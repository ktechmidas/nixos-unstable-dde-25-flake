{
  stdenv,
  lib,
  fetchFromGitLab,
  cmake,
  pkg-config,
  qt6Packages,
  glib,
  lomiri,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gsettings-qt6";
  version = "1.1.0";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/gsettings-qt";
    rev = "v${finalAttrs.version}";
    hash = "sha256-NUrJ3xQnef7TwPa7AIZaiI7TAkMe+nhuEQ/qC1H1Ves=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.qtdeclarative
  ];

  buildInputs = [
    qt6Packages.qtbase
    lomiri.cmake-extras
    glib
  ];

  dontWrapQtApps = true;

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'if (WERROR)' 'if (ENABLE_WERROR)'

    substituteInPlace src/gsettings-qt.pc.in \
      --replace-fail "''${prefix}/@CMAKE_INSTALL_LIBDIR@" '@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace-fail "''${prefix}/@QT_INCLUDE_DIR@/QGSettings" '@QT_FULL_INCLUDE_DIR@/QGSettings'

    substituteInPlace GSettings/CMakeLists.txt \
      --replace-fail "''${CMAKE_INSTALL_LIBDIR}/qt''${QT_VERSION_MAJOR}/qml" "$out/${qt6Packages.qtbase.qtQmlPrefix}"
  '';

  preBuild = ''
    export QT_PLUGIN_PATH=${lib.getBin qt6Packages.qtbase}/${qt6Packages.qtbase.qtPluginPrefix}
  '';

  cmakeFlags = [
    "-DENABLE_QT6=ON"
    "-DENABLE_WERROR=ON"
  ];

  postInstall = ''
    mv -v $out/${qt6Packages.qtbase.qtQmlPrefix}/GSettings $out/${qt6Packages.qtbase.qtQmlPrefix}/GSettings.1.0
  '';

  meta = {
    description = "Library to access GSettings from Qt (Qt6 build)";
    homepage = "https://gitlab.com/ubports/core/gsettings-qt";
    license = lib.licenses.lgpl3Only;
    platforms = lib.platforms.linux;
  };
})
