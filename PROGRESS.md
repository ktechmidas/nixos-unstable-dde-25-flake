# DDE 25 NixOS Flake - Progress & Technical Documentation

**Repository:** `git@github.com:ktechmidas/nixos-unstable-dde-25-flake.git`
**Date started:** 2026-02-25
**Target:** DDE 25 (DDE 7.0), Qt6-only, X11-first, nixos-unstable
**NixOS Qt version:** Qt 6.10.x

---

## Current Status: 40 Packages Building, Desktop Running on Real Hardware

40 packages (36 original + docparser, deepin-pdfium, util-dfm, dde-file-manager)
build successfully against nixos-unstable with Qt 6.10. DDE runs on real hardware
(ASUS laptop, AMD Cezanne iGPU + NVIDIA RTX 3080 Mobile) via LightDM.

**What works on real hardware:**
- Full session startup chain: LightDM → dde-session → deepin-kwin → dde-shell
- Dock/panel (dde-shell) with program icons, launcher (dde-launchpad)
- Desktop wallpaper (via dde-file-manager's desktop plugin)
- Icons loading (Papirus fallback, Appearance D-Bus service, XSettings)
- All Go services (dde-api, dde-daemon, startdde)
- Bloom cursor theme, compositing via deepin-kwin on AMD iGPU
- 15 tray plugins loading via trayplugin-loader

**Known issues (real hardware):**
- **Tray icons render as black boxes** — see "Tray Black Box Investigation" below
- **Tray QML takes ~3 minutes to load** — `org.deepin.ds.dock.tray` async QML compilation is extremely slow; after loading, tray _may_ work but timing makes it hard to confirm
- **Software rendering required** — `QT_QUICK_BACKEND=software` needed; GPU rendering causes all QML async loading to hang indefinitely
- dde-control-center shows white box (plugin naming mismatch: expects `system.so`, has `libsystem_qml.so`)
- dxcb "Failed to enable NoTitlebar" spam (cosmetic, non-critical)
- `lightdm-deepin-greeter` not built — needs `liblightdm-qt6-3` which doesn't exist in nixpkgs
- No deepin-terminal or deepin-editor — both are still Qt5/DTK5

---

## Package Inventory

### Layer 1-4: DTK6 Libraries (6 packages)

| Package | Version | Hash | Patches | Notes |
|---------|---------|------|---------|-------|
| dtkcommon | 6.7.33 | `sha256-KTCVHI3mqYCloaXSx3JdZ8mgT6gk+9O5LEw9r81OhX4=` | None | Build macros, first in chain |
| dtk6log | 0.0.6 | `sha256-K3+wgXZ64ee5BhFrDiktQKZgDaZrmeRp1BPR+OxLNzA=` | None | Logging lib, spdlog-based |
| dtk6core | 6.0.50-unstable | `sha256-y6gIARrR+M95bz0hU6HRy45TDU2oC1GiULknzLOpZQg=` | `fix-pkgconfig-path.patch`, `fix-pri-path.patch` | Pinned to commit `52314ed` for Qt 6.10 fix |
| dtk6gui | 6.0.50 | `sha256-reB8bR3Cw/e9AZ9juzM9Sk1SE0vbx/a0jMjrd26Ei9k=` | None | Treeland disabled, extended image formats disabled |
| dtk6widget | 6.0.50 | `sha256-ycVxz/rsKFW/sina5MQ78JiReFdC7Y5h232O3YLd0X8=` | `qt-6.10.patch` | Qt 6.10 removed `QTabBarPrivate::paintWithOffsets` |
| dtk6declarative | 6.0.50 | `sha256-K/cbbEJUqug1fpNCMGxS5AzbEJVcVv/A/B/dgjaWfpg=` | None | QML toolkit, uses qt5compat + qtshadertools |

### Layer 5: Platform Integration (2 packages)

| Package | Version | Hash | Patches | Notes |
|---------|---------|------|---------|-------|
| qt6platform-plugins | 6.0.50 | `sha256-3Dgm/cVL22fDQAer9EqvRNJKlRwIT1Z62RPiJ7bhgPI=` | None | Custom `runCommand` to extract Qt XCB private headers from qtbase source |
| qt6integration | 6.0.50 | `sha256-h/UGDpEyRpqAbMksLVRpOLLeMDlOJNiznEFvc+NQON8=` | None | Uses `lxqt.libqtxdg` for XDG icon loading |

### Support Libraries (4 packages)

| Package | Version | Hash | Source | Notes |
|---------|---------|------|--------|-------|
| gsettings-qt6 | 1.1.0 | `sha256-NUrJ3xQnef7TwPa7AIZaiI7TAkMe+nhuEQ/qC1H1Ves=` | UBports GitLab | Qt6 build of gsettings-qt, same source as nixpkgs Qt5 version with `-DENABLE_QT6=ON` |
| deepin-pw-check | 6.0.21 | — | GitHub | Password strength checking library, needed by dde-control-center |
| deepin-wayland-protocols | 1.10.14 | — | GitHub | Wayland protocol XML files |
| treeland-protocols | 0.5.4 | `sha256-tp2KvfjGJ4pMtTSXTt0aQ6Wm2Yz2GYFeV6nS3vVqDmM=` | GitHub | Wayland protocol XML files |

### Data & Schemas (2 packages)

| Package | Version | Hash | Notes |
|---------|---------|------|-------|
| deepin-desktop-schemas | 6.0.13 | `sha256-2WGrda800xIFlOrSkbEeF4MKTDIhYMhwervB1xu2nZA=` | Go-based build tool skipped, schemas installed directly |
| deepin-desktop-base | 2025.12.22 | `sha256-uPQ2eE/Yz0k2K3YB1LxZNlQCY8pzCij+jI2pHdooUK4=` | Makefile-based, `DESTDIR=$(out) PREFIX=/` |

### Build Tools (1 package)

| Package | Version | Notes |
|---------|---------|-------|
| deepin-gettext-tools | 1.0.11 | Perl/Python build tool for polkit policy translation. Required by all Go packages at build time. |

### Go Services — Layer 8 (3 packages)

| Package | Version | Notes |
|---------|---------|-------|
| dde-api | 6.0.35 | D-Bus API library, 10 binaries. `buildGoModule`. |
| dde-daemon | 6.1.75 | Central system/session daemon, 15 binaries. `buildGoModule`. Patched to disable UOS-specific `deepin-system-power-control`. |
| startdde | 6.1.6 | Session starter. `buildGoModule`. |

### Window Manager — Layer 6 (1 package)

| Package | Version | Notes |
|---------|---------|-------|
| deepin-kwin | 5.14.5.1 | KWin fork for DDE. Depends on KDE Frameworks 6. Uses `kdePackages.kwin` as base. |

### Core Services — Layer 9 (6 packages)

| Package | Version | Hash | Patches | Notes |
|---------|---------|------|---------|-------|
| deepin-service-manager | 1.0.21 | `sha256-D3igB2sb3Tiqa5gY0ZyOwczMMh6ZMo/gpvLycgZv1LY=` | None | D-Bus service lifecycle manager |
| dde-app-services | 1.0.28 | — | None | Provides `dde-dconfig-daemon` |
| dde-session | 2.0.17 | `sha256-LHAk6A+c1E2+nqQhlxoxkw882iiM0tF5iARfAeLZRD4=` | sed `/etc/` paths | Session entry point, systemd user target chain |
| dde-polkit-agent | 6.0.18 | `sha256-G08zjak34V0Ps+c560vDfILGNMEppBXTJw13s9fgeqM=` | None | Uses `kdePackages.polkit-qt-1`, depends on dde-shell |
| dde-application-manager | 1.2.45 | `sha256-HeHVjO3+sKwnkMbA19XbIVpR6iqpOKxk2w0VbxTgmZ0=` | sed `/etc/` paths | v1.2.45 already has Qt 6.10 WaylandClientPrivate fix |
| dde-appearance | 1.1.78 | `sha256-Ytd/OENzW+I6wx14QVrL1JMvKJxJKV4F/Bn7/yUuLCY=` | sed `/etc/`, `/usr/share`, systemd paths, tzdata | KF6WindowSystem + KF6Config + KF6GlobalAccel, gsettings-qt6 |

### Shell Framework — Layer 10 (2 packages)

| Package | Version | Hash | Patches | Notes |
|---------|---------|------|---------|-------|
| dde-tray-loader | 2.0.25 | `sha256-LUHBQ93URRuVcEGybza/XMEevNytkyThdMBLmX5i6Zw=` | None | Needs KF6 (`kdePackages.kwindowsystem`), extensive X11 deps |
| dde-shell | 2.0.29 | `sha256-UgDYaBXZ0MSw0ain0U/Tf6YbxrJ+kSNIiXhf0QUbHX4=` | sed `/etc/`, systemd user unit path | The main panel/taskbar, depends on tray-loader + app-manager + treeland-protocols |

### Desktop Applications — Layer 11 (3 packages)

| Package | Version | Hash | Notes |
|---------|---------|------|-------|
| dde-launchpad | 2.0.26 | `sha256-8eI2czqvSjQvuzlLIRylcNo0Iots5w2eCeXgIWltqD4=` | Application launcher, depends on dde-shell + dde-application-manager |
| dde-control-center | — | — | System settings, depends on dde-shell, deepin-pw-check |
| dde-session-shell | unstable | — | Only dde-lock built (greeter needs liblightdm-qt6-3). Pinned to commit. CMake patched to remove LightDM link from dde-lock. |

### Session — Layer 12 (1 package)

| Package | Version | Hash | Notes |
|---------|---------|------|-------|
| dde-session-ui | 1.0.12 | — | Shutdown dialog, OSD, welcome screen. Provides D-Bus services for lock/shutdown fronts. |

### Artwork (5 packages)

| Package | Version | Hash | Notes |
|---------|---------|------|-------|
| deepin-icon-theme | 2025.12.04 | `sha256-s3VlR6HMKC4vsh4MX0KmS8tMKMVpxK81gAGHV/QVUY8=` | Includes bloom cursor theme |
| deepin-desktop-theme | — | — | Desktop themes |
| deepin-sound-theme | 15.10.6 | `sha256-BvG/ygZfM6sDuDSzAqwCzDXGT/bbA6Srlpg3br117OU=` | Makefile-based, `dontBuild = true` |
| deepin-wallpapers | 1.7.25 | `sha256-eMtk/uWop2i6J61FVwlXzkjxBe0LwnirxEb40AbyPfs=` | Makefile-based (NOT CMake despite initial assumption) |
| dde-account-faces | — | — | User avatar images |

---

## Problems Encountered & Solutions

### 1. dtk6core Qt 6.10 Build Failure
**Problem:** Qt 6.10 removed `QDirIterator::ConstIterator`, breaking dtk6core 6.0.50 tag.
**Solution:** Pinned to commit `52314ed4a90e33450cc319f5ec05463626e33e5b` which includes upstream PR #527 fix. DTK_VERSION cmake flag hardcoded to `6.0.50`.

### 2. CMake Targets Path Mismatch with `dev` Output
**Problem:** Nix's fixup phase moves cmake config files to `dev` output, but the cmake target files still reference libraries at `dev/lib/` while the actual `.so` files are in `out/lib/`. Downstream packages fail with "imported target not found".
**Solution:** Dropped `dev` output from all DTK packages that had this issue. Only `out` and `doc` outputs used.

### 3. Deprecated `xorg.*` Package Names
**Problem:** `xorg.libX11`, `xorg.libXext`, etc. are deprecated in nixos-unstable. Build warnings everywhere.
**Solution:** Use top-level names: `libx11`, `libxext`, `libxi`, `libxcb`, `xcbutil`, etc.

### 4. dtk6widget Qt 6.10 Failure (`paintWithOffsets`)
**Problem:** Qt 6.10 removed `QTabBarPrivate::paintWithOffsets` member, breaking dtk6widget's `dtabbar.cpp`.
**Solution:** Cherry-picked patch from Arch Linux packaging. 4 references to `d->paintWithOffsets` removed from conditional checks in `qt-6.10.patch`.

### 5. qt6platform-plugins "Not support Qt Version: 6.10.2"
**Problem:** The bundled version check only goes up to Qt 6.8.0, and it needs internal Qt XCB QPA private headers (`qxcbintegration_p.h`, etc.) that nixpkgs doesn't install.
**Solution:** Created a `runCommand` derivation that extracts the private headers from qtbase's source tarball:
```nix
qtXcbPrivateHeaders = runCommand "qt-xcb-private-headers-${qt6Packages.qtbase.version}" {
  src = qt6Packages.qtbase.src;
} ''
  mkdir -p work
  tar -xf $src -C work
  srcdir=$(echo work/*/src/plugins/platforms/xcb)
  mkdir -p $out
  cp "$srcdir"/*.h $out/ 2>/dev/null || true
  for subdir in gl_integrations gl_integrations/xcb_egl gl_integrations/xcb_glx nativepainting; do
    if [ -d "$srcdir/$subdir" ]; then
      mkdir -p "$out/$subdir"
      cp "$srcdir/$subdir"/*.h "$out/$subdir/" 2>/dev/null || true
    fi
  done
'';
```
Passed to cmake via `-DQT_XCB_PRIVATE_HEADERS=${qtXcbPrivateHeaders}`.

### 6. deepin-desktop-schemas Go Build Failure
**Problem:** `go build` needs network access for module fetching, which is unavailable in the nix sandbox.
**Solution:** Skipped Go-based `override_tool` build entirely. Installed schema XML files directly with `install -m644 schemas/*.xml` and ran `glib-compile-schemas` manually.

### 7. Hardcoded `/etc` Paths Across Multiple Packages
**Problem:** dde-session, dde-shell, dde-application-manager, dde-appearance all have `install(... /etc/...)` in CMakeLists.txt files, which would write to the nix store's `/etc` (wrong).
**Solution:** Broad `find . -name "CMakeLists.txt" -exec sed -i "s|/etc/|$out/etc/|g" {} +` in `postPatch` for each affected package. Also set `CMAKE_INSTALL_SYSCONFDIR` cmake flag.

### 8. Systemd User Unit Install Paths
**Problem:** dde-shell and dde-appearance try to install systemd user units to systemd's store path via `${SYSTEMD_USER_UNIT_DIR}`.
**Solution:** Two-pronged fix:
1. `sed` replacement in CMakeLists.txt: `s|\${SYSTEMD_USER_UNIT_DIR}|$out/lib/systemd/user|g`
2. Set `SYSTEMD_USER_UNIT_DIR = "${placeholder "out"}/lib/systemd/user"` as environment variable

### 9. dde-application-manager WaylandClientPrivate Double-Fix
**Problem:** Arch Linux applies a sed patch `s/WaylandClient/WaylandClient WaylandClientPrivate/` for Qt 6.10 compat. But v1.2.45 already has this fix upstream, so applying it would produce `WaylandClientPrivatePrivate`.
**Solution:** Do NOT apply the Arch sed patch for this version. The fix is already upstream.

### 10. deepin-wallpapers Build System Mismatch
**Problem:** Initially used CMake as build system, but the source only has a Makefile, no CMakeLists.txt.
**Solution:** Removed `cmake` from nativeBuildInputs, added `makeFlags = [ "PREFIX=$(out)" ]`.

### 11. fontconfig pkg-config Chain Issue
**Problem:** qt6platform-plugins couldn't find fontconfig through pkg-config.
**Solution:** Added `expat` to buildInputs to complete the fontconfig pkg-config dependency chain.

### 12. gsettings-qt6 Not in nixpkgs
**Problem:** dde-appearance needs `gsettings-qt6` (pkg-config module), but nixpkgs only ships Qt5 version.
**Solution:** Created our own `gsettings-qt6` package using the same UBports source (v1.1.0) with `-DENABLE_QT6=ON`. Same patches as the nixpkgs Qt5 version (WERROR fix, pkg-config path fix, QML prefix fix). Uses `lomiri.cmake-extras` from nixpkgs.

### 13. Nix Flake Not Seeing New Files
**Problem:** New package directories created but `nix build` couldn't find them.
**Solution:** Must `git add` untracked directories/files for nix flake to include them in the evaluation tree.

### 14. dde-daemon `deepin-system-power-control` Service Failure
**Problem:** dde-daemon creates a transient systemd service for `/usr/sbin/deepin-system-power-control` which is a UOS-specific binary not available in upstream packages.
**Solution:** Patched the Go source in `system/power1/manager_powersave.go` to replace the path with `/run/current-system/sw/bin/true`.

### 15. VM Black Screen — No Hardware GL Acceleration
**Problem:** QEMU with `-vga virtio` only provides a dumb framebuffer with DRISWRAST (software rasterization). deepin-kwin requires real GL for compositing.
**Solution:** Changed VM to `-device virtio-vga-gl` with `-display gtk,gl=on` for virgl 3D acceleration.

### 16. VM Black Screen — Compositing OFF Despite GL Working
**Problem:** deepin-kwin requires DConfig schemas for `org.kde.kwin.compositing` which don't exist in any upstream package. Without them, kwin defaults to compositing OFF. Analyzed `composite.cpp` line 1263-1268: reads `[Compositing] Enabled` from kwinrc, then falls back to DConfig `getDConfigUserEffectType()` which returns `AutoSelect` (OFF) when DConfig is unavailable.
**Solution:** Added `environment.etc."xdg/kwinrc"` to the NixOS module with `[Compositing] Enabled=true Backend=OpenGL`, bypassing DConfig entirely.

### 17. Qt5Compat.GraphicalEffects QML Import Missing
**Problem:** dde-shell and other QML components need `Qt5Compat.GraphicalEffects` module for blur/shadow effects.
**Solution:** Added `qt6Packages.qt5compat` to `QML2_IMPORT_PATH` in session variables.

### 18. WebP Image Format Support
**Problem:** Some deepin icons/images use WebP format, causing missing image warnings.
**Solution:** Ensured webp support libraries are available in the Qt image format plugins path.

---

## Architecture Decisions

### Package Scope: `lib.makeScope pkgs.newScope`
We use `lib.makeScope` with explicit `qt6Packages.*` references (not `qt6Packages.newScope`). This gives us full control over Qt6 dependencies while allowing DDE packages to see each other via the scope's `callPackage`.

### No `dev` Output for DTK Libraries
The standard nix multi-output system breaks cmake target discovery for DTK packages. The `out` output contains both libraries and cmake configs. Only `doc` is split out where applicable.

### X11-First, No Treeland
- `dtk6gui`: `-DDTK_DISABLE_TREELAND=ON`
- `dde-shell`: `-DBUILD_WITH_X11=ON`
- Treeland compositor packages are not built
- `treeland-protocols` IS built (needed by dde-shell and dde-application-manager for protocol definitions)

### Explicit Qt6 Package References
All Qt6 dependencies use `qt6Packages.qtbase`, `qt6Packages.qttools`, etc. — never `qt6Packages.newScope`. This avoids the scope isolation issues that plagued the previous Qt5-era packaging.

### KDE Frameworks 6 via `kdePackages`
Where KDE Frameworks are needed (kwindowsystem, polkit-qt-1, kconfig, kglobalaccel), they come from `kdePackages.*` which is the Qt6 KDE scope in nixpkgs.

---

## NixOS Module

Located at `modules/deepin.nix`. Provides `services.desktopManager.deepin.enable`.

When enabled:
- Registers a `deepin` X11 session using `dde-session` as the session command
- Registers D-Bus services for: dconf, dde-shell, dde-session, dde-session-ui, dde-session-shell, dde-application-manager, deepin-service-manager, dde-app-services, dde-polkit-agent, dde-appearance, dde-daemon, dde-api, dde-control-center
- Creates `deepin-daemon` system user/group for dde-dconfig-daemon
- Runs 3 system-level systemd services: dde-dconfig-daemon, deepin-service-manager, dde-system-daemon
- Provides systemd user packages for: kglobalacceld, dconf, dde-session, dde-shell, dde-session-ui, dde-appearance
- Sets `QT_PLUGIN_PATH` and `QT_QPA_PLATFORM_PLUGIN_PATH` for platform plugins
- Sets `QML2_IMPORT_PATH` for DTK6, dde-shell, dde-launchpad, Qt5Compat
- Sets `XCURSOR_THEME=bloom` and `XCURSOR_SIZE=24` for deepin cursor theme
- Sets `DDE_KWIN_DIR` for deepin-kwin discovery
- Provides default `kwinrc` enabling compositing (workaround for missing DConfig schemas)
- Combines GSettings schemas from deepin-desktop-schemas, startdde, and dde-daemon
- Links XDG data dirs for icons, wallpapers, sounds, schemas, dde-shell plugins, D-Bus services, polkit, applications, xsessions, deepin-daemon libs, deepin-api libs
- Enables PAM for dde-lock (lock screen authentication)
- Enables polkit, upower, accounts-daemon, udisks2, power-profiles-daemon, NetworkManager
- Installs Noto fonts as default
- Enables XDG portal with GTK backend
- Installs all 36 DDE packages as system packages

---

## VM Configuration

Located at `vm/configuration.nix`. QEMU VM with:
- 4GB RAM, 4 cores, 8GB disk, 1920x1080 resolution
- VirtIO-VGA-GL with virgl 3D acceleration (`-device virtio-vga-gl -display gtk,gl=on`)
- Auto-login as `test` user (password: `test`) via LightDM
- DDE enabled with `deepin` as default session
- SSH access on port 2222 for debugging (`ssh -p 2222 test@localhost`)
- Serial console enabled for boot debugging
- Includes xterm, nano, feh, mesa-demos for testing

Run with: `nix run .#vm`

## Real Hardware Integration

DDE has been added to the user's NixOS system configuration at `~/code/nixos/`:

- `flake.nix`: Added `dde` flake input pointing to local path `/home/monotoko/code/dde-nixos-revival`
- `configuration.nix`: Added `services.desktopManager.deepin.enable = true`
- DDE appears alongside GNOME in the GDM session selector
- Apply with: `nh os switch ~/code/nixos/`

---

## Remaining Work

### Desktop Background / Wallpaper

The desktop is black because the `org.deepin.ds.desktop` wallpaper plugin ships with `dde-file-manager`, which has heavy dependencies (libdfm6-*, libdeepin-pdfium) and security concerns from the openSUSE audit. Options:
1. Package dde-file-manager (heavy lift, security concerns)
2. Create a minimal wallpaper-only plugin/workaround
3. Use `feh --bg-scale` as a user-level workaround

### LightDM Deepin Greeter

`lightdm-deepin-greeter` requires `liblightdm-qt6-3` which doesn't exist — Canonical's LightDM only supports Qt5. dde-lock (lock screen) works fine without it. This is not a priority since GDM works as the display manager.

### Not Yet Packaged

| Component | Priority | Notes |
|-----------|----------|-------|
| **dde-file-manager** | Medium | Provides desktop wallpaper plugin + file manager. Heavy deps, security concerns. |
| **dde-network-core** | Low | Network management integration. NetworkManager works without it. |
| **dde-clipboard** | Low | Clipboard manager |
| **dde-grand-search** | Low | Desktop search |
| **deepin-terminal** | Blocked | Still Qt5/DTK5, cannot build in Qt6-only stack |
| **deepin-editor** | Blocked | Still Qt5/DTK5, cannot build in Qt6-only stack |

### Polish / Quality

| Task | Notes |
|------|-------|
| **Test on real hardware** | DDE added to NixOS config, needs `nh os switch` and GDM testing |
| **Binary cache / CI** | No CI yet. Builds are heavy (67 derivations). Consider Garnix or GitHub Actions. |
| **Upstream contribution** | Could submit to nixpkgs once stable and well-tested |
| **Security audit** | Review openSUSE findings against DDE 25 codebase |

---

## Commit History

```
de06f78 Enable kwin compositing by default, improve VM 3D support
d518d31 Fix power control service failure, add cursor theme and xterm
df9c008 Add dde-session-shell (dde-lock), fix Qt5Compat and webp support
2370fc8 Get DDE 25 desktop session fully running in VM
b978c79 Fix build issues and get VM building successfully
a49e7ad Add dde-control-center, dde-session-ui, artwork, and deepin-pw-check (5 new packages)
f110ccd Add Go services, deepin-kwin, and supporting packages (6 new packages)
71267b5 Add comprehensive PROGRESS.md documenting all work done
6f65faf Implement NixOS module and VM configuration for DDE 25
aa6f568 Add dde-appearance and gsettings-qt6 (2 new packages)
e3795f8 Add artwork, dde-launchpad, and re-enable dde-polkit-agent (5 new packages)
3907268 Add shell framework and dependencies (5 new packages)
61b6dae Add core services and data packages (5 new packages)
9488e4c Add qt6platform-plugins and qt6integration (platform layer)
bf0af34 Add dtk6gui, dtk6widget, dtk6declarative; fix dtk6core for Qt 6.10
82cc64c Initial scaffold for DDE 25 (DDE 7.0) NixOS flake
```

---

## Key Reference Files

| File | Purpose |
|------|---------|
| `flake.nix` | Main flake: packages, NixOS module, VM config |
| `packages/default.nix` | Package scope with `lib.makeScope` |
| `modules/deepin.nix` | NixOS module wiring |
| `vm/configuration.nix` | QEMU VM test configuration |
| `RESEARCH.md` | Background research (history, architecture, security) |
| `PROGRESS.md` | This file — implementation progress and technical notes |

---

## Key URLs

- **Our repo:** https://github.com/ktechmidas/nixos-unstable-dde-25-flake
- **Arch PKGBUILDs:** https://gitlab.archlinux.org/archlinux/packaging/packages (search "deepin")
- **Upstream:** https://github.com/linuxdeepin
- **Original NixOS flake (archived):** https://github.com/martyr-deepin/dde-nixos
- **openSUSE security audit:** https://security.opensuse.org/2025/05/07/deepin-desktop-removal.html
