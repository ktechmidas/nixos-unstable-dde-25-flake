{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6Packages,
  dtk6core,
  glib,
  libmediainfo,
  libisoburn,
  libsecret,
  udisks2,
  util-linux,
  lucenepp,
  boost,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "util-dfm";
  version = "1.3.48";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "util-dfm";
    rev = finalAttrs.version;
    hash = "sha256-9okD113Ae+JEDphBX1FH8SnatIoNl3nnVGN+gzCpxQI=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.qttools
  ];

  buildInputs = [
    qt6Packages.qtbase
    dtk6core
    glib
    libmediainfo
    libisoburn
    libsecret
    udisks2
    util-linux # libmount
    lucenepp
    boost
  ];

  dontWrapQtApps = true;

  # Fix pkgconfig double-prefix issue (NixOS uses absolute install dirs)
  postInstall = ''
    find $out/lib/pkgconfig -name "*.pc" -exec sed -i "s|\''${prefix}/|/|g" {} +
  '';

  meta = {
    description = "File management utility libraries for DDE (dfm6-io, dfm6-mount, dfm6-burn, dfm6-search)";
    homepage = "https://github.com/linuxdeepin/util-dfm";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
