{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6Packages,
  dtk6core,
  dtk6widget,
  dtkcommon,
  deepin-gettext-tools,
  linux-pam,
  openssl,
  libxcb,
  xcbutilwm,
  libx11,
  libxi,
  libxcursor,
  libxfixes,
  libxrandr,
  libxext,
  libxtst,
  systemd,
  gtest,
  glib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dde-session-shell";
  version = "6.0.52";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-session-shell-snipe";
    rev = finalAttrs.version;
    hash = "sha256-3xRkOEfvSoJOPjQwKIctlaQA7m+SnyfteRs7kShD4l8=";
  };

  postPatch = ''
    # Fix hardcoded qdbusxml2cpp path
    substituteInPlace CMakeLists.txt \
      --replace-fail '/usr/lib/qt''${QT_VERSION_MAJOR}/bin/qdbusxml2cpp' \
                     '${qt6Packages.qtbase}/bin/qdbusxml2cpp'

    # Remove liblightdm-qt6-3 requirement — dde-lock doesn't actually use LightDM APIs.
    # The greeter does, but we skip building it since nixpkgs has no Qt6 lightdm bindings.
    substituteInPlace CMakeLists.txt \
      --replace-fail 'pkg_check_modules(Greeter REQUIRED liblightdm-qt6-3)' \
                     '# pkg_check_modules(Greeter REQUIRED liblightdm-qt6-3) -- patched out for NixOS'

    # Remove spurious Greeter_LIBRARIES from dde-lock link line
    substituteInPlace CMakeLists.txt \
      --replace-fail '    ''${Greeter_LIBRARIES}
    PkgConfig::SSL
)
if (DISABLE_DSS_SNIPE)' \
                     '    PkgConfig::SSL
)
if (DISABLE_DSS_SNIPE)'

    # Don't build lightdm-deepin-greeter (needs liblightdm-qt6-3 which doesn't exist in nixpkgs).
    # Wrap the entire greeter block in if(FALSE)...endif() to skip it cleanly.
    # The block covers: GREETER_SRCS, add_executable, target_include/compile/link for greeter.
    sed -i '/^set(GREETER_SRCS/i if(FALSE) # NixOS: skip greeter (no liblightdm-qt6-3)' CMakeLists.txt
    sed -i '/^add_subdirectory(tests)/i endif() # NixOS: end skip greeter' CMakeLists.txt

    # Also skip tests (they reference the greeter target)
    substituteInPlace CMakeLists.txt \
      --replace-fail 'add_subdirectory(tests)' \
                     '# add_subdirectory(tests) -- disabled for NixOS'

    # Remove greeter from install targets
    substituteInPlace CMakeLists.txt \
      --replace-fail 'install(TARGETS dde-lock lightdm-deepin-greeter DESTINATION ''${CMAKE_INSTALL_BINDIR})' \
                     'install(TARGETS dde-lock DESTINATION ''${CMAKE_INSTALL_BINDIR})'

    # Fix hardcoded /usr paths in source code
    find . -name "*.cpp" -o -name "*.h" | xargs sed -i \
      -e 's|/usr/share|/run/current-system/sw/share|g' \
      -e 's|/usr/lib|/run/current-system/sw/lib|g' || true

    # Fix hardcoded paths in service and desktop files
    find . -name "*.service" -o -name "*.desktop" | xargs sed -i \
      -e "s|/usr/bin|$out/bin|g" \
      -e "s|/usr/lib|$out/lib|g" || true

    # Fix CMake install paths
    find . -name "CMakeLists.txt" -exec sed -i \
      -e "s|/etc/|$out/etc/|g" {} +
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.qttools
    qt6Packages.wrapQtAppsHook
    deepin-gettext-tools
  ];

  buildInputs = [
    qt6Packages.qtbase
    qt6Packages.qtsvg
    qt6Packages.qtdeclarative
    dtk6core
    dtk6widget
    dtkcommon
    linux-pam
    openssl
    libxcb
    xcbutilwm
    libx11
    libxi
    libxcursor
    libxfixes
    libxrandr
    libxext
    libxtst
    systemd
    gtest
    glib
  ];

  cmakeFlags = [
    "-DDDE_SESSION_SHELL_SNIPE=ON"
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_INSTALL_SYSCONFDIR=${placeholder "out"}/etc"
    "-DCMAKE_INSTALL_LIBDIR=lib"
  ];

  meta = {
    description = "Lock screen and greeter for DDE (Deepin Desktop Environment)";
    homepage = "https://github.com/linuxdeepin/dde-session-shell-snipe";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
