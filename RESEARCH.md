# DDE NixOS Revival - Research Document

**Date:** 2026-02-25
**Goal:** Revive Deepin Desktop Environment support for NixOS as a flake, targeting DDE 25 (DDE 7.0)
**Lead:** ktechmidas (monotoko) - previous attempt mixed Qt5/Qt6 and tried Treeland too early

## Key Decision: Qt6 Only
DDE 25 is **fully Qt6**. Confirmed by checking debian/control for all components.
No Qt5 needed. Use `qt6Packages.newScope` exclusively.
- dde-session-shell has a dedicated deepin 25 repo: `dde-session-shell-snipe` (Qt6-only)
- deepin-anything has Qt5 fallback code but auto-detects Qt6 first
- Dual-mode CMake in some repos is for backward compat with deepin 23, not needed for us
- Skip Treeland initially, focus on X11 with deepin-kwin

---

## Table of Contents
1. [History of DDE in NixOS](#1-history-of-dde-in-nixos)
2. [Why It Was Removed](#2-why-it-was-removed)
3. [Current State of DDE 25](#3-current-state-of-dde-25)
4. [Arch Linux DDE Port Status](#4-arch-linux-dde-port-status)
5. [Original dde-nixos Flake Analysis](#5-original-dde-nixos-flake-analysis)
6. [DDE 25 Component Architecture](#6-dde-25-component-architecture)
7. [Build Order / Dependency Graph](#7-build-order--dependency-graph)
8. [Security Considerations](#8-security-considerations)
9. [Key Contacts & Community](#9-key-contacts--community)
10. [Strategy for Revival](#10-strategy-for-revival)
11. [Open Questions](#11-open-questions)
12. [Go Service Packaging Research (LAYER 8)](#12-go-service-packaging-research-layer-8)

---

## 1. History of DDE in NixOS

DDE has been in nixpkgs **twice**, and removed **twice**.

### First Era: DDE v20 (2019-2020)
- **Apr 2019**: romildo opened [#59023](https://github.com/NixOS/nixpkgs/issues/59023) tracking DDE packaging
- **Aug 2020**: romildo submitted [PR #96610](https://github.com/NixOS/nixpkgs/pull/96610) removing everything
- **Maintainers**: romildo, worldofpeace
- **Reason**: FHS hardcoding, poor upstream release quality, KWin broken, language barrier, packages becoming DDE-dependent

### Second Era: DDE v23 (2022-2025)
- **Aug 2022**: wineee (rewine) announced new DDE port on [NixOS Discourse](https://discourse.nixos.org/t/progress-on-porting-the-deepin-desktop-environment-dde-to-nixos/20733)
- **Mar 2022**: External flake created at [martyr-deepin/dde-nixos](https://github.com/martyr-deepin/dde-nixos)
- **Jan-Apr 2023**: DTK libs upstreamed via [PR #210477](https://github.com/NixOS/nixpkgs/pull/210477)
- **May 2023**: NixOS module merged via [PR #227936](https://github.com/NixOS/nixpkgs/pull/227936)
- **Nov 2023**: Upgraded to DDE v23 via [PR #257400](https://github.com/NixOS/nixpkgs/pull/257400)
- **Sep 2024**: Last major update [PR #337842](https://github.com/NixOS/nixpkgs/pull/337842)
- **Jul 2025**: wineee opened [#422090](https://github.com/NixOS/nixpkgs/issues/422090) considering removal
- **Aug 2025**: Cryolitia (deepin team) volunteered then withdrew due to job change
- **Aug 21, 2025**: [PR #430298](https://github.com/NixOS/nixpkgs/pull/430298) merged, removing DDE as part of Qt5 cleanup
- **Maintainer**: wineee (sole maintainer, 1182 of 1192 commits to the flake)

---

## 2. Why It Was Removed

### Technical Challenges (persistent across both eras)
1. **FHS path hardcoding** - Hundreds of `substituteInPlace` patches needed for `/usr/share`, `/var/lib`, `/etc` paths
2. **Qt private API usage** - Even minor Qt bumps (6.9, 6.9.2) broke Deepin libraries
3. **Deepin-specific incompatible code** - Riddled with code specific to Deepin OS or UOS
4. **Sole maintainer burnout** - wineee was the only person maintaining for years

### Immediate Triggers (2025)
- Qt 6.9 update broke system tray, "severely affecting usability"
- wineee switched to KDE personally, couldn't guarantee quality
- Nearly a year without major updates
- DDE 25 released upstream but nobody willing to do the massive porting work

### openSUSE Security Removal (May 2025)
openSUSE removed DDE entirely citing:
- D-Bus services running as root with unauthenticated methods
- Race conditions in Polkit authentication
- Privilege escalation flaws in dde-file-manager
- Local root exploit in deepin-api-proxy (CVE-2025-23222)
- Polkit methods with only "TODO" markers instead of auth
- "Lacking security culture" assessment
- Source: https://security.opensuse.org/2025/05/07/deepin-desktop-removal.html

### Community Sentiment at Removal
- Cryolitia: "There's no point in leaving behind a project that's severely outdated, has numerous security issues, and isn't actively addressing them upstream"
- K900 noted it was part of broader Qt5 cleanup
- BLumia (upstream) pointed interested porters to https://t.me/ddeport
- Cryolitia: "wouldn't stop anyone from reintroducing DDE into nixpkgs, as long as it will remain well maintained"
- ktechmidas and ivecl7 expressed interest but no concrete effort materialized

---

## 3. Current State of DDE 25

### Release Timeline
- **Jun 2025**: deepin 25 official release ("All Advancing, All Renewed")
- **Jan 2026**: deepin 25.0.10 (latest point release)
- Brand name: **DDE 7.0**
- Based on Debian 12, Linux 6.12

### Major Architectural Changes from DDE 23

| Aspect | DDE 23 | DDE 25 / DDE 7.0 |
|--------|--------|-------------------|
| Qt version | Qt5 (transitioning) | **Qt 6.8+** |
| UI framework | QWidget (C++) | **QML/QtQuick** (dtk6declarative) |
| DTK version | DTK5 (5.6.x) | **DTK6 (6.0.50)** |
| Window manager | deepin-kwin | deepin-kwin (default) + **Treeland** (preview) |
| Display manager | LightDM | LightDM (X11) + **DDM** (Wayland) |
| Dock/Panel | dde-dock | **dde-shell** (plugin-based) |
| Launcher | dde-launcher | **dde-launchpad** |
| Display server | X11 only | X11 (default) + **Wayland/Treeland** (preview) |
| Build system | CMake | CMake |

### Key New Components
- **dde-shell** (v2.0.29) - Unified plugin-based shell replacing dde-dock
- **dde-launchpad** (v2.0.26) - New launcher replacing dde-launcher
- **treeland** (v0.8.3) - New Wayland compositor (wlroots + Qt)
- **ddm** (v0.3.2) - SDDM fork for Wayland
- **dtk6declarative** (v6.0.50) - QML toolkit, the future UI framework

### Treeland Wayland Stack
```
wlroots 0.19 -> qwlroots (Qt bindings) -> waylib (QtQuick objects) -> treeland
```
- repos: vioken/qwlroots, vioken/waylib, linuxdeepin/treeland
- Treeland is tech preview only - X11 still default
- Does NOT support Wine applications yet
- Some external display issues remain

### DTK6 Library Stack
```
dtkcommon -> dtkcore (6.0.50) -> dtkgui (6.0.50) -> dtkwidget (6.0.50)
                                                 \-> dtkdeclarative (6.0.50)
                              \-> dtksystemsettings
```

---

## 4. Arch Linux DDE Port Status

### Current State
- Ships **DDE V23** (NOT DDE 25) - ~63 official packages across `deepin` + `deepin-extra` groups
- Primary maintainer: **Felix Yan (felixonmars)**
- Both DTK5 and DTK6 stacks maintained in parallel
- treeland (0.8.1-2) and ddm (0.3.1-1) are packaged but experimental

### No Organized DDE 25 Porting Effort
- Aug 2025 forum thread got "try it and see" response
- Felix Yan noted blockers: Treeland dev versions were kept closed-source, deepin-kwin maintenance poor
- Deepin community monthly report (Jan 2026) mentions improved Arch support, suggesting some upstream awareness

### Patches Arch Applies (very relevant for us)
Key patterns across PKGBUILDs:
1. **Path fixups**: `/usr/libexec` -> `/usr/lib`
2. **Feature disabling**: Authentication plugin removed (needs unavailable `dareader`), privacy plugin removed, language settings disabled, update module disabled
3. **OS detection workarounds**: `/etc/os-version` -> `/etc/uos-version`
4. **Background paths**: Fixed from `/usr/share/backgrounds/` to `/usr/share/backgrounds/deepin/`
5. **Compiler compat**: GCC 15 patches, LTO disabling
6. **Qt version compat**: Qt 6.10 patches for treeland and control-center
7. **Cherry-picked upstream fixes**: Various commits backported

### Arch PKGBUILD Sources
- https://gitlab.archlinux.org/archlinux/packaging/packages (search "deepin")

### Security Warning
Arch Wiki carries openSUSE security warning but has NOT removed DDE (unlike openSUSE). Felix monitoring situation.

---

## 5. Original dde-nixos Flake Analysis

### Repository: martyr-deepin/dde-nixos (ARCHIVED)
- Created March 2022, archived ~July 2024
- 33 stars, 6 forks
- ~81 Qt5 packages + 11 experimental Qt6 packages
- MIT license

### Structure
```
flake.nix              # Main flake (nixos-unstable + flake-utils)
packages/
  default.nix          # Qt5 scope via makeScope + libsForQt5.newScope
  qt6.nix              # Qt6 scope via qt6Packages.newScope (experimental)
  library/             # DTK libs (19 packages)
  core/                # Desktop shell (22 packages)
  apps/                # Applications (20 packages)
  artwork/             # Themes/icons (6 packages)
  tools/               # Utilities (3 packages)
  misc/                # Base, turbo, gsettings (3 packages)
  go-package/          # Go daemons (5 packages)
  os-specific/         # Kernel modules (1 package)
  third-party/         # Community (2 packages)
vm/                    # QEMU VM test config
```

### Key Techniques Used
1. **`makeScope` with `newScope`** - Self-contained package scope for all DDE packages
2. **Helper functions for FHS patching**: `getPatchFrom`, `getUsrPatchFrom`, `replaceAll`
3. **Per-package `substituteInPlace`** replacing paths to `/run/current-system/sw`
4. **Custom `.patch` files** for pkg-config and Qt .pri paths
5. **`buildGoModule`** with vendored deps for Go components
6. **Garnix CI** for binary cache
7. **QEMU VM** for testing with `nix run`
8. **Multiple outputs** (`out`, `dev`, `doc`)

### NixOS Module Provided
- `services.xserver.desktopManager.deepin-unstable.enable`
- `services.xserver.desktopManager.deepin-unstable.full`
- Sub-modules for dde-daemon, deepin-anything, dde-api, app-services
- Auto-configured: bluetooth, pulseaudio, polkit, colord, accounts-daemon, gvfs, keyring, NetworkManager, udisks2, upower, dconf, XDG portals
- Registered dde-x11 session for display managers

### Forks of Interest
| Fork | Notes |
|------|-------|
| **ktechmidas/dde-nixos** | Description: "dde 25 on NixOS", last activity Sept 2025 |
| linuxdeepin365/10002-dde-nixos | Early WIP fork, July 2022 |
| Aleksanaa/dde-nixos | July 2023 |

---

## 6. DDE 25 Component Architecture

### Complete Component List by Category

#### DTK6 Libraries (LAYER 1-4, build first)
| Component | Version | Language | Notes |
|-----------|---------|----------|-------|
| dtkcommon | shared | CMake | Build macros, must be first |
| dtk6core | 6.0.50 | C++ 94.6% | Core utils, DConfig, D-Bus |
| dtk6gui | 6.0.50 | C++ 96.6% | GUI primitives, icons, theming |
| dtk6widget | 6.0.50 | C++ 98.7% | QWidget toolkit |
| dtk6declarative | 6.0.50 | C++/QML | QML toolkit (the future) |
| dtksystemsettings | - | C++ | System settings API |

#### Qt Platform Integration (LAYER 5)
| Component | Notes |
|-----------|-------|
| qt6platform-plugins | QPA plugins for X11/Wayland |
| qt6integration | Theme plugins for Qt apps |

#### Wayland Stack (LAYER 6, optional for X11-only)
| Component | Version | Notes |
|-----------|---------|-------|
| qwlroots | 0.5.3 | Qt bindings for wlroots (vioken org) |
| waylib | 0.6.14 | QtQuick wlroots wrapper (vioken org) |
| treeland | 0.8.3 | Wayland compositor |
| treeland-protocols | - | Custom Wayland protocols |
| deepin-wayland-protocols | - | Deepin-specific Wayland extensions |

#### X11 Window Manager (LAYER 6, alternative to Treeland)
| Component | Version | Notes |
|-----------|---------|-------|
| deepin-kwin | 5.14.5.1 | KWin fork, needs KDE Frameworks 6 |

#### Display Manager (LAYER 7)
| Component | Version | Notes |
|-----------|---------|-------|
| ddm | 0.3.2 | SDDM fork for Wayland |

#### Go-based System Services (LAYER 8)
| Component | Language | Notes |
|-----------|----------|-------|
| dde-api | Go 84.8% | D-Bus interface library |
| dde-daemon | Go 95.1% | Primary system/session daemon |
| startdde | Go 96.9% | Session starter |
| deepin-desktop-schemas | Go/Shell | GSettings schemas |

#### Core Services (LAYER 9)
| Component | Notes |
|-----------|-------|
| deepin-service-manager | D-Bus service lifecycle |
| dde-polkit-agent | PolicyKit auth agent |
| dde-application-manager | App lifecycle management |
| dde-appearance | Theme/wallpaper management |
| dde-network-core | Network management |

#### Shell Framework (LAYER 10)
| Component | Version | Notes |
|-----------|---------|-------|
| dde-tray-loader | 2.0.25 | System tray plugins |
| dde-shell | 2.0.29 | Unified shell (dock/panel/tray) - C++ 75%, QML 21% |

#### Desktop Applications (LAYER 11)
| Component | Notes |
|-----------|-------|
| dde-launchpad | App launcher (depends on dde-shell) |
| dde-control-center | System settings (depends on dde-shell) |
| dde-file-manager | File manager |
| dde-session-shell | Lock screen / greeter |
| dde-clipboard | Clipboard manager |
| dde-grand-search | Desktop search |

#### Session (LAYER 12)
| Component | Notes |
|-----------|-------|
| dde-session | systemd-based session launcher |
| dde-session-ui | Session UI (shutdown dialog, etc.) |

#### Artwork
| Component | Notes |
|-----------|-------|
| deepin-desktop-theme | Desktop themes |
| deepin-icon-theme | Icon set |
| deepin-sound-theme | Sound effects |
| deepin-wallpapers | Wallpapers |
| dde-account-faces | User avatars |

---

## 7. Build Order / Dependency Graph

```
LAYER 0 - External Prerequisites:
  Qt 6.8+, KDE Frameworks 6, wlroots 0.19, Go compiler
  wayland-protocols, wlr-protocols, systemd, extra-cmake-modules

LAYER 1 - Common Infrastructure:
  dtkcommon, deepin-wayland-protocols, treeland-protocols, deepin-desktop-schemas

LAYER 2 - Core Library:
  dtkcore (depends: dtkcommon, Qt, ICU, uchardet, dbus)

LAYER 3 - GUI Libraries:
  dtkgui (depends: dtkcore, librsvg)
  dtksystemsettings (depends: dtkcore)

LAYER 4 - Widget Libraries:
  dtkwidget (depends: dtkcore, dtkgui)
  dtkdeclarative (depends: dtkcore, dtkgui)

LAYER 5 - Platform Integration:
  qt6platform-plugins (depends: Qt, XCB)
  qt6integration (depends: DTK, Qt, GTK)

LAYER 6 - Compositor (choose path):
  X11 PATH: deepin-kwin (depends: KDE Frameworks 6, Qt6)
  WAYLAND PATH: qwlroots -> waylib -> treeland

LAYER 7 - Display Manager:
  ddm (depends: Qt, PAM)

LAYER 8 - Go Services:
  dde-api -> dde-daemon -> startdde

LAYER 9 - Core Services:
  deepin-service-manager, dde-polkit-agent, dde-application-manager, dde-appearance

LAYER 10 - Shell:
  dde-tray-loader -> dde-shell

LAYER 11 - Applications:
  dde-launchpad, dde-control-center, dde-file-manager, dde-session-shell

LAYER 12 - Session:
  dde-session, dde-session-ui
```

---

## 8. Security Considerations

### Known Issues (from openSUSE audit)
- CVE-2025-23222: Privilege escalation in dde-api-proxy
- D-Bus root services with unauthenticated methods
- Polkit race conditions
- File manager daemon allowing arbitrary group creation
- Upstream fix for dde-api-proxy deemed insufficient by SUSE researchers

### Our Approach Should
- Audit which of these issues are fixed in DDE 25
- Consider NOT packaging dde-api-proxy (or sandboxing it heavily)
- Review all D-Bus service files for root-running services
- Document known security status transparently
- Consider NixOS-specific hardening (systemd sandboxing, minimal capabilities)

### Note
- Arch has NOT removed DDE despite the warnings
- The security issues are primarily in older components; DDE 25 may have addressed some
- We should check upstream commit history for security fixes

---

## 9. Key Contacts & Community

### People
- **wineee/rewine** - Original NixOS DDE maintainer (now using KDE, but knowledgeable)
- **Cryolitia** - Former Deepin team member, was `cryolitia@deepin.org`
- **BLumia** - Deepin upstream developer, active on GitHub
- **Felix Yan (felixonmars)** - Arch DDE maintainer
- **K900** - NixOS member who did the removal PR
- **ktechmidas** - Forked dde-nixos with "dde 25" intent

### Community Channels
- **Telegram**: https://t.me/ddeport (DDE porting group, recommended by BLumia)
- **NixOS Discourse**: https://discourse.nixos.org/t/progress-on-porting-the-deepin-desktop-environment-dde-to-nixos/20733
- **GitHub**: https://github.com/linuxdeepin (258 repos)
- **Arch GitLab**: https://gitlab.archlinux.org/archlinux/packaging/packages (PKGBUILD reference)

---

## 10. Strategy for Revival

### Phase 1: Foundation (DTK6 + minimal desktop)
**Goal**: Get DTK6 libraries building and a minimal X11 session working

1. Fork or start fresh flake based on martyr-deepin/dde-nixos structure
2. Port DTK6 libraries first: dtkcommon -> dtkcore -> dtkgui -> dtkwidget -> dtkdeclarative
3. Port qt6platform-plugins + qt6integration
4. Port deepin-kwin (X11 window manager, skip Treeland initially)
5. Port Go services: dde-api -> dde-daemon -> startdde
6. Get a basic X11 session booting

### Phase 2: Desktop Shell
**Goal**: Functional desktop with dock, launcher, and settings

7. Port dde-shell (the new unified shell)
8. Port dde-tray-loader
9. Port dde-launchpad
10. Port dde-control-center
11. Port dde-session + dde-session-shell
12. Port dde-file-manager

### Phase 3: Polish & Applications
**Goal**: Full desktop experience

13. Port remaining services (appearance, network, clipboard, etc.)
14. Port applications (terminal, editor, calculator, etc.)
15. Port artwork (themes, icons, wallpapers)
16. Write NixOS module
17. Set up CI/binary cache

### Phase 4: Wayland (Optional/Future)
**Goal**: Treeland support

18. Port qwlroots, waylib, treeland
19. Port ddm
20. Add Wayland session option to NixOS module

### Key Technical Decisions
- **Use `makeScope` with `qt6Packages.newScope`** (proven pattern from original flake)
- **Target nixos-unstable** for latest Qt6
- **Start with X11 only** - Treeland is still preview even upstream
- **Borrow Arch patches heavily** - They've solved many of the same problems
- **Binary cache from day 1** - Garnix or similar, these builds are heavy
- **VM testing** - Include QEMU VM config like original flake

### What We Can Borrow from Arch
- Path fixup patterns (`/usr/libexec` -> appropriate NixOS paths)
- Feature disabling flags (`-DDISABLE_AUTHENTICATION=YES`, etc.)
- Qt version compatibility patches
- OS detection workarounds
- GCC compatibility patches
- Knowledge of which components are actually needed vs. Deepin-OS-specific

### NixOS-Specific Challenges to Solve
- FHS path patching (the #1 challenge historically)
- Go module packaging (dde-daemon, startdde use Go)
- D-Bus service registration
- systemd user service integration
- XDG desktop session registration
- GSettings schema compilation
- Qt plugin path discovery
- Runtime path resolution (components finding each other)

---

## 11. Open Questions

1. **Has ktechmidas made any progress?** Their fork says "dde 25 on NixOS" - worth reaching out
2. **What security fixes has DDE 25 actually shipped?** Need to audit CVE-2025-23222 status
3. **Is wineee willing to advise?** They have deep knowledge of the NixOS-specific challenges
4. **What's the minimum viable desktop?** Can we skip some components entirely?
5. **Qt 6.8 availability in nixpkgs?** Need to verify nixos-unstable has Qt >= 6.8
6. **wlroots 0.19 in nixpkgs?** Needed for Treeland (phase 4)
7. **Should we join the Telegram porting group?** BLumia recommended it for known pitfalls
8. **Go module hashes** - All Go components need vendorHash computed
9. **dde-api-proxy** - Should we package it at all given the security issues?
10. **Linglong/Linyaps** - Skip entirely for NixOS (we have Nix)

---

## Appendix: Key URLs

### nixpkgs History
- Original tracking: https://github.com/NixOS/nixpkgs/issues/59023
- First removal: https://github.com/NixOS/nixpkgs/pull/96610
- Second era init: https://github.com/NixOS/nixpkgs/pull/210477
- Module init: https://github.com/NixOS/nixpkgs/pull/227936
- v23 upgrade: https://github.com/NixOS/nixpkgs/pull/257400
- Last update: https://github.com/NixOS/nixpkgs/pull/337842
- Removal discussion: https://github.com/NixOS/nixpkgs/issues/422090
- Removal PR: https://github.com/NixOS/nixpkgs/pull/430298

### Upstream
- GitHub org: https://github.com/linuxdeepin
- DDE meta-package: https://github.com/linuxdeepin/dde
- Treeland: https://github.com/linuxdeepin/treeland
- DTK6: https://github.com/linuxdeepin/dtk6core

### Flakes/Forks
- Original (archived): https://github.com/martyr-deepin/dde-nixos
- ktechmidas fork: https://github.com/ktechmidas/dde-nixos
- linuxdeepin365 WIP: https://github.com/linuxdeepin365/10002-dde-nixos

### Reference Distros
- Arch PKGBUILDs: https://gitlab.archlinux.org/archlinux/packaging/packages
- Arch Wiki: https://wiki.archlinux.org/title/Deepin_Desktop_Environment
- openSUSE security: https://security.opensuse.org/2025/05/07/deepin-desktop-removal.html

### Community
- Telegram porting group: https://t.me/ddeport
- NixOS Discourse thread: https://discourse.nixos.org/t/progress-on-porting-the-deepin-desktop-environment-dde-to-nixos/20733

---

## 12. Go Service Packaging Research (LAYER 8)

**Date:** 2026-02-26
**Packages:** startdde, dde-daemon, dde-api
**Build system:** All three use `buildGoModule` with Makefile wrappers
**Go version:** All require Go 1.20+
**Dependencies vendor in-source:** NO (none have a `vendor/` directory)
**All have go.sum:** YES (needed for `buildGoModule` vendorHash computation)

### Dependency Chain
```
dde-api (standalone, no DDE Go deps)
   ^
   |
dde-daemon (depends on dde-api as Go module)
   ^
   |
startdde (depends on dde-api as Go module)
```

Note: startdde and dde-daemon both import `dde-api` as a Go module dependency.
dde-api does NOT depend on either of the others. This is the build order.

### Old nixpkgs Packaging Reference

All three had working `buildGoModule` expressions in nixpkgs before the August 2025 removal
(commit `96e751adaf2f`, parent of the `deepin: drop` commit `25303238b95d`).
Located at `pkgs/desktops/deepin/go-package/{startdde,dde-daemon,dde-api}/default.nix`.

Key patterns from the old packaging:
- Used `buildGoModule` with `vendorHash` (not vendored in-source)
- Custom `buildPhase` calling `make` with `GO_BUILD_FLAGS="$GOFLAGS"` or `GOBUILD_OPTIONS="$GOFLAGS"`
- Custom `installPhase` calling `make install DESTDIR="$out" PREFIX="/"`
- Extensive `substituteInPlace` for hardcoded paths
- `wrapGAppsHook3` for GTK/GLib integration
- `postFixup` wrapping binaries with runtime PATH dependencies

---

### 12.1 startdde (Session Starter)

**Repo:** https://github.com/linuxdeepin/startdde
**Latest release:** 6.1.6 (2025-03-27)
**Source hash:** `sha256-znpp5lyGNUTHfyHcIu05pCWgzdNB0sKr+jNPZm+86O4=`
**Scale:** 68 Go files, ~21,700 lines of Go, 0 C files

#### Can it be built with buildGoModule?
YES. It has `go.mod` and `go.sum` (73 lines). No vendor directory -- needs `vendorHash`.
The old nixpkgs used `buildGoModule` successfully.

#### Build System
Makefile wrapping `go build`. Key targets:
- `startdde` binary (main session starter)
- `fix-xauthority-perm` binary (setuid helper)
- `translate` (msgfmt for locale .po files)
- `install` target puts files under `$DESTDIR$PREFIX`

Build command: `make GO_BUILD_FLAGS="$GOFLAGS"`
Install command: `make install DESTDIR="$out" PREFIX="/"`

#### CGo / Native Dependencies
```
#cgo pkg-config: x11
```
- **pkg-config deps:** `x11` (libX11)
- **nativeBuildInputs needed:** `pkg-config`, `gettext` (for msgfmt), `jq`, `wrapGAppsHook3`, `glib`
- **buildInputs needed:** `libX11`, `libgnome-keyring`, `gtk3`, `alsa-lib`, `pulseaudio`, `libgudev`, `libsecret`

#### Go Module Dependencies (from go.mod)
```
github.com/godbus/dbus/v5              v5.1.0
github.com/linuxdeepin/dde-api         v0.0.0-20241128100002
github.com/linuxdeepin/go-dbus-factory  v0.0.0-20241205055755
github.com/linuxdeepin/go-gir          v0.0.0-20230413065249
github.com/linuxdeepin/go-lib          v0.0.0-20230406092403
github.com/linuxdeepin/go-x11-client   v0.0.0-20230131052004
github.com/stretchr/testify            v1.8.2
golang.org/x/xerrors
```

#### Hardcoded Paths (4 files affected)
| File | Path | Purpose |
|------|------|---------|
| `display/manager.go` | `/usr/lib/deepin-daemon/dde-touchscreen-dialog` | Touchscreen dialog binary |
| `display/color_temp.go` | `/usr/share/zoneinfo/zone1970.tab` | Timezone data |
| `main.go` | reference to `/usr/sbin/lightdm-session` | Comment only |
| `xsettings/xsettings.go` | `/etc/lightdm/deepin/qt-theme.ini` | LightDM config |

**Patching difficulty: LOW** -- only ~4 paths to fix.

#### Install Artifacts
- `$PREFIX/bin/startdde`
- `$PREFIX/sbin/deepin-fix-xauthority-perm`
- `$PREFIX/lib/deepin-daemon/greeter-display-daemon` (symlink to startdde)
- `$PREFIX/share/lightdm/lightdm.conf.d/60-deepin.conf`
- `$PREFIX/share/startdde/filter.conf`
- `$PREFIX/share/glib-2.0/schemas/*.xml`
- `$PREFIX/share/dsg/configs/org.deepin.startdde/*.json`
- `$PREFIX/lib/systemd/user/dde-display-task-refresh-brightness.service`
- `$PREFIX/share/locale/*/LC_MESSAGES/startdde.mo`

---

### 12.2 dde-daemon (System/Session Daemon)

**Repo:** https://github.com/linuxdeepin/dde-daemon
**Latest release:** 6.1.75 (2026-02-06) -- actively developed
**Source hash:** `sha256-Mw1DUbqiYfx2+VHKYRZqsVScqAo5wuzd7BkxC7Qvy+o=`
**Scale:** 521 Go files, ~98,400 lines of Go, 29 C/H files, 15 binaries produced

THIS IS THE BIGGEST AND HARDEST PACKAGE.

#### Can it be built with buildGoModule?
YES. Has `go.mod` and `go.sum` (138 lines). No vendor directory -- needs `vendorHash`.

#### Build System
Makefile wrapping `go build`. Produces 15 binaries:
```
dde-session-daemon    dde-system-daemon    grub2
search                backlight_helper     langselector
soundeffect           dde-lockservice      default-terminal
dde-greeter-setter    default-file-manager greeter-display-daemon
fix-xauthority-perm   user-config          desktop-toggle (pure C)
```

Note: `desktop-toggle` is a **pure C binary** (`bin/desktop-toggle/main.c`) built with
`gcc $^ $(pkg-config --cflags --libs x11)`. This needs special handling in buildGoModule.

Build also requires:
- `python3` (for `misc/icons/install_to_hicolor.py`)
- `deepin-policy-ts-convert` (for polkit policy translation)
- `msgfmt` (gettext, for locale files)

Build command: `make GOBUILD_OPTIONS="$GOFLAGS"`
Install command: `make install DESTDIR="$out" PREFIX="/"`

#### CGo / Native Dependencies (EXTENSIVE)
```
pkg-config: x11, ddcutil, xi, libudev, libinput, glib-2.0, alsa
LDFLAGS: -lcrypt, -ldl, -lpthread, -ludev, -lm
```

**nativeBuildInputs needed:**
- `pkg-config`, `deepin-gettext-tools`, `gettext`, `python3`, `wrapGAppsHook3`

**buildInputs needed:**
- `ddcutil` (DDC/CI monitor control)
- `linux-pam`, `libxcrypt` (account/password management)
- `alsa-lib` (ALSA audio)
- `glib` (GLib/GIO)
- `libgudev` (udev GObject)
- `gtk3`, `gdk-pixbuf-xlib` (UI components)
- `networkmanager` (network management)
- `libinput` (input device management)
- `libnl` (netlink)
- `librsvg` (SVG rendering)
- `pulseaudio` (PulseAudio audio)
- `tzdata` (timezone data)
- `xkeyboard_config` (keyboard layouts)
- `libX11`, `libXi` (X11)

**Runtime PATH needed:**
- `util-linux`, `dde-session-ui`, `glib`, `lshw`, `dmidecode`, `systemd`

#### Go Module Dependencies (from go.mod)
```
github.com/adrg/xdg                    v0.5.3
github.com/fsnotify/fsnotify           v1.8.0
github.com/godbus/dbus/v5              v5.1.0
github.com/jouyouyun/hardware          v0.1.8
github.com/linuxdeepin/dde-api         v0.0.0-20260131071225
github.com/linuxdeepin/go-dbus-factory  v0.0.0-20260131085755
github.com/linuxdeepin/go-gir          v0.0.0-20251204113853
github.com/linuxdeepin/go-lib          v0.0.0-20251106065207
github.com/linuxdeepin/go-x11-client   v0.0.0-20240415051504
github.com/mdlayher/netlink            v1.7.2
github.com/rickb777/date               v1.21.1
github.com/stretchr/testify            v1.9.0
golang.org/x/xerrors
google.golang.org/protobuf             v1.34.2
```

#### Hardcoded Paths (MASSIVE -- ~80+ occurrences across 60+ files)

Major categories:
1. **Binary paths:** `/usr/lib/deepin-daemon/*`, `/usr/lib/deepin-api/*`, `/usr/bin/dde-control-center`, `/usr/bin/setxkbmap`, `/usr/bin/deepin-system-monitor`, etc.
2. **Data paths:** `/usr/share/X11/xkb`, `/usr/share/zoneinfo`, `/usr/share/wallpapers`, `/usr/share/dde-daemon`, `/usr/share/dde`, `/usr/share/backgrounds`
3. **Config paths:** `/etc/default/locale`, `/etc/default/grub.d`, `/etc/deepin`, `/etc/pam.d`, `/etc/NetworkManager`, `/etc/shells`, `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/sudoers`, `/etc/lightdm`, `/etc/gdm`, `/etc/sddm.conf`, etc.
4. **PATH overrides:** `os.Setenv("PATH", "/usr/local/sbin:/usr/local/bin:...")` in grub2/modify_manger.go and bin/dde-system-daemon/main.go
5. **libexec paths:** `/usr/libexec/dde-daemon/keybinding/*`
6. **Lib paths:** `/usr/lib/deepin-daemon/*` (dozens of references)

**Patching difficulty: HIGH** -- This is the #1 hardest package. The old nixpkgs used:
- 3 dedicated `.diff` patch files
- A global `sed` replacing `/usr/lib/deepin-daemon` with `/run/current-system/sw/lib/deepin-daemon`
- Many individual `substituteInPlace` calls
- `patchShebangs` for shell scripts
- `strings.Contains` instead of exact path matching for binary detection

**Old patches (from nixpkgs `96e751adaf2f`):**
1. `0001-dont-set-PATH.diff` -- Removes the hardcoded PATH override in grub2/modify_manger.go
2. `0002-fix-custom-wallpapers-path.diff` -- Moves wallpapers to `/var/lib/dde-daemon/` and fixes head command path
3. `0003-aviod-use-hardcode-path.diff` -- Replaces exact binary path matching with `strings.Contains` for dde-control-center, dde-lock, lightdm-deepin-greeter, fprintd; fixes dbus-send in udev rules; fixes shutdown command

These patches will need updating for the new version (6.1.75 vs 6.0.43) but the patterns are the same.

#### Install Artifacts (extensive)
- 15 binaries in `$PREFIX/lib/deepin-daemon/`
- D-Bus configs in `$PREFIX/share/dbus-1/system.d/`
- D-Bus session/system services
- Polkit actions + rules
- systemd user + system services
- PAM configs in `/etc/pam.d/`
- GRUB configs in `/etc/default/grub.d/`
- Deepin configs in `/etc/deepin/`
- PulseAudio configs in `/etc/pulse/daemon.conf.d/`
- GSettings schemas
- Locale files
- Icons
- Service trigger JSON configs
- Shell scripts in `$PREFIX/lib/deepin-daemon/` and `$PREFIX/libexec/dde-daemon/`
- DConfig settings JSONs

---

### 12.3 dde-api (D-Bus API)

**Repo:** https://github.com/linuxdeepin/dde-api
**Latest release:** 6.0.35 (2026-02-05) -- actively developed
**Source hash:** `sha256-jCy4AJCKUVL4ZCvqr25Rxse+NZkPkEQR+I2Oyv/IGuo=`
**Scale:** 86 Go files, ~14,700 lines of Go, 12 C/H files

#### Can it be built with buildGoModule?
YES. Has `go.mod` and `go.sum` (115 lines). No vendor directory -- needs `vendorHash`.

#### Build System
Makefile wrapping `go build`. Produces 10 binaries:
```
device             graphic            locale-helper
hans2pinyin        sound-theme-player deepin-shutdown-sound
dde-open           adjust-grub-theme  image-blur
image-blur-helper
```

Also builds Go libraries (installed to `$GOSITE_DIR`):
```
dxinput  drandr  soundutils  lang_info  i18n_dependent
session  language_support  userenv  inhibit_hint
powersupply  polkit
```

Build command: `make GOBUILD_OPTIONS="$GOFLAGS"`
Install command: `make install DESTDIR="$out" PREFIX="/"`

Note: `ts-to-policy` target requires `deepin-policy-ts-convert` (from `deepin-gettext-tools`).

#### CGo / Native Dependencies
```
pkg-config: x11, xi
```

**nativeBuildInputs needed:**
- `pkg-config`, `deepin-gettext-tools`, `wrapGAppsHook3`

**buildInputs needed:**
- `alsa-lib` (ALSA audio)
- `gtk3` (UI)
- `libcanberra` (event sounds)
- `libgudev` (udev GObject)
- `librsvg` (SVG)
- `poppler` (PDF rendering)
- `pulseaudio` (audio)
- `gdk-pixbuf-xlib` (image handling)
- `libX11`, `libXi` (X11)

#### Go Module Dependencies (from go.mod)
```
github.com/disintegration/imaging      v1.6.2
github.com/fogleman/gg                 v1.3.0
github.com/godbus/dbus/v5              v5.1.0
github.com/gosexy/gettext              v0.0.0-20160830220431
github.com/linuxdeepin/go-dbus-factory  v0.0.0-20251106065250
github.com/linuxdeepin/go-gir          v0.0.0-20251127080441
github.com/linuxdeepin/go-lib          v0.0.0-20251106065207
github.com/linuxdeepin/go-x11-client   v0.0.0-20230131052004
github.com/nfnt/resize
github.com/stretchr/testify            v1.8.1
gopkg.in/alecthomas/kingpin.v2         v2.2.6
```

Notable: includes image processing (`imaging`, `gg`, `resize`), gettext, kingpin CLI parser.

#### Hardcoded Paths (9 files affected, moderate)
| File | Path | Purpose |
|------|------|---------|
| `locale-helper/main.go` | `/usr/sbin/locale-gen`, `/usr/sbin/deepin-immutable-ctl` | Locale generation |
| `locale-helper/ifc.go` | `/etc/default/locale`, `/etc/locale.gen` | Locale config |
| `i18n_dependent/i18n_dependent.go` | `/usr/share/i18n/i18n_dependent.json` | i18n data |
| `sound-theme-player/utils.go` | `/etc/lightdm/lightdm.conf` | LightDM detection |
| `sound-theme-player/main.go` | `/usr/sbin/alsactl` | ALSA control |
| `lang_info/lang_info.go` | `/usr/share/i18n/language_info.json`, `/usr/share/i18n/SUPPORTED` | Language data |
| `language_support/lang_support.go` | `/usr/bin/dpkg-query`, `/usr/bin/apt-cache` | Debian-specific! |
| `adjust-grub-theme/main.go` | `/usr/share/dde-api/data/grub-themes/`, `/etc/os-version` | GRUB themes |
| `adjust-grub-theme/util.go` | `/etc/default/grub`, `/etc/default/locale`, `/etc/locale.conf` | GRUB/locale config |

**Patching difficulty: MODERATE** -- ~15-20 paths to fix. The `language_support` references to
`dpkg-query` and `apt-cache` are Debian-specific and will need to be stubbed or removed for NixOS.

#### Install Artifacts
- 10 binaries in `$PREFIX/lib/deepin-api/`
- `dde-open` also installed to `$PREFIX/bin/`
- Go libraries installed to `$GOSITE_DIR/src/github.com/linuxdeepin/dde-api/`
- D-Bus configs, services, system-services
- Polkit actions + rules
- systemd system services
- Data files in `$PREFIX/share/dde-api/data/`
- Icons in `$PREFIX/share/icons/hicolor/`
- Shell scripts from `misc/scripts/`

---

### 12.4 Shared Build Dependency: deepin-gettext-tools

Both dde-daemon and dde-api need `deepin-policy-ts-convert` at build time (and startdde
needs `deepin-update-pot`). This tool was also removed from nixpkgs.

**Old nixpkgs expression** (commit `96e751adaf2f`):
```nix
{ stdenv, fetchFromGitHub, gettext, python3Packages, perlPackages }:
stdenv.mkDerivation rec {
  pname = "deepin-gettext-tools";
  version = "1.0.11";
  src = fetchFromGitHub {
    owner = "linuxdeepin"; repo = pname; rev = version;
    sha256 = "sha256-V6X0E80352Vb6zwaBTRfZZnXEVCmBRbO2bca9A9OL6c=";
  };
  nativeBuildInputs = [ python3Packages.wrapPython ];
  buildInputs = [ gettext perlPackages.perl perlPackages.ConfigTiny perlPackages.XMLLibXML ];
  makeFlags = [ "PREFIX=${placeholder "out"}" ];
}
```

This is a simple stdenv package (not Go). Must be packaged first since it is needed by all three
Go packages at build time.

---

### 12.5 Summary Table

| | startdde | dde-daemon | dde-api |
|---|---|---|---|
| **Version** | 6.1.6 | 6.1.75 | 6.0.35 |
| **Release date** | 2025-03-27 | 2026-02-06 | 2026-02-05 |
| **Source SRI** | `sha256-znpp5l...86O4=` | `sha256-Mw1DUb...y+o=` | `sha256-jCy4AJ...Guo=` |
| **Go files** | 68 | 521 | 86 |
| **Lines of Go** | ~21,700 | ~98,400 | ~14,700 |
| **C files** | 0 | 29 | 12 |
| **Has go.sum** | YES (73 lines) | YES (138 lines) | YES (115 lines) |
| **Has vendor/** | NO | NO | NO |
| **buildGoModule** | YES | YES | YES |
| **vendorHash** | needs computing | needs computing | needs computing |
| **Binaries produced** | 2 | 15 | 10 |
| **CGo pkg-config** | x11 | x11, xi, ddcutil, libudev, libinput, glib-2.0, alsa | x11, xi |
| **Hardcoded paths** | ~4 | ~80+ | ~15-20 |
| **Patching difficulty** | LOW | HIGH | MODERATE |
| **Has Makefile** | YES | YES | YES |
| **Other build systems** | None | None | None |
| **Python needed** | No | Yes (icons) | No |
| **deepin-gettext-tools** | Yes (pot) | Yes (policy) | Yes (policy) |

### 12.6 vendorHash Strategy

None of the three packages vendor their Go dependencies. For NixOS `buildGoModule`:
- The `vendorHash` must be computed by attempting a build with `vendorHash = lib.fakeHash;`
- Nix will download the Go modules, fail, and report the correct hash
- This hash goes into the `vendorHash` attribute
- The fetched modules are cached in a fixed-output derivation

The old nixpkgs had working vendorHashes for version 6.0.x. Since we are targeting newer versions
(6.1.x for startdde/dde-daemon, 6.0.35 for dde-api), these hashes must be recomputed.

### 12.7 Build Order for Go Packages

```
1. deepin-gettext-tools  (stdenv, simple Make-based, needed by all three)
2. dde-api               (buildGoModule, no DDE Go deps, needed by the other two)
3. dde-daemon            (buildGoModule, depends on dde-api)
4. startdde              (buildGoModule, depends on dde-api)
```

Note: dde-daemon and startdde could build in parallel after dde-api, since they only
depend on dde-api as a Go module (fetched via vendorHash, not as a Nix build dep).

### 12.8 dde-daemon Deep Dive: Runtime Services & Architecture

**Date:** 2026-02-26 (extended research session)

#### What dde-daemon Actually Does

dde-daemon is the **central system/session management daemon** for the Deepin desktop.
It produces two main daemon binaries plus 13 helper binaries, managing virtually every
desktop subsystem via D-Bus interfaces.

##### dde-session-daemon (user session, runs per-user)
Manages session-level services activated on-demand via D-Bus:
- **Audio** (`org.deepin.dde.Audio1`) -- Audio device/volume management via PulseAudio + ALSA
- **Bluetooth** (`org.deepin.dde.Bluetooth1`) -- Bluetooth pairing, device management
- **InputDevices** (`org.deepin.dde.InputDevices1`) -- Keyboard layout, touchpad, mouse settings
- **Keybinding** (`org.deepin.dde.Keybinding1`) -- System keyboard shortcuts
- **LangSelector** (`org.deepin.dde.LangSelector1`) -- System language switching
- **Power** (`org.deepin.dde.Power1`) -- Power management, screen dimming, suspend/hibernate
- **Search** (`org.deepin.dde.Search1`) -- Desktop file search
- **SessionWatcher** (`org.deepin.dde.SessionWatcher1`) -- Session lifecycle tracking
- **SoundEffect** (`org.deepin.dde.SoundEffect1`) -- System sound effects
- **SystemInfo** (`org.deepin.dde.SystemInfo1`) -- System information provider
- **Timedate** (`org.deepin.dde.Timedate1`) -- Time/date/timezone management
- **XEventMonitor** (`org.deepin.dde.XEventMonitor1`) -- X11 input event monitoring
- **Zone** (`org.deepin.dde.Zone1`) -- Hot corners/screen edges
- **LastoreSessionHelper** (`org.deepin.dde.LastoreSessionHelper1`) -- Software update helper
- **Clipboard** -- Clipboard management
- **Display** -- Display/monitor management
- **Screensaver** -- Screensaver management
- **Service-trigger** -- On-demand service activation
- **EventLog** -- Usage event logging (optional)

Modules can be selectively enabled/disabled. Treeland-incompatible modules (x-event-monitor,
keybinding, screensaver, display, xsettings) are auto-skipped when running under Treeland/Wayland.

##### dde-system-daemon (system-level, runs as root via systemd)
Manages privileged operations:
- **Accounts** (`org.deepin.dde.Accounts1`) -- User account management (create/delete/modify)
- **AirplaneMode** (`org.deepin.dde.AirplaneMode1`) -- RF kill switch management
- **Bluetooth** (system) (`org.deepin.dde.Bluetooth1`) -- Privileged BT operations
- **Display** (system) (`org.deepin.dde.Display1`) -- Privileged display config
- **Gesture** (`org.deepin.dde.Gesture1`) -- Touchpad gesture recognition (uses libinput C code)
- **Hostname** -- Hostname management
- **InputDevices** (system) -- Privileged input device config (udev rules for touchpad)
- **KeyEvent** (`org.deepin.dde.KeyEvent1`) -- System-level key event monitoring (libinput)
- **Lang** -- System-wide language settings
- **Power** (system) (`org.deepin.dde.Power1`) -- Privileged power management (suspend, lid)
- **ResourceCtl** -- Cgroup resource control
- **Scheduler** -- Process scheduler optimization (Deepin/UOS only, disabled via `noscheduler` tag)
- **SwapSched** (`org.deepin.dde.SwapSchedHelper1`) -- Swap scheduling helper
- **SystemInfo** (system) (`org.deepin.dde.SystemInfo1`) -- System hardware info
- **Timedate** (system) (`org.deepin.dde.Timedate1`) -- Privileged timezone/NTP management
- **UADP** (`org.deepin.dde.Uadp1`) -- Unified Adaptation and Detection Platform (crypto)
- **ImageEffect** (`org.deepin.dde.ImageEffect1`) -- Image blur effects

##### Helper binaries
- `grub2` -- GRUB bootloader configuration management
- `backlight_helper` -- Display backlight control (DDC/CI via ddcutil)
- `langselector` -- Language selection daemon
- `soundeffect` -- Sound effect player daemon
- `dde-lockservice` -- Screen lock service
- `default-terminal` -- Default terminal emulator launcher
- `dde-greeter-setter` -- Greeter/login screen configuration
- `default-file-manager` -- Default file manager launcher
- `greeter-display-daemon` -- Display config for login greeter
- `fix-xauthority-perm` -- X11 auth file permission fixer
- `search` -- Desktop search daemon
- `user-config` -- First-login user configuration (desktop setup, wallpapers)
- `desktop-toggle` -- Pure C binary to toggle show-desktop (X11 _NET_SHOWING_DESKTOP)

#### D-Bus Services (29 total)

Session-activated (14 `.service` files in `misc/services/`):
```
org.deepin.dde.Audio1              -> dde-session-daemon
org.deepin.dde.Bluetooth1          -> dde-session-daemon
org.deepin.dde.InputDevices1       -> dde-session-daemon
org.deepin.dde.Keybinding1         -> dde-session-daemon
org.deepin.dde.LangSelector1      -> langselector
org.deepin.dde.LastoreSessionHelper1 -> dde-session-daemon
org.deepin.dde.Power1             -> dde-session-daemon
org.deepin.dde.Search1            -> search
org.deepin.dde.SessionWatcher1    -> dde-session-daemon
org.deepin.dde.SoundEffect1       -> dde-session-daemon
org.deepin.dde.SystemInfo1        -> dde-session-daemon
org.deepin.dde.Timedate1          -> dde-session-daemon
org.deepin.dde.XEventMonitor1     -> dde-session-daemon
org.deepin.dde.Zone1              -> dde-session-daemon
```

System-activated (15 `.service` files in `misc/system-services/`):
```
org.deepin.dde.Accounts1          -> dde-system-daemon (via systemd)
org.deepin.dde.AirplaneMode1      -> dde-system-daemon (via systemd)
org.deepin.dde.BacklightHelper1   -> dde-system-daemon (via systemd)
org.deepin.dde.Bluetooth1         -> dde-system-daemon (via systemd)
org.deepin.dde.Daemon1            -> dde-system-daemon (via systemd)
org.deepin.dde.Display1           -> dde-system-daemon (via systemd)
org.deepin.dde.Gesture1           -> dde-system-daemon (via systemd)
org.deepin.dde.Greeter1           -> dde-system-daemon (via systemd)
org.deepin.dde.Grub2              -> dde-system-daemon (via systemd)
org.deepin.dde.ImageEffect1       -> dde-system-daemon (via systemd)
org.deepin.dde.LockService1       -> dde-system-daemon (via systemd)
org.deepin.dde.Power1             -> dde-system-daemon (via systemd)
org.deepin.dde.SwapSchedHelper1   -> dde-system-daemon (via systemd)
org.deepin.dde.Timedate1          -> dde-system-daemon (via systemd)
org.deepin.dde.Uadp1              -> dde-system-daemon (via systemd)
```

#### systemd Services (7 total)

System services (5):
```
dde-system-daemon.service         -> /usr/lib/deepin-daemon/dde-system-daemon (root, graphical.target)
dde-backlight-helper.service      -> backlight helper
dde-greeter-setter.service        -> greeter display config
dde-lock-service.service          -> lock screen service
deepin-grub2.service              -> GRUB management
```

User services (2):
```
org.dde.session.Daemon1.service   -> /usr/lib/deepin-daemon/dde-session-daemon (D-Bus activated)
org.deepin.dde.SoundEffect1.service -> sound effect player
```

#### CGo Breakdown by Module (8 files with pkg-config)

| File | pkg-config deps | C libraries | Purpose |
|------|----------------|-------------|---------|
| `bin/dde-session-daemon/main.go` | x11 | libX11 (XInitThreads) | X11 thread safety init |
| `inputdevices1/wrapper.go` | x11, xi | libX11, libXi + pthread | X11 input event listening |
| `audio1/alsa.go` | alsa | libasound | ALSA mixer control |
| `bin/backlight_helper/ddcci/ddcci.go` | ddcutil | libddcutil + dl | DDC/CI monitor brightness |
| `system/inputdevices1/libinput.go` | libinput, libudev | libinput, libudev | Input device config |
| `system/inputdevices1/udev_monitor.go` | libudev | libudev | Device hotplug monitoring |
| `system/keyevent1/libinput_bridge.go` | libinput, glib-2.0 | libinput, glib, udev, m | Key event monitoring |
| `system/gesture1/gesture.go` | libinput, glib-2.0 | libinput, glib, udev, m | Gesture recognition |

Additional implicit CGo (no pkg-config, just LDFLAGS):
- `accounts1/user_ifc.go` -- `-lcrypt` (password hashing via crypt.h)
- `accounts1/users/passwd.go` -- `-lcrypt` (shadow password)
- `accounts1/reminder_info.go` -- libc (utmpx, shadow, arpa/inet)
- `system/uadp1/crypto.go` -- `-ldl` (dynamic loading for crypto)
- `session/eventlog/module.go` -- `-ldl` (event SDK dynamic loading)
- `system/scheduler/proc_connector.go` -- libc (linux connector/cn_proc)
- `system/power1/lid_switch_common.go` -- libc (linux/input.h)
- `lastore1/tools.go` -- libc (sys/statvfs.h)
- `timedate1/zoneinfo/wrapper.go` -- libc (custom C timezone code)

#### Arch Linux In-Repo PKGBUILD Analysis

The repo includes its own Arch PKGBUILD at `archlinux/PKGBUILD` (for a `-git` build).

Key dependencies listed:
```
depends=(
  deepin-desktop-schemas-git ddcutil deepin-api-git gvfs iso-codes lsb-release
  mobile-broadband-provider-info deepin-polkit-agent-git
  deepin-polkit-agent-ext-gnomekeyring-git udisks2 upower
  libxkbfile accountsservice deepin-desktop-base-git bamf pulseaudio
  org.freedesktop.secrets noto-fonts imwheel ddcutil
)
makedepends=(
  golang-github-linuxdeepin-go-dbus-factory-git golang-deepin-gir-git golang-deepin-lib-git
  deepin-api-git golang-github-nfnt-resize sqlite deepin-gettext-tools-git
  git mercurial python-gobject networkmanager bluez go ddcutil
)
```

Two patches applied:
1. **`dde-daemon.patch`** -- Disables TAP gesture events in libinput C code (commented out
   `LIBINPUT_EVENT_GESTURE_TAP_*` cases which are likely from a newer libinput API not in Arch)
2. **`remove-tc.patch`** -- Removes UADP (Unified Adaptation/Detection Platform) module entirely
   by removing `_ "github.com/linuxdeepin/dde-daemon/system/uadp"` import and the `uadpagent`
   session module. UADP is a Deepin-OS-specific trusted computing module.

**Package phase:** Moves systemd units from `/lib/systemd` to `/usr/lib/systemd` (Arch convention).

**Sysusers config:** Creates a `deepin-daemon` system user (member of `netdev` group).

#### Polkit Policies (15 policy files)

Covers privileged operations for: accounts, airplane mode, backlight, bluetooth, display,
gesture, greeter, GRUB, image effects, lock service, power, swap scheduler, timedate, UADP,
and a general system daemon policy.

Two polkit rules files: `org.deepin.dde.grub2.rules` and `org.deepin.dde.accounts.rules`.

#### Config Files Installed to /etc

```
/etc/pam.d/deepin-auth-keyboard     -- PAM config for keyboard auth
/etc/deepin/grub2_edit_auth.conf     -- GRUB edit auth config
/etc/default/grub.d/10_deepin.cfg    -- GRUB default settings
/etc/pulse/daemon.conf.d/10-deepin.conf -- PulseAudio config
/etc/systemd/logind.conf             -- logind overrides
```

#### GSettings Schemas (1 file)
- `com.deepin.dde.display.gschema.xml`

#### Shell Scripts Shipped
- `misc/scripts/dde-lock.sh` -- Lock screen via D-Bus + xdotool + setxkbmap
- `misc/scripts/dde-shutdown.sh` -- Shutdown dialog via D-Bus + xdotool + setxkbmap
- `misc/libexec/dde-daemon/keybinding/shortcut-dde-grand-search.sh` -- Grand search shortcut
- `misc/libexec/dde-daemon/keybinding/shortcut-dde-script.sh` -- Script shortcut
- `misc/libexec/dde-daemon/keybinding/shortcut-dde-switch-monitors.sh` -- Monitor switch

#### Runtime External Commands Executed

The daemon calls many external tools at runtime:
- **Display:** `redshift`, `xrandr`, `lspci`, `glxinfo`, `dde_wldpms`
- **Accounts:** `groupadd`, `groupdel`, `groupmod`, `usermod`, `chown`, `runuser`, `setfacl`, `realm`, `xauth`
- **Input:** `xdotool`, `setxkbmap`, `syndaemon`, `pgrep`, `killall`, `imwheel`, `pkill`
- **System:** `systemctl`, `systemd-notify`, `systemd-detect-virt`, `rfkill`, `amixer`, `getconf`
- **GRUB:** `adjust-grub-theme` (from dde-api)
- **Images:** `image-blur-helper` (from dde-api)
- **Shell:** `/bin/sh`, `/bin/bash`, `dbus-send`, `xprop`
- **Backlight:** `dpkg-architecture` (Debian-specific, can be skipped/patched)
- **Power:** `dde-lowpower` (from separate package)
- **Touchscreen:** `dde-touchscreen-dialog`
- **Bluetooth:** `dde-bluetooth-dialog`
- **Lock/Shutdown:** `dde-lock.sh`, `dde-shutdown.sh`
- **Keybinding scripts:** Various scripts in libexec

#### NixOS Packaging Complexity Assessment

**Scale: LARGE** -- This is equivalent to a medium-sized system service like accountsservice
or network-manager in terms of packaging complexity.

**Difficulty: HIGH** -- Due to:
1. Extensive CGo with 8 different pkg-config dependencies
2. ~80+ hardcoded FHS paths across 60+ files
3. 15 separate binaries including a pure C binary
4. 29 D-Bus service definitions to register
5. 7 systemd service files needing path fixups
6. PAM, polkit, GSettings, DConfig integration
7. Heavy runtime dependency on external tools
8. Two Makefile targets requiring `deepin-gettext-tools`

**Feasibility: PROVEN** -- The old nixpkgs had a working package for version 6.0.43 using
`buildGoModule`. The existing NixOS derivation (from nixpkgs 24.11) at
`pkgs/desktops/deepin/go-package/dde-daemon/default.nix` provides a complete working template.

The main work for version 6.1.75 will be:
1. Updating the 3 patch files for the new codebase
2. Recomputing `vendorHash`
3. Adding any new `substituteInPlace` calls for newly added hardcoded paths
4. Testing the `noscheduler` build tag (skips Deepin/UOS-specific scheduler)
5. Potentially applying the Arch `remove-tc.patch` to remove UADP module

---

### 12.9 Key Packaging Challenges

1. **vendorHash computation** - Must do `nix-build` with fake hash to get real hash for each
2. **deepin-gettext-tools** - Must be packaged first (was removed from nixpkgs)
3. **Hardcoded path patching in dde-daemon** - ~80+ occurrences, need new versions of the 3 old patches
4. **desktop-toggle C binary in dde-daemon** - Pure C binary compiled via gcc in Makefile, needs X11 pkg-config. buildGoModule might need `preBuild` to handle this
5. **Debian-specific code in dde-api** - `dpkg-query` and `apt-cache` references in `language_support/lang_support.go` need to be patched out or replaced
6. **Runtime binary discovery** - Many paths like `/usr/lib/deepin-daemon/*` need to point to `/run/current-system/sw/lib/deepin-daemon` (NixOS profile path) since components find each other at runtime
7. **PATH override removal** - Two places set hardcoded PATH; must be patched out (dde-daemon already had a patch for this)
8. **`/etc` paths** - Many references to `/etc/default/locale`, `/etc/passwd`, etc. Some are Linux standard paths that work on NixOS, others (like `/etc/default/locale`) need patching or symlinking
9. **UADP module** - Deepin-specific trusted computing platform. Arch removes it entirely. We should too (`remove-tc.patch` from Arch, or equivalent for v6.1.75)
10. **Scheduler module** - Already disabled by default via `BUILD_TAGS ?= noscheduler` in the Makefile. Only for Deepin/UOS. Keep the default.
11. **D-Bus service path fixups** - All 29 `.service` files reference `/usr/lib/deepin-daemon/` in their Exec lines. The global sed in the old nixpkgs handled this.
12. **systemd service path fixups** - 7 systemd units reference `/usr/lib/deepin-daemon/` in ExecStart. The NixOS module used `systemd.packages` which handles this via the `systemd` property of the package.
13. **System user creation** - Arch creates a `deepin-daemon` system user. The NixOS module should do this via `users.users` and `users.groups`.
14. **Gesture TAP events** - Arch patches out TAP gesture event handling in the libinput C code (may be a newer libinput API issue). We may need this too depending on our libinput version.

---

## 13. dde-session-shell Research

**Repository:** https://github.com/linuxdeepin/dde-session-shell
**Latest Commit:** `3bd2a1f` (fix: fix lock screen window positioning on multi-monitor X11 setups)
**No Tagged Releases** - Development tracked via commit history only (1,956 commits on master)

### 13.1 What It Provides

`dde-session-shell` provides **two main applications**:

1. **`dde-lock`** - Lock screen functionality (protects privacy while system is running)
2. **`lightdm-deepin-greeter`** - Login greeter for LightDM display manager

The package "Provides: lightdm-greeter" in debian packaging, making it a full LightDM greeter implementation.

### 13.2 Build System Architecture

The build uses CMake with **dual-mode support** for Qt5 (v20) and Qt6 (snipe):

```cmake
# Auto-detection logic (lines 31-45 in CMakeLists.txt)
if (NOT DDE_SESSION_SHELL_SNIPE)
    find_package(Qt6 COMPONENTS Core QUIET)
endif ()

if (DDE_SESSION_SHELL_SNIPE OR Qt6_FOUND)
    set(QT_VERSION_MAJOR 6)
    set(DTK_VERSION_MAJOR 6)
else ()
    set(QT_VERSION_MAJOR 5)  # v20 mode
    set(DTK_VERSION_MAJOR "")
endif ()
```

For DDE 25 / NixOS packaging: **Use Qt6 mode** by ensuring Qt6 is findable or setting `DDE_SESSION_SHELL_SNIPE`.

### 13.3 The liblightdm-qt6-3 Blocker

**Critical Finding:** Both `dde-lock` AND `lightdm-deepin-greeter` link against `${Greeter_LIBRARIES}`:

```cmake
# Line 62 (v20 mode)
pkg_check_modules(Greeter REQUIRED liblightdm-qt5-3)

# Line 66 (snipe/Qt6 mode)
pkg_check_modules(Greeter REQUIRED liblightdm-qt6-3)

# Line 298 (dde-lock links it)
target_link_libraries(dde-lock PRIVATE
    ${Greeter_LIBRARIES}
    ...
)

# Line 375 (lightdm-deepin-greeter links it)
target_link_libraries(lightdm-deepin-greeter PRIVATE
    ${Greeter_LIBRARIES}
    ...
)
```

**However**, after analyzing the source code:

#### dde-lock Does NOT Use LightDM APIs

- **No `#include <QLightDM/*>` headers** in any dde-lock or session-widgets source files
- **No `QLightDM::Greeter` objects** instantiated in dde-lock code
- **Only place LightDM is referenced**: `AuthObjectType::LightDM` enum in `auth_custom.h` (just a metadata flag for plugin communication, not actual LightDM API usage)

The `${Greeter_LIBRARIES}` link is **spurious** for dde-lock. It's linked because both executables share `${SESSION_WIDGETS}` sources in their build, but dde-lock never calls LightDM functions.

#### lightdm-deepin-greeter DOES Use LightDM APIs

Files using QLightDM:
- `src/lightdm-deepin-greeter/greeterworker.h` - `#include <QLightDM/Greeter>` and `#include <QLightDM/SessionsModel>`
- `src/lightdm-deepin-greeter/greeterworker.cpp` - Instantiates `QLightDM::Greeter` object
- `src/lightdm-deepin-greeter/sessionwidget.cpp` - Uses LightDM session model
- `src/lightdm-deepin-greeter/sessionwidget.h` - Header for session widget

### 13.4 LightDM Qt6 Support Status

**Canonical LightDM upstream:**
- **Only supports Qt5** (`liblightdm-qt5-3`)
- No Qt6 support in official releases (latest: v1.32.0, July 2022)
- Repository: https://github.com/canonical/lightdm
- `configure.ac` only has `--enable-liblightdm-qt5` flag

**NixOS nixpkgs lightdm package:**
- Located at: `pkgs/by-name/li/lightdm/package.nix`
- Supports Qt5 via `withQt5` option: `lightdm.override { withQt5 = true; }`
- Builds `liblightdm-qt5-3` when enabled
- **No Qt6 support available**

### 13.5 Workaround Strategies

#### Option 1: Build dde-lock Separately (RECOMMENDED)

Since dde-lock doesn't actually use LightDM APIs, we can:

1. **Patch CMakeLists.txt** to make `Greeter_LIBRARIES` optional or remove it from dde-lock link line
2. **Build only dde-lock** for the initial NixOS port
3. **Skip lightdm-deepin-greeter** until upstream or community provides `liblightdm-qt6-3`

**Patch approach:**
```cmake
# Remove line 298 from dde-lock target_link_libraries:
-    ${Greeter_LIBRARIES}

# Or make it conditional:
if (TARGET lightdm-deepin-greeter)
    pkg_check_modules(Greeter REQUIRED liblightdm-qt6-3)
endif()
```

**Benefits:**
- Lock screen works without LightDM dependency
- Can use with any display manager (GDM, SDDM, etc.)
- Most users need lock screen, not custom greeter

#### Option 2: Use dde-session-shell-snipe Repository

The research document mentions "dde-session-shell has a dedicated deepin 25 repo: dde-session-shell-snipe (Qt6-only)".

**TODO:** Investigate if this separate repo has different LightDM handling or if it's just the snipe branch.

#### Option 3: Port liblightdm-qt to Qt6

**Effort:** MEDIUM-HIGH
**Scope:** Fork Canonical's `liblightdm-qt` and port Qt5 → Qt6
**Risk:** Maintenance burden, ABI compatibility issues

This would be a **separate project** and likely not worth it for initial DDE revival.

#### Option 4: Wait for Upstream

Deepin developers must have solved this for DDE 25. Possible scenarios:
1. They maintain internal `liblightdm-qt6` fork
2. They switched to different display manager integration
3. The snipe branch has conditional compilation

**Action:** Check Deepin's build system for how they handle this.

### 13.6 Dependency Analysis

#### Build Dependencies (Qt6 Mode)

From `debian/control` and `CMakeLists.txt`:

**Required:**
- Qt6 (Core, Widgets, DBus, Svg, Network, LinguistTools)
- Dtk6 (Widget, Core, Tools)
- PAM
- xcb-ewmh, x11, xi, xcursor, xfixes, xrandr, xext, xtst
- OpenSSL (libcrypto, libssl)
- **liblightdm-qt6-3** (BLOCKER - not in nixpkgs)

**Not required for Qt6 mode:**
- KF5Wayland (only in v20/Qt5 mode)
- Qt5X11Extras (only in v20 mode)
- dframeworkdbus (only in v20 mode)
- gsettings-qt (only in v20 mode)

#### Runtime Dependencies

From `debian/control`:
- deepin-desktop-schemas (≥5.9.14)
- dde-daemon (≥5.13.12)
- startdde (≥5.10.24)
- deepin-authenticate (≥1.2.27)
- dde-dconfig-daemon
- dde-wayland-config (≥1.0.10-1)
- x11-xserver-utils
- xsettingsd
- dbus-x11
- libssl1.1

**Critical:** "lightdm-deepin-greeter strongly relies on the com.deepin.daemon.Accounts service" from dde-daemon.

#### Shared Widget Code

Both executables share 18,000+ lines of common code:
- `${GLOBAL_UTILS}` - Global utility functions
- `${GLOBAL_UTILS_DBUS}` - D-Bus interface code
- `${WIDGETS}` - General widget components
- `${SESSION_WIDGETS}` - Session-level widgets
- `${AUTHENTICATE}` - Authentication library (libdde-auth)
- `${INTERFACE}` - Interface definitions
- `${PLUGIN_MANAGER}` - Plugin management system

This shared code does NOT use LightDM APIs.

### 13.7 Components Built

The package builds **3 executables** (v20 mode) or **2 executables** (snipe/Qt6 mode):

1. **`dde-lock`** - Lock screen (BOTH modes)
2. **`lightdm-deepin-greeter`** - LightDM greeter (BOTH modes)
3. **`greeter-display-setting`** - Display settings for greeter (v20 ONLY)

Additional components:
- **`lighter-greeter`** subdirectory (v20 only) - Lightweight greeter variant
- **`pam-inhibit-autologin`** - PAM module to block autologin
- **Plugins** - Extensibility system

### 13.8 Lock Screen vs Greeter Separation

**Lock Screen (dde-lock):**
- Runs in **user session** after login
- Displays when user locks screen (Ctrl+Alt+L, idle timeout, etc.)
- Uses D-Bus services: `com.deepin.dde.lockFront`, `com.deepin.dde.shutdownFront`
- Integrates with deepin-authenticate for biometric/password auth

**Greeter (lightdm-deepin-greeter):**
- Runs as **LightDM child process** before login
- Displays at boot/logout for user selection and authentication
- Uses LightDM APIs (`QLightDM::Greeter`) to communicate with LightDM daemon
- Cannot run without LightDM

**Conclusion:** These are separate use cases. Lock screen can exist independently.

### 13.9 Configuration Files Installed

- `/usr/share/dde-session-shell/dde-session-shell.conf` - Main config
- `/usr/share/deepin-authentication/privileges/lightdm-deepin-greeter.conf` - Auth privileges
- `/etc/lightdm/deepin/qt-theme.ini` - Qt theme for greeter
- `/usr/share/lightdm/lightdm.conf.d/50-deepin.conf` - LightDM integration
- `/usr/share/xgreeters/lightdm-deepin-greeter.desktop` - Greeter registration
- `/usr/share/applications/dde-lock.desktop` - Lock screen desktop entry
- `/etc/xdg/autostart/dde-lock.desktop` - Autostart lock screen

Plus D-Bus service files in `/usr/share/dbus-1/services/`.

### 13.10 PAM Configuration

Installs PAM configs (from `files/pam.d/*`):
- Handles authentication for both lock and greeter
- Must be integrated into NixOS PAM system via `security.pam.services`

### 13.11 Packaging Recommendation

**Phase 1 (Initial Port):**
1. Package **dde-lock only**
2. Patch out `${Greeter_LIBRARIES}` dependency
3. Set `DDE_SESSION_SHELL_SNIPE=ON` or ensure Qt6 is detected
4. Build with: `cmake -DDDE_SESSION_SHELL_SNIPE=ON` or just provide Qt6
5. Install only `dde-lock` binary + lock-related configs
6. Skip greeter until liblightdm-qt6 situation resolves

**Phase 2 (Greeter Support):**
1. Investigate dde-session-shell-snipe repo for alternative approach
2. OR: Package liblightdm with Qt6 support (requires upstream fork)
3. OR: Wait for Deepin to upstream their Qt6 solution
4. Build full package with greeter support

### 13.12 NixOS Integration Points

**For dde-lock:**
- Systemd user service (if needed for autostart)
- D-Bus session services registration
- PAM config for `dde-lock` authentication
- Desktop entry in `/etc/xdg/autostart/`
- Integration with deepin-authenticate

**For lightdm-deepin-greeter (future):**
- Add to `services.xserver.displayManager.lightdm.greeters.enable`
- Configure LightDM to use deepin greeter
- PAM config for `lightdm-deepin-greeter`
- Install xgreeters desktop file

### 13.13 Blocker Status Summary

| Component | liblightdm-qt6-3 Needed? | Can Build Without? |
|-----------|--------------------------|-------------------|
| dde-lock | No (spurious link only) | **YES** - Just patch CMakeLists.txt |
| lightdm-deepin-greeter | Yes (actual API usage) | **NO** - Hard requirement |
| session-widgets | No (shared code) | YES |

**Conclusion:** The blocker can be worked around by building dde-lock separately, which is the higher-priority component for desktop usability.
