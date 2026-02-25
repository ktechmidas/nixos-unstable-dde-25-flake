{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6Packages,
  kdePackages,
  dtk6core,
  dtk6widget,
  dde-shell,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dde-polkit-agent";
  version = "6.0.18";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-polkit-agent";
    rev = finalAttrs.version;
    hash = "sha256-G08zjak34V0Ps+c560vDfILGNMEppBXTJw13s9fgeqM=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.qttools
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = [
    qt6Packages.qtbase
    kdePackages.polkit-qt-1
    dtk6core
    dtk6widget
    dde-shell
  ];

  cmakeFlags = [
    "-DDTK_VERSION=${finalAttrs.version}"
  ];

  meta = {
    description = "Polkit authentication agent for DDE";
    homepage = "https://github.com/linuxdeepin/dde-polkit-agent";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
