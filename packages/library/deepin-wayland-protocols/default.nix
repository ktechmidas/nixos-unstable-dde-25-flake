{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  extra-cmake-modules,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "deepin-wayland-protocols";
  version = "1.10.0.31";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "deepin-wayland-protocols";
    rev = finalAttrs.version;
    hash = "sha256-z87wMCAK68SZwbA8K92C9u8q1+EIy859xGj/p0GQdrI=";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
  ];

  meta = {
    description = "Non-standard Wayland protocols used by the Deepin desktop";
    homepage = "https://github.com/linuxdeepin/deepin-wayland-protocols";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.linux;
  };
})
