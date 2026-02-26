{
  lib,
  buildGoModule,
  fetchFromGitHub,
  gettext,
  pkg-config,
  wrapGAppsHook3,
  glib,
  gtk3,
  libx11,
  libxi,
  libgudev,
  dbus,
  tzdata,
  bash,
}:

buildGoModule rec {
  pname = "startdde";
  version = "6.1.6";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "startdde";
    rev = version;
    hash = "sha256-znpp5lyGNUTHfyHcIu05pCWgzdNB0sKr+jNPZm+86O4=";
  };

  vendorHash = "sha256-DaDF/1RI2XJ8R/RvsKKRISLJlI7+4EwXjIlJWWma2zk=";

  postPatch = ''
    # Fix hardcoded /bin/bash
    substituteInPlace display/manager.go \
      --replace-fail "/bin/bash" "${bash}/bin/bash"

    # Fix hardcoded /bin/sh in wayland util
    substituteInPlace wl_display/util.go \
      --replace-fail "/bin/sh" "${bash}/bin/sh" || true

    # Fix dbus-send path in systemd service
    substituteInPlace misc/systemd_task/dde-display-task-refresh-brightness.service \
      --replace-fail "/usr/bin/dbus-send" "${dbus}/bin/dbus-send"

    # Fix deepin-daemon binary path
    substituteInPlace display/manager.go \
      --replace-fail "/usr/lib/deepin-daemon" "/run/current-system/sw/lib/deepin-daemon"

    # Fix timezone data path
    substituteInPlace display/color_temp.go \
      --replace-fail "/usr/share/zoneinfo/zone1970.tab" "${tzdata}/share/zoneinfo/zone1970.tab" || true

    # Fix lightdm config path
    substituteInPlace misc/lightdm.conf \
      --replace-fail "/usr" "$out" || true

    # Fix sbin -> bin for fix-xauthority-perm
    sed -i 's/sbin/bin/' Makefile
  '';

  nativeBuildInputs = [
    gettext
    pkg-config
    wrapGAppsHook3
    glib
  ];

  buildInputs = [
    gtk3
    libx11
    libxi
    libgudev
  ];

  # go-gir generates old-style C declarations with () that GCC 14 treats as (void),
  # conflicting with cgo's proper prototypes. Force C11 standard.
  env.CGO_CFLAGS = "-std=gnu11";

  buildPhase = ''
    runHook preBuild
    make GO_BUILD_FLAGS="$GOFLAGS"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make install DESTDIR="$out" PREFIX="/"
    runHook postInstall
  '';

  meta = {
    description = "Starter of deepin desktop environment";
    homepage = "https://github.com/linuxdeepin/startdde";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
