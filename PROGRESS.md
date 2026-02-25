# DDE 25 NixOS Flake - Progress & Technical Documentation

**Repository:** `git@github.com:ktechmidas/nixos-unstable-dde-25-flake.git`
**Date started:** 2026-02-25
**Target:** DDE 25 (DDE 7.0), Qt6-only, X11-first, nixos-unstable
**NixOS Qt version:** Qt 6.10.x

---

## Current Status: 23 Packages Building

All 23 packages build successfully against nixos-unstable with Qt 6.10.
A NixOS module and QEMU VM configuration are in place.
The full VM system toplevel builds.

---

## Package Inventory

### Layer 1-4: DTK6 Libraries

| Package | Version | Hash | Patches | Notes |
|---------|---------|------|---------|-------|
| dtkcommon | 6.7.33 | `sha256-KTCVHI3mqYCloaXSx3JdZ8mgT6gk+9O5LEw9r81OhX4=` | None | Build macros, first in chain |
| dtk6log | 0.0.6 | `sha256-K3+wgXZ64ee5BhFrDiktQKZgDaZrmeRp1BPR+OxLNzA=` | None | Logging lib, spdlog-based |
| dtk6core | 6.0.50-unstable | `sha256-y6gIARrR+M95bz0hU6HRy45TDU2oC1GiULknzLOpZQg=` | `fix-pkgconfig-path.patch`, `fix-pri-path.patch` | Pinned to commit `52314ed` for Qt 6.10 fix |
| dtk6gui | 6.0.50 | `sha256-reB8bR3Cw/e9AZ9juzM9Sk1SE0vbx/a0jMjrd26Ei9k=` | None | Treeland disabled, extended image formats disabled |
| dtk6widget | 6.0.50 | `sha256-ycVxz/rsKFW/sina5MQ78JiReFdC7Y5h232O3YLd0X8=` | `qt-6.10.patch` | Qt 6.10 removed `QTabBarPrivate::paintWithOffsets` |
| dtk6declarative | 6.0.50 | `sha256-K/cbbEJUqug1fpNCMGxS5AzbEJVcVv/A/B/dgjaWfpg=` | None | QML toolkit, uses qt5compat + qtshadertools |

### Layer 5: Platform Integration

| Package | Version | Hash | Patches | Notes |
|---------|---------|------|---------|-------|
| qt6platform-plugins | 6.0.50 | `sha256-3Dgm/cVL22fDQAer9EqvRNJKlRwIT1Z62RPiJ7bhgPI=` | None | Custom `runCommand` to extract Qt XCB private headers from qtbase source |
| qt6integration | 6.0.50 | `sha256-h/UGDpEyRpqAbMksLVRpOLLeMDlOJNiznEFvc+NQON8=` | None | Uses `lxqt.libqtxdg` for XDG icon loading |

### Support Libraries

| Package | Version | Hash | Source | Notes |
|---------|---------|------|--------|-------|
| gsettings-qt6 | 1.1.0 | `sha256-NUrJ3xQnef7TwPa7AIZaiI7TAkMe+nhuEQ/qC1H1Ves=` | UBports GitLab | Qt6 build of gsettings-qt, same source as nixpkgs Qt5 version with `-DENABLE_QT6=ON` |
| treeland-protocols | 0.5.4 | `sha256-tp2KvfjGJ4pMtTSXTt0aQ6Wm2Yz2GYFeV6nS3vVqDmM=` | GitHub | Wayland protocol XML files |

### Data & Schemas

| Package | Version | Hash | Notes |
|---------|---------|------|-------|
| deepin-desktop-schemas | 6.0.13 | `sha256-2WGrda800xIFlOrSkbEeF4MKTDIhYMhwervB1xu2nZA=` | Go-based build tool skipped, schemas installed directly |
| deepin-desktop-base | 2025.12.22 | `sha256-uPQ2eE/Yz0k2K3YB1LxZNlQCY8pzCij+jI2pHdooUK4=` | Makefile-based, `DESTDIR=$(out) PREFIX=/` |

### Core Services

| Package | Version | Hash | Patches | Notes |
|---------|---------|------|---------|-------|
| deepin-service-manager | 1.0.21 | `sha256-D3igB2sb3Tiqa5gY0ZyOwczMMh6ZMo/gpvLycgZv1LY=` | None | D-Bus service lifecycle manager |
| dde-session | 2.0.17 | `sha256-LHAk6A+c1E2+nqQhlxoxkw882iiM0tF5iARfAeLZRD4=` | sed `/etc/` paths | Hardcoded `/etc` in CMakeLists across multiple subdirs |
| dde-polkit-agent | 6.0.18 | `sha256-G08zjak34V0Ps+c560vDfILGNMEppBXTJw13s9fgeqM=` | None | Uses `kdePackages.polkit-qt-1`, depends on dde-shell |
| dde-application-manager | 1.2.45 | `sha256-HeHVjO3+sKwnkMbA19XbIVpR6iqpOKxk2w0VbxTgmZ0=` | sed `/etc/` paths | v1.2.45 already has Qt 6.10 WaylandClientPrivate fix (do NOT apply Arch sed) |
| dde-appearance | 1.1.78 | `sha256-Ytd/OENzW+I6wx14QVrL1JMvKJxJKV4F/Bn7/yUuLCY=` | sed `/etc/`, `/usr/share`, systemd paths, tzdata | KF6WindowSystem + KF6Config + KF6GlobalAccel, gsettings-qt6 |

