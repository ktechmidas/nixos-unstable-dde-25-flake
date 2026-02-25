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
