# GoldenEye: Source — Linux Install Instructions

There are two ways to install GES on Linux. **Lutris** is the easiest and most reliable.
The **Flatpak/Steam** method is better if you want GES to live inside your Steam library.

---

## Method 1: Lutris (recommended)

Lutris handles everything — Wine prefix setup, download, and launch configuration — in a few clicks.

1. Install Lutris from your distro's package manager or [lutris.net](https://lutris.net)
2. Install Wine and its 32-bit dependencies:
   ```bash
   # Debian/Ubuntu
   sudo apt install wine wine32 winetricks
   # Arch
   sudo pacman -S wine wine-mono winetricks
   ```
3. Open Lutris and search for **GoldenEye: Source**
4. Click **Install** — Lutris downloads the Windows installer and sets up a 32-bit Wine prefix automatically
5. Launch from Lutris

**Why this works well:** GES v5.0 only shipped Windows binaries, and Lutris runs it as a standalone Wine application — no Steam sourcemods configuration needed.

---

## Method 2: Flatpak installer + Steam sourcemods

Use this if you want GES to appear in your Steam library and launch from there.

### What you need before starting
1. **Steam** installed (native or Flatpak)
2. **Source SDK Base 2013 Multiplayer** — free on Steam, search for it and install it
3. **GES content** — download the GoldenEye: Source v5.0 content pack from [ModDB](https://www.moddb.com/mods/goldeneye-source) or the GES website as a zip

### Build & install the Flatpak (one-time)

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

### Run the installer

```bash
flatpak run com.geshl2.GESource
```

Or launch **GoldenEye: Source Installer** from your app menu.

The installer will:
1. Find your Steam installation automatically (including Flatpak Steam)
2. Verify Source SDK Base 2013 Multiplayer is installed
3. Ask you to point it at your GES zip archive or folder
4. Detect whether Linux or Windows-only binaries are present
5. Copy files to `steamapps/sourcemods/gesource/`
6. Walk you through any remaining Steam/Proton configuration

### Enabling Proton (required for v5.0 Windows binaries)

Since the v5.0 release only includes Windows `.dll` files, you need Proton:

1. Restart Steam after installation
2. Right-click **Source SDK Base 2013 Multiplayer** → Properties → Compatibility
3. Check **Force the use of a specific Steam Play compatibility tool**
4. Select **Proton-GE** (recommended) or Proton 9.0
5. GoldenEye: Source will now appear in your library — launch it from there

> **Proton-GE tip:** [GE-Proton](https://github.com/GloriousEggrollGuy/proton-ge-custom) (installed via ProtonUp-Qt) handles older Source mods more reliably than stock Proton. Worth installing if you hit audio or rendering issues.

---

## Recommended Steam launch options

Right-click GoldenEye: Source → Properties → Launch Options:

```
-novid -console
```

| Option | Effect |
|---|---|
| `-novid` | Skips the intro video on launch |
| `-console` | Enables the developer console (`` ` `` key in-game) for troubleshooting |
| `-w 1920 -h 1080` | Forces a specific resolution if the game starts at the wrong size |
| `-windowed` | Starts in windowed mode |

---

## Common fixes

### Game doesn't appear in Steam library after installation
- Make sure Steam was fully restarted (quit from the system tray, not just the window)
- Verify `steamapps/sourcemods/gesource/gameinfo.txt` exists
- Check that Source SDK Base 2013 Multiplayer is installed and not set to a beta branch

### No audio / audio crashes on launch
This is the most common Linux issue with GES. GES uses FMOD for music, which behaves poorly under native Linux. Running via Proton or Lutris/Wine resolves it in most cases.

### Mouse feels wrong / acceleration issues
Open the in-game console and run:
```
m_rawinput 1
```
This enables raw mouse input and bypasses OS acceleration. Add it to `gesource/cfg/autoexec.cfg` to make it permanent.

### Low framerates
Source SDK Base 2013 Multiplayer can be CPU-bound on Linux. Try:
```
-threads 4
```
as a launch option (replace `4` with your core count).

### 32-bit library errors (native Linux path only)
If attempting the native Linux path with `.so` binaries:
```bash
# Debian/Ubuntu
sudo apt install lib32gcc-s1 libsdl2-2.0-0:i386 libopenal1:i386
```

---

## Config file locations

| File | Purpose |
|---|---|
| `steamapps/sourcemods/gesource/cfg/autoexec.cfg` | Runs on every launch — good place for permanent settings |
| `steamapps/sourcemods/gesource/cfg/config.cfg` | Auto-generated user config (binds, graphics) |
| `steamapps/sourcemods/gesource/cfg/video.txt` | Resolution and graphics settings |

---

## References

- [PCGamingWiki — GoldenEye: Source](https://www.pcgamingwiki.com/wiki/GoldenEye:_Source)
- [Gamers on Linux — GoldenEye: Source Guide](https://www.gamersonlinux.com/forum/threads/goldeneye-source-guide.2149/)
- [Lutris — GoldenEye: Source](https://lutris.net/games/goldeneye-source/)
- [ModDB — GoldenEye: Source](https://www.moddb.com/mods/goldeneye-source)
- [GE-Proton (ProtonUp-Qt)](https://github.com/GloriousEggrollGuy/proton-ge-custom)
