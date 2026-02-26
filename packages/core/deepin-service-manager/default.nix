{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6Packages,
  dtk6core,
  systemd,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "deepin-service-manager";
  version = "1.0.21";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "deepin-service-manager";
    rev = finalAttrs.version;
    hash = "sha256-D3igB2sb3Tiqa5gY0ZyOwczMMh6ZMo/gpvLycgZv1LY=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = [
    qt6Packages.qtbase
    dtk6core
    systemd
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_SYSCONFDIR=${placeholder "out"}/etc"
  ];

  # Fix hardcoded /usr/bin paths in systemd service files
  postInstall = ''
    find $out -name "*.service" -exec sed -i \
      -e "s|/usr/bin/deepin-service-manager|$out/bin/deepin-service-manager|g" \
      -e "s|/usr/bin/|$out/bin/|g" \
      -e "s|/usr/lib/|$out/lib/|g" \
      {} +
  '';

  meta = {
    description = "D-Bus service manager for Deepin Desktop";
    homepage = "https://github.com/linuxdeepin/deepin-service-manager";
    license = lib.licenses.lgpl3Plus;
    platforms = lib.platforms.linux;
  };
})
