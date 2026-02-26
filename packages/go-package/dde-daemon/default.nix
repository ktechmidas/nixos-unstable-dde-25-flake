{
  lib,
  buildGoModule,
  fetchFromGitHub,
  substituteAll,
  pkg-config,
  deepin-gettext-tools,
  gettext,
  python3,
  wrapGAppsHook3,
  ddcutil,
  alsa-lib,
  glib,
  gtk3,
  libgudev,
  libinput,
  libnl,
  librsvg,
  linux-pam,
  libxcrypt,
  networkmanager,
  pulseaudio,
  gdk-pixbuf-xlib,
  tzdata,
  xkeyboard_config,
  runtimeShell,
  dbus,
  util-linux,
  coreutils,
  lshw,
  systemd,
}:

buildGoModule rec {
  pname = "dde-daemon";
  version = "6.1.75";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-daemon";
    rev = version;
    hash = "sha256-Mw1DUbqiYfx2+VHKYRZqsVScqAo5wuzd7BkxC7Qvy+o=";
  };

  vendorHash = "sha256-mKRd07Oe7Xjv2VgLfakuiR9HtXnUKQUdS3ILZS9tUOo=";

  postPatch = ''
    # Remove hardcoded PATH overrides
    sed -i '/os.Setenv("PATH"/d' grub2/modify_manger.go || true
    sed -i '/os.Setenv("PATH"/d' bin/dde-system-daemon/main.go || true

    # Fix /bin/bash references
    find . -name "*.go" -exec sed -i 's|"/bin/bash"|"${runtimeShell}"|g' {} + || true

    # Fix xkb path
    substituteInPlace inputdevices/layout_list.go \
      --replace-fail "/usr/share/X11/xkb" "${xkeyboard_config}/share/X11/xkb" || true

    # Fix wallpaper paths
    find . -name "*.go" -exec sed -i \
      's|"/usr/share/wallpapers"|"/run/current-system/sw/share/wallpapers"|g' {} + || true

    # Fix timezone paths
    find . -name "*.go" -exec sed -i \
      's|"/usr/share/zoneinfo"|"${tzdata}/share/zoneinfo"|g' {} + || true

    # Fix dde-api paths
    find . -name "*.go" -exec sed -i \
      's|"/usr/lib/deepin-api"|"/run/current-system/sw/lib/deepin-api"|g' {} + || true

    # Fix dde-control-center paths
    find . -name "*.go" -exec sed -i \
      's|"/usr/lib/dde-control-center"|"/run/current-system/sw/lib/dde-control-center"|g' {} + || true

    # Fix deepin-daemon binary paths
    for file in $(grep -rl "/usr/lib/deepin-daemon" .); do
      sed -i 's|/usr/lib/deepin-daemon|/run/current-system/sw/lib/deepin-daemon|g' "$file"
    done

    # Fix hardcoded exe path checks to use strings.Contains for NixOS store paths
    # dde-control-center binary check
    find . -name "*.go" -exec sed -i \
      's|exe == "/usr/bin/dde-control-center"|strings.Contains(exe, "dde-control-center")|g' {} + || true
    find . -name "*.go" -exec sed -i \
      's|cmd == "/usr/bin/dde-control-center"|strings.Contains(cmd, "dde-control-center")|g' {} + || true
    find . -name "*.go" -exec sed -i \
      's|execPath == "/usr/bin/lightdm-deepin-greeter"|strings.Contains(execPath, "lightdm-deepin-greeter")|g' {} + || true

    # Fix dbus-send in udev rules
    find . -name "*.rules" -exec sed -i \
      's|/usr/bin/dbus-send|${dbus}/bin/dbus-send|g' {} + || true

    # Fix /sbin/shutdown
    find . -name "*.sh" -exec sed -i 's|/sbin/shutdown|shutdown|g' {} + || true

    # Fix custom wallpapers path
    find . -name "*.go" -exec sed -i \
      's|"/usr/share/wallpapers/custom-wallpapers/"|"/var/lib/dde-daemon/wallpapers/custom-wallpapers/"|g' {} + || true

    # Fix fprintd kill
    find . -name "*.go" -exec sed -i \
      's|"pkill", "-f", "/usr/lib/fprintd/fprintd"|"pkill", "fprintd"|g' {} + || true

    # Fix /usr/share/dde references
    find . -name "*.go" -exec sed -i \
      's|"/usr/share/dde"|"'$out'/share/dde"|g' {} + || true

    # Fix uadp path
    find . -name "*.go" -exec sed -i \
      's|"/usr/share/uadp"|"/var/lib/dde-daemon/uadp"|g' {} + || true

    # Disable deepin-system-power-control (UOS-specific binary, not in upstream packages)
    # NixOS uses power-profiles-daemon instead
    sed -i 's|"/usr/sbin/deepin-system-power-control"|"/run/current-system/sw/bin/true"|' \
      system/power1/manager_powersave.go || true

    patchShebangs .
  '';

  # go-gir generates old-style C declarations incompatible with GCC 14
  env.CGO_CFLAGS = "-std=gnu11";

  nativeBuildInputs = [
    pkg-config
    deepin-gettext-tools
    gettext
    python3
    wrapGAppsHook3
  ];

  buildInputs = [
    ddcutil
    linux-pam
    libxcrypt
    alsa-lib
    glib
    libgudev
    gtk3
    gdk-pixbuf-xlib
    networkmanager
    libinput
    libnl
    librsvg
    pulseaudio
    tzdata
    xkeyboard_config
  ];

  buildPhase = ''
    runHook preBuild
    make GOBUILD_OPTIONS="$GOFLAGS"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make install DESTDIR="$out" PREFIX="/"
    runHook postInstall
  '';

  doCheck = false;

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "${lib.makeBinPath [
        util-linux
        glib
        lshw
        systemd
      ]}"
    )
  '';

  postFixup = ''
    for binary in $out/lib/deepin-daemon/*; do
      if [ -f "$binary" ] && [ -x "$binary" ]; then
        # Skip non-ELF files (scripts, etc.)
        if file "$binary" | grep -q "ELF"; then
          wrapGApp "$binary"
        fi
      fi
    done
  '';

  meta = {
    description = "Daemon for handling the deepin session settings";
    homepage = "https://github.com/linuxdeepin/dde-daemon";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
