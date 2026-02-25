{
  stdenv,
  lib,
  fetchFromGitHub,
  gtk3,
  hicolor-icon-theme,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "deepin-icon-theme";
  version = "2025.12.04";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "deepin-icon-theme";
    rev = finalAttrs.version;
    hash = "sha256-s3VlR6HMKC4vsh4MX0KmS8tMKMVpxK81gAGHV/QVUY8=";
  };

  nativeBuildInputs = [
    gtk3  # for gtk-update-icon-cache
  ];

  propagatedBuildInputs = [
    hicolor-icon-theme
  ];

  makeFlags = [
    "PREFIX=$(out)"
  ];

  dontBuild = true;

  meta = {
    description = "Deepin icon theme";
    homepage = "https://github.com/linuxdeepin/deepin-icon-theme";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
