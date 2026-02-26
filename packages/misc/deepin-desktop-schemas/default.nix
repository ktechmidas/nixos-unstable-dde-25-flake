{
  stdenv,
  lib,
  fetchFromGitHub,
  python3,
  go,
  glib,
  gsettings-desktop-schemas,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "deepin-desktop-schemas";
  version = "6.0.13";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "deepin-desktop-schemas";
    rev = finalAttrs.version;
    hash = "sha256-2WGrda800xIFlOrSkbEeF4MKTDIhYMhwervB1xu2nZA=";
  };

  nativeBuildInputs = [
    python3
    glib  # for glib-compile-schemas
  ];

  buildInputs = [
    gsettings-desktop-schemas  # wrap schemas reference GNOME schemas
  ];

  # Skip the Go-based override_tool build (needs network access)
  # and just install the schema files directly
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install GSettings schemas (including wrap schemas for GNOME compat)
    mkdir -p $out/share/glib-2.0/schemas
    install -m644 schemas/*.xml $out/share/glib-2.0/schemas/
    install -m644 schemas/wrap/*.xml $out/share/glib-2.0/schemas/

    # Copy GNOME schemas so wrap schemas can reference their enums
    for f in ${gsettings-desktop-schemas}/share/gsettings-schemas/*/glib-2.0/schemas/*.xml; do
      cp -n "$f" $out/share/glib-2.0/schemas/ 2>/dev/null || true
    done

    # Install overrides
    mkdir -p $out/share/deepin-desktop-schemas
    cp -r overrides $out/share/deepin-desktop-schemas/

    # Compile all schemas together (deepin + GNOME)
    glib-compile-schemas $out/share/glib-2.0/schemas

    runHook postInstall
  '';

  meta = {
    description = "GSettings schemas for Deepin Desktop Environment";
    homepage = "https://github.com/linuxdeepin/deepin-desktop-schemas";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
