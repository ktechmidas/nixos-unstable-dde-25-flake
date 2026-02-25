{
  stdenv,
  lib,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "deepin-wallpapers";
  version = "1.7.25";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "deepin-wallpapers";
    rev = finalAttrs.version;
    hash = "sha256-eMtk/uWop2i6J61FVwlXzkjxBe0LwnirxEb40AbyPfs=";
  };

  makeFlags = [
    "PREFIX=$(out)"
  ];

  meta = {
    description = "Wallpapers for Deepin Desktop Environment";
    homepage = "https://github.com/linuxdeepin/deepin-wallpapers";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
