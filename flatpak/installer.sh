#!/bin/bash
# GoldenEye: Source Linux installer
# Installs GES into Steam for native Linux or Proton play

set -uo pipefail

TITLE="GoldenEye: Source Installer"

# ---------------------------------------------------------------------------
# UI helpers — kdialog with echo fallback for headless/testing runs
# ---------------------------------------------------------------------------

HAS_KDIALOG=false
if command -v kdialog &>/dev/null; then
    HAS_KDIALOG=true
fi

ui_msg() {
    if $HAS_KDIALOG; then
        kdialog --title "$TITLE" --msgbox "$1"
    else
        echo -e "\n>>> $1\n"
        read -r -p "Press Enter to continue..."
    fi
}

ui_error() {
    if $HAS_KDIALOG; then
        kdialog --title "$TITLE" --error "$1"
    else
        echo -e "\nERROR: $1\n" >&2
    fi
}

ui_yesno() {
    if $HAS_KDIALOG; then
        kdialog --title "$TITLE" --yesno "$1"
        return $?
    else
        echo -e "\n$1"
        read -r -p "[y/N] " ans
        [[ "${ans,,}" == "y" ]]
    fi
}

ui_pick_file() {
    local start_dir="$1"
    local filter="$2"
    if $HAS_KDIALOG; then
        kdialog --title "$TITLE" --getopenfilename "$start_dir" "$filter"
    else
        read -r -p "Enter path to GES archive: " path
        echo "$path"
    fi
}

ui_pick_dir() {
    local start_dir="$1"
    if $HAS_KDIALOG; then
        kdialog --title "$TITLE" --getexistingdirectory "$start_dir"
    else
        read -r -p "Enter path to GES directory: " path
        echo "$path"
    fi
}

ui_menu() {
    # args: prompt item1 label1 item2 label2 ...
    local prompt="$1"
    shift
    if $HAS_KDIALOG; then
        kdialog --title "$TITLE" --menu "$prompt" "$@"
    else
        echo -e "\n$prompt"
        local i=1
        local -a keys=()
        while (( $# >= 2 )); do
            keys+=("$1")
            echo "  $i) $2"
            shift 2
            (( i++ ))
        done
        read -r -p "Choose [1-${#keys[@]}]: " choice
        echo "${keys[$((choice-1))]}"
    fi
}

die() {
    ui_error "$1"
    exit 1
}

# ---------------------------------------------------------------------------
# Steam detection
# ---------------------------------------------------------------------------

STEAM_CANDIDATES=(
    "$HOME/.local/share/Steam"
    "$HOME/.steam/steam"
    "$HOME/.steam/Steam"
    "$HOME/.var/app/com.valvesoftware.Steam/data/Steam"
)

find_steam() {
    for candidate in "${STEAM_CANDIDATES[@]}"; do
        local resolved
        resolved=$(realpath "$candidate" 2>/dev/null) || resolved="$candidate"
        if [[ -d "$resolved/steamapps" ]]; then
            echo "$resolved"
            return 0
        fi
    done
    return 1
}

# Parse libraryfolders.vdf and return all Steam library root paths
get_library_paths() {
    local steam_path="$1"
    echo "$steam_path"
    local vdf="$steam_path/steamapps/libraryfolders.vdf"
    [[ -f "$vdf" ]] || return 0
    grep '"path"' "$vdf" | sed 's/.*"path"[[:space:]]*"\(.*\)".*/\1/' | while read -r p; do
        [[ -d "$p/steamapps" ]] && echo "$p"
    done
}

check_source_sdk() {
    local steam_path="$1"
    while IFS= read -r lib; do
        if [[ -d "$lib/steamapps/common/Source SDK Base 2013 Multiplayer" ]]; then
            return 0
        fi
    done < <(get_library_paths "$steam_path")
    return 1
}

find_sourcemods_path() {
    local steam_path="$1"
    # Prefer the main Steam install's sourcemods dir
    echo "$steam_path/steamapps/sourcemods"
}

# ---------------------------------------------------------------------------
# Content detection
# ---------------------------------------------------------------------------

detect_binary_type() {
    local dir="$1"
    local has_so=false has_dll=false

    [[ -f "$dir/bin/client.so" || -f "$dir/bin/server.so" ]] && has_so=true
    [[ -f "$dir/bin/client.dll" || -f "$dir/bin/server.dll" ]] && has_dll=true

    if $has_so && $has_dll; then echo "both"
    elif $has_so;            then echo "linux"
    elif $has_dll;           then echo "windows"
    else                          echo "unknown"
    fi
}

# ---------------------------------------------------------------------------
# Archive extraction
# ---------------------------------------------------------------------------

extract_archive() {
    local archive="$1"
    local dest="$2"
    case "$archive" in
        *.zip)          unzip -q "$archive" -d "$dest"     ;;
        *.tar.gz|*.tgz) tar -xzf "$archive" -C "$dest"   ;;
        *.tar.bz2)      tar -xjf "$archive" -C "$dest"    ;;
        *.tar.xz)       tar -xJf "$archive" -C "$dest"    ;;
        *)              die "Unsupported archive format: $(basename "$archive")\nSupported formats: .zip  .tar.gz  .tar.bz2  .tar.xz" ;;
    esac
}

