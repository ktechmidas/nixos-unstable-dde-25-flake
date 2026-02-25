{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  doxygen,
  qt6Packages,
  libstartup_notification,
  libx11,
  libxext,
  libxi,
  libxcb,
  xcbutil,
  dtkcommon,
  dtk6core,
  dtk6gui,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dtk6widget";
  version = "6.0.50";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dtk6widget";
    rev = finalAttrs.version;
    hash = "sha256-ycVxz/rsKFW/sina5MQ78JiReFdC7Y5h232O3YLd0X8=";
  };

  patches = [
    # Qt 6.10 removed QTabBarPrivate::paintWithOffsets
    # Cherry-picked from Arch Linux packaging
    ./qt-6.10.patch
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    doxygen
    qt6Packages.qttools
    qt6Packages.wrapQtAppsHook
  ];

  dontWrapQtApps = true;

  buildInputs = [
    qt6Packages.qtbase
    qt6Packages.qtsvg
    libstartup_notification
    libx11
    libxext
    libxi
    libxcb
    xcbutil
  ];

  propagatedBuildInputs = [
    dtkcommon
    dtk6core
    dtk6gui
  ];

  cmakeFlags = [
    "-DDTK_VERSION=${finalAttrs.version}"
    "-DBUILD_DOCS=ON"
    "-DBUILD_PLUGINS=OFF"
    "-DBUILD_EXAMPLES=OFF"
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DMKSPECS_INSTALL_DIR=${placeholder "out"}/mkspecs/modules"
    "-DQCH_INSTALL_DESTINATION=${placeholder "doc"}/share/doc"
  ];

  preConfigure = ''
    export QT_PLUGIN_PATH=${lib.getBin qt6Packages.qtbase}/${qt6Packages.qtbase.qtPluginPrefix}
  '';

  outputs = [
    "out"
    "doc"
  ];

  postFixup = ''
    for binary in $out/libexec/dtk6/DWidget/bin/*; do
      [ -f "$binary" ] && wrapQtApp "$binary"
    done
  '';

  meta = {
    description = "Deepin tool kit widget library";
    homepage = "https://github.com/linuxdeepin/dtk6widget";
    license = lib.licenses.lgpl3Plus;
    platforms = lib.platforms.linux;
  };
})
