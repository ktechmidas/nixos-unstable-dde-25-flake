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

  meta = {
    description = "D-Bus service manager for Deepin Desktop";
    homepage = "https://github.com/linuxdeepin/deepin-service-manager";
    license = lib.licenses.lgpl3Plus;
    platforms = lib.platforms.linux;
  };
})
