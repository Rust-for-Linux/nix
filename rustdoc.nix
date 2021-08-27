{ lib, src, configfile, version, stdenv, rustPlatform, rustfmt, rust-bindgen

, perl, bc, nettools, openssl, rsync, gmp, libmpc, mpfr, gawk, zstd
, python3Minimal, libelf, bison, flex, cpio, elfutils, buildPackages }:

let inherit (rustPlatform.rust) rustc;

in stdenv.mkDerivation {
  pname = "linux-doc";
  inherit version src;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [
    perl
    bc
    nettools
    openssl
    rsync
    gmp
    libmpc
    mpfr
    gawk
    zstd
    python3Minimal
    libelf
    bison
    flex
    cpio
    elfutils
    rustc
    rust-bindgen
    rustfmt
  ];
  hardeningDisable =
    [ "bindnow" "format" "fortify" "stackprotector" "pic" "pie" ];

  RUST_LIB_SRC = rustPlatform.rustLibSrc;

  #enableParallelBuilding = true;

  configurePhase = ''
    runHook preConfigure


    mkdir build
    export buildRoot="$(pwd)/build"

    echo "manual-config configurePhase buildRoot=$buildRoot pwd=$PWD"

    if [ -f "$buildRoot/.config" ]; then
      echo "Could not link $buildRoot/.config : file exists"
      exit 1
    fi
    ln -sv ${configfile} $buildRoot/.config

    runHook postConfigure

    # Note: we can get rid of this once http://permalink.gmane.org/gmane.linux.kbuild.devel/13800 is merged.
    buildFlagsArray+=("KBUILD_BUILD_TIMESTAMP=$(date -u -d @$SOURCE_DATE_EPOCH)")

    #cd $buildRoot
  '';

  buildFlags = [ "KBUILD_BUILD_VERSION=1-NixOS" "rustdoc" "O=build" ];

  preInstall = ''
    installFlagsArray+=("-j$NIX_BUILD_CORES")
  '';

  installPhase = ''
    mkdir "$out"
    cp -r build/rust/doc/* "$out/"
    mkdir -p $out/nix-support
    echo "doc manual $out/" >> $out/nix-support/hydra-build-products

    cat <<EOF > $out/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>Rust for Linux documentation (Hydra)</title>
    <meta name="description" content="Rust-For-Linux documentation">
    <meta name="author" content="Rust for Linux Contributors">
    <meta http-equiv="refresh" content="0; url=./kernel/">
    <script>location="./kernel/"</script>
    </head>
    <body>
    <h1>Redirecting...</h1>
    <a href="./kernel/">Click here if you are not redirected.</a>
    </body>
    </html>
    EOF
  '';

  meta = {
    description = "The Linux kernel rust documentation";
    license = lib.licenses.gpl2Only;
    homepage = "https://github.com/rust-for-linux/linux";
    repositories.git = "https://github.com/rust-for-linux/linux";
    maintainers = [ lib.maintainers.kloenk ];
    platforms = lib.platforms.linux;
    timeout = 14400; # 4 hours
  };
}
