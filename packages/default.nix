# DDE 25 (DDE 7.0) package scope
# All packages are Qt6-only. No Qt5 needed.
{ pkgs }:

let
  inherit (pkgs) lib;

  packages =
    self:
    let
      inherit (self) callPackage;
    in
    {
      #### DTK6 LIBRARIES (Layer 1-4 — build these first)
      dtkcommon = callPackage ./library/dtkcommon { };
      dtk6log = callPackage ./library/dtk6log { };
      dtk6core = callPackage ./library/dtk6core { };
      dtk6gui = callPackage ./library/dtk6gui { };
      dtk6widget = callPackage ./library/dtk6widget { };
      dtk6declarative = callPackage ./library/dtk6declarative { };
      # dtk6systemsettings = callPackage ./library/dtk6systemsettings { };

      #### PLATFORM INTEGRATION (Layer 5)
      qt6platform-plugins = callPackage ./library/qt6platform-plugins { };
      qt6integration = callPackage ./library/qt6integration { };

      #### SUPPORT LIBRARIES
      gsettings-qt6 = callPackage ./library/gsettings-qt6 { };
      deepin-pw-check = callPackage ./library/deepin-pw-check { };

      #### FILE MANAGER DEPENDENCIES
      docparser = callPackage ./library/docparser { };
      deepin-pdfium = callPackage ./library/deepin-pdfium { };
      util-dfm = callPackage ./library/util-dfm { };

      #### PROTOCOL DEFINITIONS (Layer 1)
      deepin-wayland-protocols = callPackage ./library/deepin-wayland-protocols { };
      treeland-protocols = callPackage ./library/treeland-protocols { };

      #### COMPOSITOR (Layer 6 — X11 path)
      deepin-kwin = callPackage ./core/deepin-kwin { };

      #### SCHEMAS & DATA
      deepin-desktop-schemas = callPackage ./misc/deepin-desktop-schemas { };

      #### TOOLS
      deepin-gettext-tools = callPackage ./tools/deepin-gettext-tools { };

      #### GO SERVICES (Layer 8)
      dde-api = callPackage ./go-package/dde-api { };
      dde-daemon = callPackage ./go-package/dde-daemon { };
      startdde = callPackage ./go-package/startdde { };

      #### CORE SERVICES (Layer 9)
      deepin-service-manager = callPackage ./core/deepin-service-manager { };
      dde-app-services = callPackage ./core/dde-app-services { };
      dde-polkit-agent = callPackage ./core/dde-polkit-agent { };
      dde-application-manager = callPackage ./core/dde-application-manager { };
      dde-appearance = callPackage ./core/dde-appearance { };

      #### SHELL (Layer 10)
      dde-tray-loader = callPackage ./core/dde-tray-loader { };
      dde-shell = callPackage ./core/dde-shell { };

      #### DESKTOP APPS (Layer 11)
      dde-launchpad = callPackage ./core/dde-launchpad { };
      dde-control-center = callPackage ./core/dde-control-center { };
      dde-file-manager = callPackage ./apps/dde-file-manager { };
      # dde-session-shell: only dde-lock is built (greeter needs liblightdm-qt6-3 which is not in nixpkgs)

      #### SESSION (Layer 12)
      dde-session = callPackage ./core/dde-session { };
      dde-session-ui = callPackage ./core/dde-session-ui { };
      dde-session-shell = callPackage ./core/dde-session-shell { };

      #### ARTWORK
      deepin-icon-theme = callPackage ./artwork/deepin-icon-theme { };
      deepin-desktop-theme = callPackage ./artwork/deepin-desktop-theme { };
      deepin-sound-theme = callPackage ./artwork/deepin-sound-theme { };
      deepin-wallpapers = callPackage ./artwork/deepin-wallpapers { };
      dde-account-faces = callPackage ./artwork/dde-account-faces { };

      #### MISC
      deepin-desktop-base = callPackage ./misc/deepin-desktop-base { };
    };
in
lib.makeScope pkgs.newScope packages