find_gesource_in_dir() {
    local dir="$1"
    # Dir might be named gesource directly
    if [[ -f "$dir/gameinfo.txt" ]]; then
        echo "$dir"
        return 0
    fi
    # Or contain a gesource subdirectory
    local sub
    sub=$(find "$dir" -maxdepth 2 -type f -name "gameinfo.txt" | head -1)
    if [[ -n "$sub" ]]; then
        echo "$(dirname "$sub")"
        return 0
    fi
    return 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

ui_msg "Welcome to the GoldenEye: Source installer for Linux!\n\nThis will install GES into your Steam library.\n\nYou will need:\n  • Your GES content archive or folder ready\n  • Steam with 'Source SDK Base 2013 Multiplayer' installed (free on Steam)"

# --- Locate Steam ---
STEAM_PATH=$(find_steam 2>/dev/null) || true
if [[ -z "$STEAM_PATH" ]]; then
    if ui_yesno "Steam was not found in the standard locations.\n\nDo you want to locate your Steam directory manually?"; then
        STEAM_PATH=$(ui_pick_dir "$HOME") || die "No directory selected."
        [[ -d "$STEAM_PATH/steamapps" ]] || die "The selected directory doesn't look like a Steam install\n(no 'steamapps' subfolder found)."
    else
        die "Cannot continue without a Steam installation."
    fi
fi

echo "Steam found at: $STEAM_PATH"

# --- Check Source SDK Base 2013 Multiplayer ---
if ! check_source_sdk "$STEAM_PATH"; then
    ui_msg "⚠  'Source SDK Base 2013 Multiplayer' was not found in your Steam library.\n\nThis free game is required by GoldenEye: Source.\n\nPlease install it from Steam (search 'Source SDK Base 2013 Multiplayer'), then re-run this installer."
    die "Required dependency not installed."
fi

echo "Source SDK Base 2013 Multiplayer: found"

# --- Select content ---
CONTENT_MODE=$(ui_menu "How do you want to provide the GES content?" \
    "archive" "Select a .zip / .tar.gz archive" \
    "folder"  "Select an existing gesource folder")

case "$CONTENT_MODE" in
    archive)
        CONTENT=$(ui_pick_file "$HOME" "*.zip *.tar.gz *.tgz *.tar.bz2 *.tar.xz|GES Archives") || true
        [[ -n "$CONTENT" && -f "$CONTENT" ]] || die "No archive selected."
        ;;
    folder)
        CONTENT=$(ui_pick_dir "$HOME") || true
        [[ -n "$CONTENT" && -d "$CONTENT" ]] || die "No folder selected."
        ;;
    *)
        die "No content source selected."
        ;;
esac

# --- Extract / locate gesource dir ---
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

if [[ -d "$CONTENT" ]]; then
    GES_DIR=$(find_gesource_in_dir "$CONTENT") || die "Could not find a valid gesource folder inside:\n$CONTENT\n\n(Expected a 'gameinfo.txt' file)"
else
    ui_msg "Extracting archive — this may take a moment..."
    extract_archive "$CONTENT" "$TMPDIR_WORK" || die "Extraction failed. Is the archive corrupted?"
    GES_DIR=$(find_gesource_in_dir "$TMPDIR_WORK") || die "Could not find a valid gesource directory in the archive.\n\n(Expected a 'gameinfo.txt' inside a 'gesource' folder)"
fi

echo "GES content found at: $GES_DIR"

# --- Detect binary type ---
BIN_TYPE=$(detect_binary_type "$GES_DIR")

case "$BIN_TYPE" in
    linux)
        NEEDS_PROTON=false
        BIN_MSG="Linux native binaries detected (.so files).\nGES will run using the Source Engine directly on Linux — no Proton needed."
        ;;
    windows)
        NEEDS_PROTON=true
        BIN_MSG="Windows-only binaries detected (.dll files).\nGES will need to run through Steam Proton. Setup instructions will follow."
        ;;
    both)
        NEEDS_PROTON=false
        BIN_MSG="Both Linux and Windows binaries detected.\nGES will run natively on Linux (preferred)."
        ;;
    unknown)
        NEEDS_PROTON=false
        BIN_MSG="⚠  No game binaries were found in the content.\n\nInstallation will proceed, but GES may not run without compiled binaries.\nYou may need to build them from source (see the repository README)."
        ;;
esac

ui_msg "Content check:\n\n$BIN_MSG"

# --- Install ---
SOURCEMODS=$(find_sourcemods_path "$STEAM_PATH")
INSTALL_DIR="$SOURCEMODS/gesource"

if [[ -d "$INSTALL_DIR" ]]; then
    ui_yesno "GoldenEye: Source is already installed at:\n$INSTALL_DIR\n\nOverwrite it?" || die "Installation cancelled."
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$SOURCEMODS"
echo "Installing to: $INSTALL_DIR"
cp -r "$GES_DIR" "$INSTALL_DIR"

[[ -f "$INSTALL_DIR/gameinfo.txt" ]] || ui_msg "⚠  gameinfo.txt was not found after installation.\nThe installation may be incomplete."

# --- Done ---
if $NEEDS_PROTON; then
    ui_msg "GoldenEye: Source installed!\n\nBecause only Windows binaries were found, you must configure Proton:\n\n1. Restart Steam completely\n2. Right-click 'Source SDK Base 2013 Multiplayer' → Properties\n3. Open the Compatibility tab\n4. Check 'Force the use of a specific Steam Play compatibility tool'\n5. Select Proton 9.0 (or the latest available)\n6. Close Properties\n7. GoldenEye: Source will appear in your Steam library — launch it from there"
else
    ui_msg "GoldenEye: Source installed!\n\nNext steps:\n1. Restart Steam completely\n2. GoldenEye: Source will appear in your Steam library\n3. Launch it from the library\n\nIf the game fails to start, try enabling Proton compatibility\non 'Source SDK Base 2013 Multiplayer' (Properties → Compatibility)."
fi

echo "Installation complete: $INSTALL_DIR"
