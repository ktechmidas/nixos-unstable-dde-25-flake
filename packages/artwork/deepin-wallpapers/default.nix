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

  postPatch = ''
    # Skip blur generation (needs dde-api image-blur at build time)
    # and skip os-release check
    sed -i '/image-blur/d' Makefile
    sed -i '/os-release/d' Makefile
    sed -i 's|/usr/lib/deepin-api/image-blur|true|g' Makefile
  '';

  # Only install the wallpapers, not the blurred versions
  buildPhase = ''
    runHook preBuild
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/wallpapers/deepin
    cp -r deepin/*.jpg $out/share/wallpapers/deepin/ || true
    cp -r deepin/*.png $out/share/wallpapers/deepin/ || true

    # Create a default background symlink
    if [ -f $out/share/wallpapers/deepin/desktop.jpg ]; then
      mkdir -p $out/share/backgrounds/deepin
      ln -s $out/share/wallpapers/deepin/desktop.jpg $out/share/backgrounds/deepin/desktop.jpg
    fi
    runHook postInstall
  '';

  meta = {
    description = "Wallpapers for Deepin Desktop Environment";
    homepage = "https://github.com/linuxdeepin/deepin-wallpapers";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
