# NixOS module for DDE 25 (Deepin Desktop Environment 7.0)
# X11-first approach, Qt6-only
{ self }:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.desktopManager.deepin;
  deepin = import ../packages { inherit pkgs; };
in
{
  options.services.desktopManager.deepin = {
    enable = lib.mkEnableOption "Deepin Desktop Environment (DDE 25)";
  };

  config = lib.mkIf cfg.enable {

    # X11 session via deepin-kwin
    services.xserver.enable = true;

    services.displayManager.sessionPackages = [
      ((pkgs.writeTextDir "share/xsessions/deepin.desktop" ''
        [Desktop Entry]
        Name=Deepin
        Comment=Deepin Desktop Environment
        Exec=${deepin.startdde}/bin/startdde
        Type=Application
        DesktopNames=Deepin
      '').overrideAttrs {
        passthru.providedSessions = [ "deepin" ];
      })
    ];

    # D-Bus services
    services.dbus.packages = [
      deepin.dde-shell
      deepin.dde-session
      deepin.dde-session-ui
      deepin.dde-application-manager
      deepin.deepin-service-manager
      deepin.dde-polkit-agent
      deepin.dde-appearance
      deepin.dde-daemon
      deepin.dde-api
      deepin.dde-control-center
    ];

    # Systemd user/system units
    systemd.packages = [
      deepin.dde-shell
      deepin.dde-session
      deepin.dde-session-ui
      deepin.dde-application-manager
      deepin.deepin-service-manager
      deepin.dde-appearance
      deepin.dde-daemon
      deepin.dde-api
    ];

    # Environment variables for the session
    environment.sessionVariables = {
      # Make DTK and Qt find our plugins and themes
      QT_PLUGIN_PATH = [
        "${deepin.qt6platform-plugins}/lib/qt-6/plugins"
        "${deepin.qt6integration}/lib/qt-6/plugins"
      ];
      QT_QPA_PLATFORM_PLUGIN_PATH = [
        "${deepin.qt6platform-plugins}/lib/qt-6/plugins/platforms"
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
      "/lib/deepin-daemon"
      "/lib/deepin-api"
    ];

    # System packages — everything DDE needs at runtime
    environment.systemPackages = with deepin; [
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
      dde-polkit-agent
      dde-appearance
      dde-control-center

      # Core services
      deepin-service-manager
      deepin-desktop-schemas
      deepin-desktop-base

      # Artwork
      deepin-icon-theme
      deepin-desktop-theme
      deepin-sound-theme
      deepin-wallpapers
      dde-account-faces
    ];

    # GSettings schemas
    environment.variables = {
      GSETTINGS_SCHEMA_DIR = lib.mkDefault "${deepin.deepin-desktop-schemas}/share/glib-2.0/schemas";
    };

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
