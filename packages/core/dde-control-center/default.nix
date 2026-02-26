{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  qt6Packages,
  dtk6core,
  dtk6gui,
  dtkcommon,
  dde-shell,
  deepin-pw-check,
  treeland-protocols,
  deepin-gettext-tools,
  glib,
  gtest,
  systemd,
  kdePackages,
  libxcrypt,
  icu,
  openssl,
  dpkg,
  wayland,
  wlr-protocols,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dde-control-center";
  version = "6.1.72";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-control-center";
    rev = finalAttrs.version;
    hash = "sha256-ybzJp/1SR+yzMY4fh2scXGEvmAT2DBNXFVURRIQ4c2s=";
  };

  postPatch = ''
    # Fix hardcoded paths
    find . -name "*.cpp" -o -name "*.h" -o -name "*.qml" | xargs sed -i \
      -e 's|/usr/share|/run/current-system/sw/share|g' \
      -e 's|/usr/lib|/run/current-system/sw/lib|g' \
      -e 's|/usr/bin|/run/current-system/sw/bin|g' || true

    find . -name "*.service" -o -name "*.desktop" | xargs sed -i \
      -e "s|/usr/bin|$out/bin|g" \
      -e "s|/usr/lib|$out/lib|g" || true

    # Fix CMake install paths
    find . -name "CMakeLists.txt" -exec sed -i \
      -e "s|/etc/|$out/etc/|g" \
      -e 's|''${systemd_USER_UNIT_DIR}|'"$out/lib/systemd/user"'|g' \
      -e 's|''${SYSTEMD_USER_UNIT_DIR}|'"$out/lib/systemd/user"'|g' {} +
  '';

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6Packages.qttools
    qt6Packages.wrapQtAppsHook
    deepin-gettext-tools
  ];

  buildInputs = [
    # Qt6
    qt6Packages.qtbase
    qt6Packages.qtdeclarative
    qt6Packages.qtmultimedia
    qt6Packages.qtwayland
    qt6Packages.qtsvg

    # DTK6
    dtk6core
    dtk6gui
    dtkcommon

    # DDE
    dde-shell
    deepin-pw-check
    treeland-protocols

    # KDE
    kdePackages.polkit-qt-1

    # System
    glib
    gtest
    systemd
    libxcrypt
    icu
    openssl
    dpkg
    wayland
    wlr-protocols
  ];

  cmakeFlags = [
    "-DBUILD_TESTING=OFF"
    "-DBUILD_DOCS=OFF"
    "-DDTK_VERSION_MAJOR=6"
    "-DQT_VERSION_MAJOR=6"
    "-DDISABLE_AUTHENTICATION=ON"
  ];

  meta = {
    description = "Control center for Deepin Desktop Environment";
    homepage = "https://github.com/linuxdeepin/dde-control-center";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
