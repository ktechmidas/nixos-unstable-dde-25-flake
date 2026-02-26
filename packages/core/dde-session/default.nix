{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6Packages,
  dtk6core,
  glib,
  libsecret,
  systemd,
  libx11,
  libxcursor,
  libxfixes,
  libcap_ng,
  deepin-kwin,
  dde-shell,
  dde-polkit-agent,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dde-session";
  version = "2.0.17";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-session";
    rev = finalAttrs.version;
    hash = "sha256-LHAk6A+c1E2+nqQhlxoxkw882iiM0tF5iARfAeLZRD4=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = [
    qt6Packages.qtbase
    dtk6core
    glib
    libsecret
    systemd
    libx11
    libxcursor
    libxfixes
    libcap_ng
  ];

  postPatch = ''
    # Fix hardcoded /etc paths across all cmake files
    find . -name "CMakeLists.txt" -exec \
      sed -i "s|/etc/|$out/etc/|g" {} +
  '';

  cmakeFlags = [
    "-DCMAKE_INSTALL_SYSCONFDIR=${placeholder "out"}/etc"
  ];

  # Fix hardcoded /usr/bin and /usr/lib paths in systemd service files
  # and D-Bus service files to use Nix store paths
  postInstall = ''
    # Fix own binaries
    find $out -name "*.service" -exec sed -i \
      -e "s|/usr/bin/dde-session|$out/bin/dde-session|g" \
      -e "s|/usr/bin/dde-keyring-checker|$out/bin/dde-keyring-checker|g" \
      -e "s|/usr/bin/dde-quick-login|$out/bin/dde-quick-login|g" \
      -e "s|/usr/bin/dde-version-checker|$out/bin/dde-version-checker|g" \
      -e "s|/usr/bin/dde-xsettings-checker|$out/bin/dde-xsettings-checker|g" \
      {} +

    # Fix cross-package references
    find $out -name "*.service" -exec sed -i \
      -e "s|/usr/bin/kwin_x11|${deepin-kwin}/bin/kwin_x11|g" \
      -e "s|/usr/bin/dde-shell|${dde-shell}/bin/dde-shell|g" \
      -e "s|/usr/bin/dde-lock|/run/current-system/sw/bin/dde-lock|g" \
      -e "s|/usr/lib/polkit-1-dde/dde-polkit-agent|${dde-polkit-agent}/lib/polkit-1-dde/dde-polkit-agent|g" \
      {} +

    # Fix D-Bus service files
    find $out -name "*.service" -path "*/dbus-1/*" -exec sed -i \
      -e "s|/usr/bin/|$out/bin/|g" \
      -e "s|/usr/lib/|$out/lib/|g" \
      {} +
  '';

  passthru.providedSessions = [ "deepin" ];

  meta = {
    description = "Session manager for Deepin Desktop Environment";
    homepage = "https://github.com/linuxdeepin/dde-session";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
