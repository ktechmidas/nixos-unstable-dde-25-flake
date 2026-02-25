{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "treeland-protocols";
  version = "0.5.4";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "treeland-protocols";
    rev = finalAttrs.version;
    hash = "sha256-tp2KvfjGJ4pMtTSXTt0aQ6Wm2Yz2GYFeV6nS3vVqDmM=";
  };

  nativeBuildInputs = [ cmake ];

  meta = {
    description = "Wayland protocol definitions for Treeland";
    homepage = "https://github.com/linuxdeepin/treeland-protocols";
    license = lib.licenses.lgpl3Plus;
    platforms = lib.platforms.linux;
  };
})
