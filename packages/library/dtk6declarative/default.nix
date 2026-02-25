{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  doxygen,
  qt6Packages,
  libGL,
  vulkan-headers,
  dtkcommon,
  dtk6core,
  dtk6gui,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dtk6declarative";
  version = "6.0.50";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dtk6declarative";
    rev = finalAttrs.version;
    hash = "sha256-K/cbbEJUqug1fpNCMGxS5AzbEJVcVv/A/B/dgjaWfpg=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    doxygen
    qt6Packages.qttools
    qt6Packages.qtshadertools
    qt6Packages.wrapQtAppsHook
  ];

  dontWrapQtApps = true;

  buildInputs = [
    qt6Packages.qtbase
    qt6Packages.qtdeclarative
    qt6Packages.qt5compat
    qt6Packages.qtshadertools
    libGL
    vulkan-headers
  ];

  propagatedBuildInputs = [
    dtkcommon
    dtk6core
    dtk6gui
  ];

  cmakeFlags = [
    "-DDTK_VERSION=${finalAttrs.version}"
    "-DBUILD_DOCS=ON"
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

  meta = {
    description = "Deepin tool kit declarative/QML library";
    homepage = "https://github.com/linuxdeepin/dtk6declarative";
    license = lib.licenses.lgpl3Plus;
    platforms = lib.platforms.linux;
  };
})
