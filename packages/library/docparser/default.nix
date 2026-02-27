{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  poppler,
  libzip,
  pugixml,
  freetype,
  libxml2,
  util-linux,
  tinyxml-2,
  file,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "docparser";
  version = "1.0.25";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "docparser";
    rev = finalAttrs.version;
    hash = "sha256-6BWjY9ODJwiZTE4Q+mJQDLHGbSmle9Tr5iIZl1ZtnmM=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    poppler
    libzip
    pugixml
    freetype
    libxml2
    util-linux # libuuid
    tinyxml-2
    file # libmagic
  ];

  # Fix pkgconfig double-prefix issue (NixOS uses absolute install dirs)
  postInstall = ''
    sed -i "s|''${prefix}/|/|g" $out/lib/pkgconfig/docparser.pc
  '';

  meta = {
    description = "Document content analysis library for full-text search";
    homepage = "https://github.com/linuxdeepin/docparser";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
