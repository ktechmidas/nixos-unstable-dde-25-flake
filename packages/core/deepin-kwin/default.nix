{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  extra-cmake-modules,
  qt6Packages,
  kdePackages,
  gsettings-qt6,
  deepin-wayland-protocols,
  qt6platform-plugins,
  wayland,
  wayland-protocols,
  libepoxy,
  pipewire,
  lcms2,
  libcap,
  libinput,
  libxkbcommon,
  libxcb,
  xcb-util-cursor,
  xcbutilkeysyms,
  xcbutilwm,
  libx11,
  libxi,
  libxtst,
  libxscrnsaver,
  xwayland,
  libdrm,
  mesa,
  freetype,
  systemd,
  python3,
  perl,
  libxcvt,
  sysprof,
  bash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "deepin-kwin";
  version = "6.0.8";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "deepin-kwin";
    rev = finalAttrs.version;
    hash = "sha256-aDaMSn3/C8TsBoHsWDKaYvYDnnYT6FH10G7kEcYuD7g=";
  };

  patches = [
    ./qt-6.9.patch
    ./qt-6.10.patch
    ./qt-6.10.2.patch
    ./disable-kglobalaccel.patch
  ];

  postPatch = ''
    # Fix shebangs (e.g. /usr/bin/env python3)
    patchShebangs .

    # Fix default background path
    sed -i 's|/usr/share/backgrounds/default_background.jpg|/usr/share/backgrounds/deepin/desktop.jpg|' \
      src/effects/multitaskview/multitaskview.cpp || true

    # Fix hardcoded /etc paths
    find . -name "CMakeLists.txt" -exec \
      sed -i "s|/etc/|$out/etc/|g" {} +
  '';

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    extra-cmake-modules
    qt6Packages.qttools
    qt6Packages.wrapQtAppsHook
    python3
    perl
  ];

  buildInputs = [
    # Qt6
    qt6Packages.qtbase
    qt6Packages.qtdeclarative
    qt6Packages.qtshadertools
    qt6Packages.qtwayland
    qt6Packages.qt5compat

    # KDE Frameworks 6
    kdePackages.kauth
    kdePackages.kconfig
    kdePackages.kconfigwidgets
    kdePackages.kcoreaddons
    kdePackages.kcrash
    kdePackages.kdbusaddons
    kdePackages.kdeclarative
    kdePackages.kglobalaccel
    kdePackages.ki18n
    kdePackages.kidletime
    kdePackages.kitemviews
    kdePackages.knotifications
    kdePackages.kpackage
    kdePackages.kwidgetsaddons
    kdePackages.kwindowsystem
    kdePackages.kcmutils
    kdePackages.knewstuff
    kdePackages.krunner
    kdePackages.kservice
    kdePackages.ktextwidgets
    kdePackages.kxmlgui
    kdePackages.kwayland
    kdePackages.kglobalacceld

    # KDE Plasma
    kdePackages.kscreenlocker
    kdePackages.libkscreen

    # Deepin
    gsettings-qt6
    deepin-wayland-protocols
    qt6platform-plugins

    # Wayland
    wayland
    wayland-protocols

    # Graphics
    libepoxy
    pipewire
    lcms2
    libdrm
    mesa
    freetype

    # X11
    libxcb
    xcb-util-cursor
    xcbutilkeysyms
    xcbutilwm
    libx11
    libxi
    libxtst
    libxscrnsaver
    libxkbcommon
    xwayland

    # System
    libcap
    libinput
    libxcvt
    sysprof
    systemd
    bash
  ];

  cmakeFlags = [
    "-DBUILD_ON_V25=ON"
    "-DBUILD_TESTING=OFF"
    "-DENABLE_KGLOBALACCEL=OFF"
    "-DCMAKE_INSTALL_LIBEXECDIR=lib"
  ];

  meta = {
    description = "DDE window manager forked from KWin";
    homepage = "https://github.com/linuxdeepin/deepin-kwin";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
})
