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

    # X11 session
    services.xserver.enable = true;

    services.displayManager.sessionPackages = [
      (pkgs.writeTextDir "share/xsessions/deepin.desktop" ''
        [Desktop Entry]
        Name=Deepin
        Comment=Deepin Desktop Environment
        Exec=${deepin.dde-session}/bin/dde-session
        Type=Application
        DesktopNames=Deepin
      '')
    ];

    # D-Bus services
    services.dbus.packages = [
      deepin.dde-shell
      deepin.dde-session
      deepin.dde-application-manager
      deepin.deepin-service-manager
      deepin.dde-polkit-agent
      deepin.dde-appearance
    ];

    # Systemd user units
    systemd.packages = [
      deepin.dde-shell
      deepin.dde-session
      deepin.dde-application-manager
      deepin.deepin-service-manager
      deepin.dde-appearance
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
    ];

    # System packages
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

      # Shell and desktop
      dde-shell
      dde-launchpad
      dde-tray-loader
      dde-application-manager
      dde-session
      dde-polkit-agent
      dde-appearance

      # Core services
      deepin-service-manager
      deepin-desktop-schemas
      deepin-desktop-base

      # Artwork
      deepin-icon-theme
      deepin-sound-theme
      deepin-wallpapers
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
