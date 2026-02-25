{
  stdenv,
  lib,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "deepin-desktop-base";
  version = "2025.12.22";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "deepin-desktop-base";
    rev = finalAttrs.version;
    hash = "sha256-uPQ2eE/Yz0k2K3YB1LxZNlQCY8pzCij+jI2pHdooUK4=";
  };

  makeFlags = [
    "DESTDIR=$(out)"
    "PREFIX=/"
  ];

  meta = {
    description = "Base configuration files for Deepin Desktop";
    homepage = "https://github.com/linuxdeepin/deepin-desktop-base";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
