{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6Packages,
  dtk6core,
  glib,
  libsecret,
  systemd,
  libx11,
  libxcursor,
  libxfixes,
  libcap_ng,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dde-session";
  version = "2.0.17";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-session";
    rev = finalAttrs.version;
    hash = "sha256-LHAk6A+c1E2+nqQhlxoxkw882iiM0tF5iARfAeLZRD4=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = [
    qt6Packages.qtbase
    dtk6core
    glib
    libsecret
    systemd
    libx11
    libxcursor
    libxfixes
    libcap_ng
  ];

  postPatch = ''
    # Fix hardcoded /etc paths across all cmake files
    find . -name "CMakeLists.txt" -exec \
      sed -i "s|/etc/|$out/etc/|g" {} +
  '';

  cmakeFlags = [
    "-DCMAKE_INSTALL_SYSCONFDIR=${placeholder "out"}/etc"
  ];

  meta = {
    description = "Session manager for Deepin Desktop Environment";
    homepage = "https://github.com/linuxdeepin/dde-session";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