### Shell Framework

| Package | Version | Hash | Patches | Notes |
|---------|---------|------|---------|-------|
| dde-tray-loader | 2.0.25 | `sha256-LUHBQ93URRuVcEGybza/XMEevNytkyThdMBLmX5i6Zw=` | None | Needs KF6 (`kdePackages.kwindowsystem`), extensive X11 deps |
| dde-shell | 2.0.29 | `sha256-UgDYaBXZ0MSw0ain0U/Tf6YbxrJ+kSNIiXhf0QUbHX4=` | sed `/etc/`, systemd user unit path | The main panel/taskbar, depends on tray-loader + app-manager + treeland-protocols |

### Desktop Applications

| Package | Version | Hash | Notes |
|---------|---------|------|-------|
| dde-launchpad | 2.0.26 | `sha256-8eI2czqvSjQvuzlLIRylcNo0Iots5w2eCeXgIWltqD4=` | Application launcher, depends on dde-shell + dde-application-manager |

### Artwork

| Package | Version | Hash | Notes |
|---------|---------|------|-------|
| deepin-icon-theme | 2025.12.04 | `sha256-s3VlR6HMKC4vsh4MX0KmS8tMKMVpxK81gAGHV/QVUY8=` | Makefile-based, needs gtk3 for `gtk-update-icon-cache` |
| deepin-sound-theme | 15.10.6 | `sha256-BvG/ygZfM6sDuDSzAqwCzDXGT/bbA6Srlpg3br117OU=` | Makefile-based, `dontBuild = true` |
| deepin-wallpapers | 1.7.25 | `sha256-eMtk/uWop2i6J61FVwlXzkjxBe0LwnirxEb40AbyPfs=` | Makefile-based (NOT CMake despite initial assumption) |

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
- Registers D-Bus services for: dde-shell, dde-session, dde-application-manager, deepin-service-manager, dde-polkit-agent, dde-appearance
- Sets `QT_PLUGIN_PATH` for platform plugins and integration
- Links XDG data dirs for icons, wallpapers, sounds, schemas
- Sets `GSETTINGS_SCHEMA_DIR` for deepin-desktop-schemas
- Enables polkit, upower, accounts-daemon
- Installs Noto fonts as default
- Enables XDG portal with GTK backend

---

## VM Configuration

Located at `vm/configuration.nix`. QEMU VM with:
- 4GB RAM, 4 cores, VirtIO GPU
- Auto-login as `test` user (password: `test`)
- DDE enabled with `deepin` as default session

Run with: `nix run .#vm`

---

## Remaining Work

### Critical for Functional Desktop

| Component | Status | Blocker |
|-----------|--------|---------|
| **startdde** | Not started | Go module vendoring for nix sandbox |
| **dde-daemon** | Not started | Go module vendoring, large dependency tree |
| **dde-api** | Not started | Go module vendoring |
| **Window manager** | Not started | Need deepin-kwin or can use regular kwin-x11 |

### Important for Usability

| Component | Status | Blocker |
|-----------|--------|---------|
| **dde-session-shell** | Researched | `liblightdm-qt6-3` not in nixpkgs (lightdm Qt6 greeter library) |
| **dde-control-center** | Not started | Large package, many dependencies |
| **dde-file-manager** | Not started | Security concerns (openSUSE audit) |
| **deepin-desktop-theme** | Not started | Should be simple |
| **dde-account-faces** | Not started | Should be simple |

### dde-session-shell Research Summary
- No release tags — must pin to commit `a711d9f7c9d8fe822bf044bfe4ee5fe86a2c1cc6`
- Hash: `sha256-9Eas0WTK2OV3tCZs+rBmH1gbKbMrrSB1fuj5WgDO6P8=`
- CMake with C++17, Qt6/Dtk6 "snipe" code path
- **BLOCKER:** Needs `liblightdm-qt6-3` — LightDM's Qt6 greeter library. nixpkgs lightdm doesn't build this.
- Extensive hardcoded path patching needed (20+ `/usr` references, `#include </usr/include/shadow.h>`)
- Hardcoded `qdbusxml2cpp` path in CMakeLists.txt
- Builds dde-lock (lock screen) + lightdm-deepin-greeter (LightDM greeter)
- PAM module `pam_inhibit_autologin.so` built as subproject

### Go Services Strategy
The Go packages (dde-api, dde-daemon, startdde) are the biggest remaining challenge:
- Need `buildGoModule` with `vendorHash` computed for each
- dde-daemon is the largest (~95% Go, many deps)
- startdde is the session entry point that launches everything
- Without startdde, we rely on dde-session launching dde-shell directly
- Alternative: skip Go services initially, launch dde-shell directly from the X session

---

## Commit History

```
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
