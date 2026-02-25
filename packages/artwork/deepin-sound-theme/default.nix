{
  stdenv,
  lib,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "deepin-sound-theme";
  version = "15.10.6";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "deepin-sound-theme";
    rev = finalAttrs.version;
    hash = "sha256-BvG/ygZfM6sDuDSzAqwCzDXGT/bbA6Srlpg3br117OU=";
  };

  makeFlags = [
    "PREFIX=$(out)"
  ];

  dontBuild = true;

  meta = {
    description = "Sound theme for Deepin Desktop Environment";
    homepage = "https://github.com/linuxdeepin/deepin-sound-theme";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
