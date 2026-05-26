# GoldenEye: Source — Linux Install Instructions

## What you need before starting
1. **Steam** installed (native or Flatpak)
2. **Source SDK Base 2013 Multiplayer** — free on Steam, search for it and install it
3. **GES content** — download the GoldenEye: Source v5.0 content pack from [ModDB](https://www.moddb.com/mods/goldeneye-source) or the GES website as a zip

---

## Build & install the Flatpak (one-time)

```bash
# Clone the repo if you haven't
git clone https://github.com/echocabinet/ges-code.git
cd ges-code

# Install flatpak-builder if needed
sudo apt install flatpak-builder   # or equivalent for your distro

# Add the KDE runtime (required)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.kde.Platform//6.7 org.kde.Sdk//6.7

# Build and install locally
flatpak-builder --force-clean --install --user build-dir flatpak/com.geshl2.GESource.yaml
```

---

## Run the installer

```bash
flatpak run com.geshl2.GESource
```

Or launch **GoldenEye: Source Installer** from your app menu.

---

## What the installer does (step by step)

1. **Finds Steam** automatically — checks all standard locations including Flatpak Steam
2. **Verifies** Source SDK Base 2013 Multiplayer is installed
3. **Asks** whether you're providing a zip archive or an existing folder
4. **Extracts** the archive and locates the `gesource/` directory inside it
5. **Checks binaries** — if `.so` files are present it sets up for native Linux; if only `.dll` files it gives you Proton setup steps
6. **Copies** everything to `~/.local/share/Steam/steamapps/sourcemods/gesource/`
7. **Tells you** to restart Steam — GES then appears in your library like any other game

---

## After installation

- Restart Steam
- GoldenEye: Source appears in your library
- If it doesn't launch (likely, since v5.0 only shipped Windows binaries): right-click **Source SDK Base 2013 Multiplayer** → Properties → Compatibility → force Proton 9.0, then try launching GES again
