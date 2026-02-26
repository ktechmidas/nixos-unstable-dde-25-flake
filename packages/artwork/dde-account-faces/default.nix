{
  stdenv,
  lib,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dde-account-faces";
  version = "1.0.17";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "dde-account-faces";
    rev = finalAttrs.version;
    hash = "sha256-z2xvhYQs/6R350D2Oyg/ECWM3H4E2XSr8OAs6pvWCkE=";
  };

  # Pure data package — no compilation needed
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/var/lib/AccountsService
    cp -r icons $out/var/lib/AccountsService/
    runHook postInstall
  '';

  meta = {
    description = "Account face avatars for Deepin Desktop Environment";
    homepage = "https://github.com/linuxdeepin/dde-account-faces";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
