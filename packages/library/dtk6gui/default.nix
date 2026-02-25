{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  doxygen,
  qt6Packages,
  librsvg,
  dtkcommon,
  dtk6core,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dtk6gui";
  version = "6.0.50";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dtk6gui";
    rev = finalAttrs.version;
    hash = "sha256-reB8bR3Cw/e9AZ9juzM9Sk1SE0vbx/a0jMjrd26Ei9k=";
  };

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
    qt6Packages.qtwayland
    librsvg
  ];

  propagatedBuildInputs = [
    dtkcommon
    dtk6core
  ];

  cmakeFlags = [
    "-DDTK_VERSION=${finalAttrs.version}"
    "-DBUILD_DOCS=ON"
    "-DBUILD_EXAMPLES=OFF"
    "-DBUILD_TESTING=OFF"
    "-DDTK_DISABLE_EX_IMAGE_FORMAT=ON"
    "-DDTK_DISABLE_TREELAND=ON"
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
    for binary in $out/libexec/dtk6/DGui/bin/*; do
      [ -f "$binary" ] && wrapQtApp "$binary"
    done
  '';

  meta = {
    description = "Deepin tool kit GUI library";
    homepage = "https://github.com/linuxdeepin/dtk6gui";
    license = lib.licenses.lgpl3Plus;
    platforms = lib.platforms.linux;
  };
})
