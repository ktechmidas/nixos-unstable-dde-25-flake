{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6Packages,
  mtdev,
  libx11,
  lxqt,
  dtkcommon,
  dtk6core,
  dtk6gui,
  dtk6widget,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qt6integration";
  version = "6.0.50";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "qt6integration";
    rev = finalAttrs.version;
    hash = "sha256-h/UGDpEyRpqAbMksLVRpOLLeMDlOJNiznEFvc+NQON8=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.qttools
    qt6Packages.wrapQtAppsHook
  ];

  dontWrapQtApps = true;

  buildInputs = [
    qt6Packages.qtbase
    qt6Packages.qtsvg
    mtdev
    libx11
    lxqt.libqtxdg
  ];

  propagatedBuildInputs = [
    dtkcommon
    dtk6core
    dtk6gui
    dtk6widget
  ];

  cmakeFlags = [
    "-DDTK_VERSION=${finalAttrs.version}"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DENABLE_QT_XDG_ICON_LOADER=ON"
  ];

  # Move plugins to the standard NixOS Qt6 plugin path (lib/qt-6/plugins)
  postInstall = ''
    if [ -d "$out/lib/qt6/plugins" ] && [ ! -d "$out/${qt6Packages.qtbase.qtPluginPrefix}" ]; then
      mkdir -p "$out/$(dirname "${qt6Packages.qtbase.qtPluginPrefix}")"
      mv "$out/lib/qt6/plugins" "$out/${qt6Packages.qtbase.qtPluginPrefix}"
      rmdir "$out/lib/qt6" 2>/dev/null || true
    fi
  '';

  meta = {
    description = "Qt6 platform theme integration plugin for DDE";
    homepage = "https://github.com/linuxdeepin/qt6integration";
    license = lib.licenses.lgpl3Plus;
    platforms = lib.platforms.linux;
  };
})
