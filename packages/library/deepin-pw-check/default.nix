{
  stdenv,
  lib,
  fetchFromGitHub,
  pkg-config,
  cracklib,
  iniparser,
  linux-pam,
  libxcrypt,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "deepin-pw-check";
  version = "6.0.8";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = "deepin-pw-check";
    rev = finalAttrs.version;
    hash = "sha256-+gXPCowBSBHEofiKJjFsG8hPQzGg0IZlnGDQgK9gASA=";
  };

  patches = [
    ./cracklib-compat.patch
  ];

  postPatch = ''
    # Fix service file paths
    find misc -name "*.service" -exec sed -i "s|/usr/lib|$out/lib|g" {} + || true
    find misc -name "*.conf" -exec sed -i "s|/usr/lib|$out/lib|g" {} + || true
  '';

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    cracklib
    iniparser
    linux-pam
    libxcrypt
  ];

  # Build only the C library (skip Go service binary)
  buildPhase = ''
    runHook preBuild

    # Build the shared library
    cd lib
    gcc -shared -fPIC -DIN_CRACKLIB -o libdeepin_pw_check.so.1.1 \
      deepin_pw_check.c word_check.c passwd_compare.c \
      bigcrypt.c md5.c md5_crypt.c debug.c \
      -lcrack -liniparser -lcrypt -lpam \
      $(pkg-config --cflags --libs iniparser 2>/dev/null || true)
    ln -sf libdeepin_pw_check.so.1.1 libdeepin_pw_check.so.1
    ln -sf libdeepin_pw_check.so.1 libdeepin_pw_check.so
    cd ..

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install library
    mkdir -p $out/lib
    cp -a lib/libdeepin_pw_check.so* $out/lib/

    # Install header
    mkdir -p $out/include
    cp lib/deepin_pw_check.h $out/include/

    # Install pkg-config file
    mkdir -p $out/lib/pkgconfig
    cat > $out/lib/pkgconfig/libdeepin_pw_check.pc << EOF
prefix=$out
libdir=\''${prefix}/lib
includedir=\''${prefix}/include

Name: libdeepin_pw_check
Description: Deepin password check library
Version: ${finalAttrs.version}
Libs: -L\''${libdir} -ldeepin_pw_check
Cflags: -I\''${includedir}
EOF

    runHook postInstall
  '';

  meta = {
    description = "Password strength checking library for Deepin";
    homepage = "https://github.com/linuxdeepin/deepin-pw-check";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
