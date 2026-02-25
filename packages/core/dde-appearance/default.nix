{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6Packages,
  kdePackages,
  dtk6core,
  dtk6gui,
  gsettings-qt6,
  deepin-service-manager,
  glib,
  gtk3,
  libxcursor,
  libxfixes,
  libx11,
  libxcb,
  xcb-util-cursor,
  fontconfig,
  openssl,
  systemd,
  tzdata,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dde-appearance";
  version = "1.1.78";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-appearance";
    rev = finalAttrs.version;
    hash = "sha256-Ytd/OENzW+I6wx14QVrL1JMvKJxJKV4F/Bn7/yUuLCY=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.qttools
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = [
    qt6Packages.qtbase
    kdePackages.kwindowsystem
    kdePackages.kconfig
    kdePackages.kglobalaccel
    dtk6core
    dtk6gui
    gsettings-qt6
    deepin-service-manager
    glib
    gtk3
    libxcursor
    libxfixes
    libx11
    libxcb
    xcb-util-cursor
    fontconfig
    openssl
    systemd
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_SYSCONFDIR=${placeholder "out"}/etc"
  ];

  postPatch = ''
    # Fix hardcoded /etc paths in CMakeLists
    find . -name "CMakeLists.txt" -exec \
      sed -i "s|/etc/|$out/etc/|g" {} +

    # Fix systemd user unit install path
    find . -name "CMakeLists.txt" -exec \
      sed -i "s|\''${SYSTEMD_USER_UNIT_DIR}|$out/lib/systemd/user|g" {} +

    # Fix timezone data path
    substituteInPlace src/service/modules/common/commondefine.h \
      --replace-fail '"/usr/share/zoneinfo/zone1970.tab"' '"${tzdata}/share/zoneinfo/zone1970.tab"'

    # Fix hardcoded /usr/share paths to use $out
    substituteInPlace src/service/modules/api/compatibleengine.cpp \
      --replace-fail '"/usr/share/dsg/icons/"' '"'"$out"'/share/dsg/icons/"'
    substituteInPlace src/service/modules/subthemes/customtheme.cpp \
      --replace-fail '"/usr/share/dde-appearance/' '"'"$out"'/share/dde-appearance/' || true
  '';

  SYSTEMD_USER_UNIT_DIR = "${placeholder "out"}/lib/systemd/user";

  meta = {
    description = "Appearance management service for DDE";
    homepage = "https://github.com/linuxdeepin/dde-appearance";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
