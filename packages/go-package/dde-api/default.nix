{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  deepin-gettext-tools,
  wrapGAppsHook3,
  alsa-lib,
  gtk3,
  libcanberra,
  libgudev,
  librsvg,
  poppler,
  pulseaudio,
  gdk-pixbuf-xlib,
  coreutils,
  dbus,
}:

buildGoModule rec {
  pname = "dde-api";
  version = "6.0.35";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-api";
    rev = version;
    hash = "sha256-jCy4AJCKUVL4ZCvqr25Rxse+NZkPkEQR+I2Oyv/IGuo=";
  };

  vendorHash = "sha256-GkbrG/rnz2ANw+vHnyxCFirTZjFGjZX8CaeXZgzKoP0=";

  postPatch = ''
    # Fix systemd service paths
    substituteInPlace misc/systemd/system/deepin-shutdown-sound.service \
      --replace-fail "/usr/bin/true" "${coreutils}/bin/true"

    substituteInPlace sound-theme-player/main.go \
      --replace-fail "/usr/sbin/alsactl" "alsactl"

    substituteInPlace misc/scripts/deepin-boot-sound.sh \
      --replace-fail "/usr/bin/dbus-send" "${dbus}/bin/dbus-send"

    substituteInPlace adjust-grub-theme/main.go \
      --replace-fail "/usr/share/dde-api" "$out/share/dde-api"

    # Fix /usr/lib/deepin-api paths in all files
    for file in $(grep -rl "/usr/lib/deepin-api" .); do
      sed -i 's|/usr/lib/deepin-api|/run/current-system/sw/lib/deepin-api|g' "$file"
    done
  '';

  # go-gir generates old-style C declarations incompatible with GCC 14
  env.CGO_CFLAGS = "-std=gnu11";

  nativeBuildInputs = [
    pkg-config
    deepin-gettext-tools
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    gtk3
    libcanberra
    libgudev
    librsvg
    poppler
    pulseaudio
    gdk-pixbuf-xlib
  ];

  buildPhase = ''
    runHook preBuild
    make GOBUILD_OPTIONS="$GOFLAGS"
    runHook postBuild
  '';

  doCheck = false;

  installPhase = ''
    runHook preInstall
    make install DESTDIR="$out" PREFIX="/"
    runHook postInstall
  '';

  postFixup = ''
    for binary in $out/lib/deepin-api/*; do
      if [ -f "$binary" ] && [ -x "$binary" ]; then
        wrapProgram "$binary" "''${gappsWrapperArgs[@]}"
      fi
    done
  '';

  meta = {
    description = "D-Bus interfaces for screen zone detecting, thumbnail generating, sound playing, etc";
    mainProgram = "dde-open";
    homepage = "https://github.com/linuxdeepin/dde-api";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
