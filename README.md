# com.automattic.beeper — Beeper Flatpak

Unofficial Flatpak wrapper for [Beeper](https://www.beeper.com), a universal
messaging app that unifies WhatsApp, Telegram, Signal, Instagram, Facebook
Messenger, Twitter/X DMs, LinkedIn, Slack, Discord, and more.

> **Disclaimer**: This package is not verified by, affiliated with, or
> supported by Automattic, Inc.

## Structure

| File | Purpose |
|------|---------|
| `com.automattic.beeper.yml` | Main Flatpak manifest |
| `apply_extra` | AppImage extraction script (runs at install time) |
| `com.automattic.beeper.sh` | Launcher wrapper (`zypak-wrapper` + Wayland env) |
| `com.automattic.beeper.desktop` | Desktop entry |
| `com.automattic.beeper.png` | 512×512 app icon (extracted from AppImage) |
| `com.automattic.beeper.metainfo.xml` | AppStream metainfo (Flathub) |
| `update.sh` | Helper to update sha256/size for a new Beeper release |

## How It Works

The AppImage is downloaded at **install time** via Flatpak's `extra-data`
mechanism (not bundled in the repo). `apply_extra` locates the embedded
squashfs by scanning for its magic bytes (`hsqs`) and extracts it with
`unsquashfs`. The launcher sets `ELECTRON_OZONE_PLATFORM_HINT=auto` so
Electron runs natively on Wayland when available.

## Building

### Prerequisites

```bash
# Install flatpak-builder
sudo apt install flatpak-builder   # Debian/Ubuntu
sudo pacman -S flatpak-builder     # Arch

# Add Flathub and install the runtime + BaseApp
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub \
  org.freedesktop.Platform//25.08 \
  org.freedesktop.Sdk//25.08 \
  org.electronjs.Electron2.BaseApp//25.08

# Pull submodules (squashfs-tools)
git submodule update --init --recursive
```

### Build & Install

```bash
# Build and install locally (downloads ~230 MB AppImage on first run)
flatpak-builder --force-clean --install --user build-dir com.automattic.beeper.yml

# Run
flatpak run com.automattic.beeper
```

> **Note**: `flatpak-builder --run` does **not** work for this package because
> `extra-data` sources (the AppImage) are only downloaded during `flatpak install`.
> Always use `--install --user` and then `flatpak run`.

## Updating to a New Beeper Release

```bash
# Fetches the latest release, recomputes sha256/size, and patches the manifest.
./update.sh
git add com.automattic.beeper.yml com.automattic.beeper.metainfo.xml
git commit -m "Update to Beeper X.Y.Z"
```

## Permissions

| Permission | Reason |
|------------|--------|
| `--share=network` | Required for messaging |
| `--share=ipc` | Electron multi-process IPC |
| `--socket=wayland` + `--socket=fallback-x11` | Display (prefers native Wayland) |
| `--socket=pulseaudio` | Audio notifications / calls |
| `--device=dri` | GPU acceleration |
| `--filesystem=xdg-download` | File sharing / downloads |
| `--filesystem=xdg-config/gtk-3.0`, `~/.themes` | GTK theme passthrough |
| `--filesystem=xdg-run/dconf`, `--talk-name=ca.desrt.dconf` | GSettings / theme name lookup |
| `--talk-name=org.freedesktop.secrets` etc. | Keychain / credential storage |
| `--talk-name=org.kde.StatusNotifierWatcher` | System tray icon |
