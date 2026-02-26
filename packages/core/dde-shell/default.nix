{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  extra-cmake-modules,
  pkg-config,
  qt6Packages,
  wayland,
  wayland-protocols,
  yaml-cpp,
  icu,
  systemd,
  dtkcommon,
  dtk6core,
  dtk6gui,
  dtk6widget,
  dtk6declarative,
  dde-tray-loader,
  dde-application-manager,
  treeland-protocols,
  libxcb,
  xcbutilwm,
  libxtst,
  qt6platform-plugins,
  qt6integration,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dde-shell";
  version = "2.0.29";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-shell";
    rev = finalAttrs.version;
    hash = "sha256-UgDYaBXZ0MSw0ain0U/Tf6YbxrJ+kSNIiXhf0QUbHX4=";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    pkg-config
    qt6Packages.qttools
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = [
    qt6Packages.qtbase
    qt6Packages.qtdeclarative
    qt6Packages.qtsvg
    qt6Packages.qtwayland
    qt6Packages.qt5compat          # Qt5Compat.GraphicalEffects QML (notification panel)
    qt6Packages.qtimageformats     # webp, tiff, etc. image format plugins
    wayland
    wayland-protocols
    yaml-cpp
    icu
    systemd
    dde-tray-loader
    dde-application-manager
    treeland-protocols
    libxcb
    xcbutilwm
    libxtst
    qt6platform-plugins
    qt6integration
  ];

  propagatedBuildInputs = [
    dtkcommon
    dtk6core
    dtk6gui
    dtk6widget
    dtk6declarative
  ];

  cmakeFlags = [
    "-DDS_BUILD_WITH_QT6=ON"
    "-DBUILD_WITH_X11=ON"
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_SYSCONFDIR=${placeholder "out"}/etc"
  ];

  postPatch = ''
    # Fix hardcoded /etc paths
    find . -name "CMakeLists.txt" -exec \
      sed -i "s|/etc/|$out/etc/|g" {} +
    # Redirect systemd user unit install to our output
    find . -name "CMakeLists.txt" -exec \
      sed -i "s|\''${SYSTEMD_USER_UNIT_DIR}|$out/lib/systemd/user|g" {} +
  '';

  # Inject QML paths for DTK modules that install to non-standard lib/qt6/qml.
  # dde-launchpad QML is added via environment.sessionVariables in the module
  # (can't be a buildInput here due to circular dependency).
  qtWrapperArgs = [
    "--prefix" "QML2_IMPORT_PATH" ":" "${dtk6declarative}/lib/qt6/qml"
  ];

  # Ensure systemd user units don't go to systemd's store path
  SYSTEMD_USER_UNIT_DIR = "${placeholder "out"}/lib/systemd/user";

  meta = {
    description = "DDE shell framework (panel, taskbar, applets)";
    homepage = "https://github.com/linuxdeepin/dde-shell";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
