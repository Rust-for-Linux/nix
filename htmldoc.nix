{ lib, src, configfile, version, stdenv, rustPlatform, rustfmt, rust-bindgen

, perl, bc, nettools, openssl, rsync, gmp, libmpc, mpfr, gawk, zstd
, python3Minimal, libelf, bison, flex, cpio, elfutils, buildPackages

, sphinx, python39Packages
, imagemagick, graphviz, librsvg
, texlive
, which
}:

let
  inherit (rustPlatform.rust) rustc;

  tex = texlive.combine {
    inherit (texlive) scheme-small;
    inherit (texlive) latexmk anyfontsize capt-of;
    inherit (texlive) eqparbox fncychap framed;
    inherit (texlive) luatex85 multirow needspace;
    inherit (texlive) tabulary threeparttable titlesec;
    inherit (texlive) ucs wrapfig;
  };

in stdenv.mkDerivation {
  pname = "linux-htmldoc";
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

    # documentation
    sphinx python39Packages.sphinx_rtd_theme
    imagemagick graphviz librsvg
    tex which
  ];
  hardeningDisable =
    [ "bindnow" "format" "fortify" "stackprotector" "pic" "pie" ];

  RUST_LIB_SRC = rustPlatform.rustLibSrc;

  #enableParallelBuilding = true;

  prePatch = ''
    for mf in $(find -name Makefile -o -name Makefile.include -o -name install.sh); do
        echo "stripping FHS paths in \`$mf'..."
        sed -i "$mf" -e 's|/usr/bin/||g ; s|/bin/||g ; s|/sbin/||g'
    done
    sed -i Makefile -e 's|= depmod|= ${buildPackages.kmod}/bin/depmod|'

    # Don't include a (random) NT_GNU_BUILD_ID, to make the build more deterministic.
    # This way kernels can be bit-by-bit reproducible depending on settings
    # (e.g. MODULE_SIG and SECURITY_LOCKDOWN_LSM need to be disabled).
    # See also https://kernelnewbies.org/BuildId
    sed -i Makefile -e 's|--build-id=[^ ]*|--build-id=none|'

    patchShebangs scripts
    patchShebangs Documentation
  '';

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

  buildFlags = [
    "KBUILD_BUILD_VERSION=1-NixOS"
    "SPHINXBUILD=${sphinx}/bin/sphinx-build"
    "htmldocs"
    "O=build"
  ];

  preInstall = ''
    installFlagsArray+=("-j$NIX_BUILD_CORES")
  '';

  installPhase = ''
    mkdir "$out"
    cp -r build/Documentation/output/* "$out/"
    mkdir -p $out/nix-support
    echo "doc manual $out/" >> $out/nix-support/hydra-build-products
  '';

  meta = {
    description = "The Linux kernel html documentation";
    license = lib.licenses.gpl2Only;
    homepage = "https://github.com/rust-for-linux/linux";
    repositories.git = "https://github.com/rust-for-linux/linux";
    maintainers = [ lib.maintainers.kloenk ];
    platforms = lib.platforms.linux;
    timeout = 14400; # 4 hours
  };
}
