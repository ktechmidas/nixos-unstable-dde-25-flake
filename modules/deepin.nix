# NixOS module for DDE 25 (Deepin Desktop Environment 7.0)
# X11-first approach, Qt6-only
{ self }:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.desktopManager.deepin;
  deepin = import ../packages { inherit pkgs; };

  # Combined GSettings schemas from all DDE packages.
  # GLib's GSETTINGS_SCHEMA_DIR only supports a single directory, so we
  # merge schemas from deepin-desktop-schemas, startdde, and dde-daemon
  # into one compiled database.
  deepinSchemas = pkgs.runCommand "deepin-combined-schemas" {
    nativeBuildInputs = [ pkgs.glib ];
  } ''
    mkdir -p $out/share/glib-2.0/schemas
    for dir in \
      ${deepin.deepin-desktop-schemas}/share/gsettings-schemas/*/glib-2.0/schemas \
      ${deepin.startdde}/share/gsettings-schemas/*/glib-2.0/schemas \
      ${deepin.dde-daemon}/share/gsettings-schemas/*/glib-2.0/schemas; do
      for f in "$dir"/*.xml; do
        [ -f "$f" ] && cp -n "$f" $out/share/glib-2.0/schemas/ 2>/dev/null || true
      done
    done
    glib-compile-schemas $out/share/glib-2.0/schemas
  '';
in
{
  options.services.desktopManager.deepin = {
    enable = lib.mkEnableOption "Deepin Desktop Environment (DDE 25)";
  };

  config = lib.mkIf cfg.enable {

    # X11 session via deepin-kwin
    services.xserver.enable = true;

    # dde-session is the session entry point (replaces startdde in DDE 25).
    # It activates the systemd user target chain: dde-session.target →
    # dde-session-pre.target (kwin) → dde-session-core.target (dde-shell) →
    # dde-session-initialized.target (polkit, lock, etc.)
    services.displayManager.sessionPackages = [ deepin.dde-session ];

    # D-Bus services
    services.dbus.packages = [
      pkgs.dconf                           # ca.desrt.dconf session service
      deepin.dde-shell
      deepin.dde-session
      deepin.dde-session-ui
      deepin.dde-session-shell             # org.deepin.dde.LockFront1, ShutdownFront1
      deepin.dde-application-manager
      deepin.deepin-service-manager
      deepin.dde-app-services
      deepin.dde-polkit-agent
      deepin.dde-appearance
      deepin.dde-daemon
      deepin.dde-api
      deepin.dde-control-center
    ];

    # System user for dde-dconfig-daemon
    users.users.deepin-daemon = {
      isSystemUser = true;
      group = "deepin-daemon";
      home = "/var/lib/dde-dconfig-daemon";
    };
    users.groups.deepin-daemon = {};

    # Critical system-level DDE services
    systemd.services.dde-dconfig-daemon = {
      description = "DDE DConfig Daemon (org.desktopspec.ConfigManager)";
      wants = [ "dbus.socket" ];
      after = [ "dbus.socket" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.desktopspec.ConfigManager";
        User = "deepin-daemon";
        ExecStart = "${deepin.dde-app-services}/bin/dde-dconfig-daemon";
        StateDirectory = "dde-dconfig-daemon";
        StateDirectoryMode = "0700";
        LogsDirectory = "deepin";
        ProtectSystem = "full";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateNetwork = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RemoveIPC = true;
      };
      environment = {
        DSG_DATA_DIRS = "/run/current-system/sw/share/dsg";
      };
    };

    systemd.services.deepin-service-manager = {
      description = "Deepin Service Manager";
      after = [ "dbus.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${deepin.deepin-service-manager}/bin/deepin-service-manager";
        Restart = "on-failure";
        RestartSec = 3;
      };
      environment = {
        GSETTINGS_SCHEMA_DIR = "${deepinSchemas}/share/glib-2.0/schemas";
      };
    };

    systemd.services.dde-system-daemon = {
      description = "DDE System Daemon";
      after = [ "nss-user-lookup.target" "deepin-service-manager.service" ];
      wants = [ "nss-user-lookup.target" ];
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        ExecStart = "${deepin.dde-daemon}/lib/deepin-daemon/dde-system-daemon";
        Restart = "on-failure";
        RestartSec = 3;
        OOMScoreAdjust = "-500";
        Nice = -5;
      };
      environment = {
        GSETTINGS_SCHEMA_DIR = "${deepinSchemas}/share/glib-2.0/schemas";
        GVFS_DISABLE_FUSE = "1";
        GIO_USE_VFS = "local";
        GVFS_REMOTE_VOLUME_MONITOR_IGNORE = "1";
      };
    };

    # User-level systemd services (linked into /run/current-system/sw/share/systemd/user/)
    # Note: deepin-service-manager and dde-daemon are NOT in systemd.packages
    # because they have system-level services with hardcoded paths that we
    # handle manually below. Only packages with user-level services go here.
    systemd.packages = [
      pkgs.kdePackages.kglobalacceld       # plasma-kglobalaccel.service (user)
      pkgs.dconf                           # dconf.service (user)
      deepin.dde-session                   # DDE session targets and user services
      deepin.dde-shell                     # dde-shell@.service (user)
      deepin.dde-session-ui                # dde-lock.service, etc. (user)
      deepin.dde-appearance                # dde-fakewm.service (user)
    ];

    # Environment variables for the session
    environment.sessionVariables = {
      # Make DTK and Qt find our plugins and themes
      QT_PLUGIN_PATH = [
        "${deepin.qt6platform-plugins}/${pkgs.qt6Packages.qtbase.qtPluginPrefix}"
        "${deepin.qt6integration}/${pkgs.qt6Packages.qtbase.qtPluginPrefix}"
      ];
      QT_QPA_PLATFORM_PLUGIN_PATH = [
        "${deepin.qt6platform-plugins}/${pkgs.qt6Packages.qtbase.qtPluginPrefix}/platforms"
      ];
      # QML import paths for DTK and DDE modules
      # Our packages install QML to lib/qt6/qml, not the NixOS standard lib/qt-6/qml
      QML2_IMPORT_PATH = [
        "${deepin.dtk6declarative}/lib/qt6/qml"
        "${deepin.dde-shell}/lib/qt6/qml"
        "${deepin.dde-launchpad}/lib/qt6/qml"
        "${pkgs.qt6Packages.qt5compat}/${pkgs.qt6Packages.qtbase.qtQmlPrefix}"
      ];
      # DDE needs to find its own schemas
      DDE_KWIN_DIR = "${deepin.deepin-kwin}";
    };

    # XDG data dirs for icon themes, wallpapers, schemas, etc.
    environment.pathsToLink = [
      "/share/icons"
      "/share/wallpapers"
      "/share/sounds"
      "/share/dsg"
      "/share/glib-2.0"
      "/share/dde-shell"
      "/share/dde-application-manager"
      "/share/deepin"
      "/share/dbus-1"
      "/share/polkit-1"
      "/share/applications"
      "/share/xsessions"
      "/lib/deepin-daemon"
      "/lib/deepin-api"
      "/lib/dde-shell"
    ];

    # System packages — everything DDE needs at runtime
    environment.systemPackages = [
      # System deps needed by DDE at runtime
      pkgs.dconf                           # ca.desrt.dconf D-Bus service
      pkgs.pciutils                        # lspci (used by startdde display detection)
      pkgs.kdePackages.kglobalacceld       # plasma-kglobalaccel.service (needed by dde-fakewm)
    ] ++ (with deepin; [
      # DTK libraries
      dtkcommon
      dtk6core
      dtk6gui
      dtk6widget
      dtk6declarative

      # Platform integration
      qt6platform-plugins
      qt6integration
      gsettings-qt6

      # Window manager
      deepin-kwin

      # Session starter
      startdde

      # Go services
      dde-api
      dde-daemon

      # Shell and desktop
      dde-shell
      dde-launchpad
      dde-tray-loader
      dde-application-manager
      dde-session
      dde-session-ui
      dde-session-shell                    # dde-lock (lock screen)
      dde-polkit-agent
      dde-appearance
      dde-control-center

      # Core services
      deepin-service-manager
      dde-app-services
      deepin-desktop-schemas
      deepin-desktop-base

      # Artwork
      deepin-icon-theme
      deepin-desktop-theme
      deepin-sound-theme
      deepin-wallpapers
      dde-account-faces
    ]);

    # GSettings schemas — combined from all DDE packages
    environment.variables = {
      GSETTINGS_SCHEMA_DIR = lib.mkDefault "${deepinSchemas}/share/glib-2.0/schemas";
    };

    # PAM for dde-lock (lock screen authentication)
    security.pam.services.dde-lock = {};

    # Polkit (for dde-polkit-agent)
    security.polkit.enable = true;

    # Required system services
    services.upower.enable = lib.mkDefault true;
    services.accounts-daemon.enable = lib.mkDefault true;
    services.udisks2.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;

    # NetworkManager for dde-daemon network management
    networking.networkmanager.enable = lib.mkDefault true;

    # Fonts
    fonts.packages = lib.mkDefault (with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
    ]);

    # XDG portal
    xdg.portal = {
      enable = lib.mkDefault true;
      extraPortals = lib.mkDefault [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
