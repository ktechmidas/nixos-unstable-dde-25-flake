{
  stdenv,
  lib,
  fetchFromGitHub,
  runCommand,
  cmake,
  pkg-config,
  qt6Packages,
  mtdev,
  cairo,
  libxkbcommon,
  libx11,
  libxcb,
  libxi,
  libSM,
  libICE,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  xcbutilwm,
  xcbutil,
  libGL,
  dbus,
  expat,
}:

let
  # Extract Qt XCB private headers from qtbase source.
  # qt6platform-plugins subclasses QXcbIntegration and needs these
  # internal headers which aren't installed by qtbase.
  qtXcbPrivateHeaders = runCommand "qt-xcb-private-headers-${qt6Packages.qtbase.version}" {
    src = qt6Packages.qtbase.src;
  } ''
    mkdir -p work
    tar -xf $src -C work
    srcdir=$(echo work/*/src/plugins/platforms/xcb)
    mkdir -p $out
    cp "$srcdir"/*.h $out/ 2>/dev/null || true
    for subdir in gl_integrations gl_integrations/xcb_egl gl_integrations/xcb_glx nativepainting; do
      if [ -d "$srcdir/$subdir" ]; then
        mkdir -p "$out/$subdir"
        cp "$srcdir/$subdir"/*.h "$out/$subdir/" 2>/dev/null || true
      fi
    done
  '';
in

stdenv.mkDerivation (finalAttrs: {
  pname = "qt6platform-plugins";
  version = "6.0.50";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "qt6platform-plugins";
    rev = finalAttrs.version;
    hash = "sha256-3Dgm/cVL22fDQAer9EqvRNJKlRwIT1Z62RPiJ7bhgPI=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.wrapQtAppsHook
  ];

  dontWrapQtApps = true;

  buildInputs = [
    qt6Packages.qtbase
    mtdev
    cairo
    libxkbcommon
    libx11
    libxcb
    libxi
    libSM
    libICE
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcbutilwm
    xcbutil
    libGL
    dbus
    expat
  ];

  cmakeFlags = [
    "-DDTK_VERSION=${finalAttrs.version}"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DQT_XCB_PRIVATE_HEADERS=${qtXcbPrivateHeaders}"
  ];

  # Move plugins to the standard NixOS Qt6 plugin path so wrapQtAppsHook
  # and Qt plugin discovery find them. The upstream installs to lib/qt6/plugins
  # but NixOS uses lib/qt-6/plugins.
  postInstall = ''
    if [ -d "$out/lib/qt6/plugins" ] && [ ! -d "$out/${qt6Packages.qtbase.qtPluginPrefix}" ]; then
      mkdir -p "$out/$(dirname "${qt6Packages.qtbase.qtPluginPrefix}")"
      mv "$out/lib/qt6/plugins" "$out/${qt6Packages.qtbase.qtPluginPrefix}"
      rmdir "$out/lib/qt6" 2>/dev/null || true
    fi
  '';

  meta = {
    description = "Qt6 platform integration plugin for DDE";
    homepage = "https://github.com/linuxdeepin/qt6platform-plugins";
    license = with lib.licenses; [ lgpl3Plus gpl3Plus ];
    platforms = lib.platforms.linux;
  };
})
