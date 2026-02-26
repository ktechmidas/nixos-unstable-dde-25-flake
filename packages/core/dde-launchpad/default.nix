{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6Packages,
  glib,
  systemd,
  appstream,
  kdePackages,
  dtkcommon,
  dtk6core,
  dtk6gui,
  dtk6declarative,
  dde-shell,
  dde-application-manager,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dde-launchpad";
  version = "2.0.26";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-launchpad";
    rev = finalAttrs.version;
    hash = "sha256-8eI2czqvSjQvuzlLIRylcNo0Iots5w2eCeXgIWltqD4=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.qttools
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = [
    qt6Packages.qtbase
    qt6Packages.qtdeclarative
    qt6Packages.qtsvg
    qt6Packages.qtwayland
    qt6Packages.qt5compat
    glib
    systemd
    appstream
    kdePackages.appstream-qt
    dtkcommon
    dtk6core
    dtk6gui
    dtk6declarative
    dde-shell
    dde-application-manager
  ];

  # After cmake configure, fix the generated install scripts to redirect dde-shell paths to $out
  postConfigure = ''
    find . -name "cmake_install.cmake" -exec sed -i \
      -e "s|${dde-shell}/share/dde-shell|$out/share/dde-shell|g" \
      -e "s|${dde-shell}/lib/dde-shell|$out/lib/dde-shell|g" {} +
  '';

  cmakeFlags = [
    "-DBUILD_TEST=OFF"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DSYSTEMD_USER_UNIT_DIR=${placeholder "out"}/lib/systemd/user"
  ];

  meta = {
    description = "Application launcher for Deepin Desktop Environment";
    homepage = "https://github.com/linuxdeepin/dde-launchpad";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
