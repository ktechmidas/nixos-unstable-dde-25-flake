{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  dtk6gui,
  dtk6widget,
  dtk6core,
  dtkcommon,
  qt6Packages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "deepin-desktop-theme";
  version = "1.1.27";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "deepin-desktop-theme";
    rev = finalAttrs.version;
    hash = "sha256-w+iSX3Jh3jIiUtUgTm7UbNncJENBN/T0vVFoG/wanyk=";
  };

  nativeBuildInputs = [
    cmake
    qt6Packages.qtbase
    qt6Packages.qttools
  ];

  buildInputs = [
    dtk6gui
    dtk6widget
    dtk6core
    dtkcommon
  ];

  dontWrapQtApps = true;

  # Upstream has broken symlinks in bloom-classic themes
  dontCheckForBrokenSymlinks = true;

  cmakeFlags = [
    "-DVERSION=${finalAttrs.version}"
  ];

  meta = {
    description = "Desktop themes for Deepin Desktop Environment";
    homepage = "https://github.com/linuxdeepin/deepin-desktop-theme";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
