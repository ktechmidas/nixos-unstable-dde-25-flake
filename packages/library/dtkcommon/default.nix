{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation rec {
  pname = "dtkcommon";
  version = "6.7.33";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = pname;
    rev = version;
    hash = "sha256-KTCVHI3mqYCloaXSx3JdZ8mgT6gk+9O5LEw9r81OhX4=";
  };

  nativeBuildInputs = [ cmake ];

  dontWrapQtApps = true;

  meta = {
    description = "Public project for building DTK Library";
    homepage = "https://github.com/linuxdeepin/dtkcommon";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
