{ lib
, stdenv
, llvmPackages_latest
, rustPlatform
, rustfmt
, rust-bindgen
, buildLinux
, linuxManualConfig
, kernelPatches
, perl, bc, nettools, openssl, rsync, gmp, libmpc, mpfr, gawk, zstd
, python3Minimal, libelf, bison, flex, cpio, elfutils, buildPackages

, src
, version
, modVersion ? null
}@args:

let
  llvmPackages = llvmPackages_latest;
  inherit (llvmPackages_latest) clang;

  inherit (rustPlatform.rust) rustc;
  /*rustcNightly = rustPlatform.rust.rustc.overrideAttrs (oldAttrs: {
    configureFlags = map (flag:
      if flag == "--release-channel=stable" then
        "--release-channel=nightly"
      else
        flag
    ) oldAttrs.configureFlags;
  });*/

  addRust = old: {
    RUST_LIB_SRC = rustPlatform.rustLibSrc;
    buildInputs = (old.buildInputs or []) ++ [
        rustc
    ];
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
      #(rust-bindgen.override { inherit clang llvmPackages; })
      rust-bindgen
      rustfmt
    ];
  };

in

let
kernel = (linuxManualConfig rec {
  inherit src version stdenv lib;

  kernelPatches = with args.kernelPatches; [
    bridge_stp_helper
    request_key_helper
  ];

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = if modVersion != null then modVersion else with lib; concatStringsSep "." (take 3 (splitVersion "${version}.0"));

  # branchVersion needs to be x.y
  extraMeta = {
    branch = lib.versions.majorMinor version;
  };

  randstructSeed = "";

  configfile = (buildLinux {
    inherit src version stdenv modDirVersion kernelPatches extraMeta;

    structuredExtraConfig = with lib.kernel; {
      RUST = yes;
      SAMPLES = yes;
      SAMPLES_RUST = yes;
      SAMPLE_RUST_MINIMAL = module;
      SAMPLE_RUST_PRINT = module;
      SAMPLE_RUST_MODULE_PARAMETERS = module;
      SAMPLE_RUST_SYNC = module;
      SAMPLE_RUST_CHRDEV = module;
      SAMPLE_RUST_MISCDEV = module;
      SAMPLE_RUST_STACK_PROBING = module;
      SAMPLE_RUST_SEMAPHORE = module;
      SAMPLE_RUST_SEMAPHORE_C = module;
    };
  }).configfile.overrideAttrs addRust;

  config = { CONFIG_MODULES = "y"; CONFIG_FW_LOADER = "m"; };
}).overrideAttrs addRust;

  configfile = kernel.configfile;

  doc = stdenv.mkDerivation {
    pname = "linux-doc";
    inherit version;

    depsBuildBuild = [ buildPackages.stdenv.cc ];
    nativeBuildInputs = [ perl bc nettools openssl rsync gmp libmpc mpfr gawk zstd python3Minimal libelf bison flex cpio elfutils rustc rust-bindgen rustfmt ];
    hardeningDisable = [ "bindnow" "format" "fortify" "stackprotector" "pic" "pie" ];

    RUST_LIB_SRC = rustPlatform.rustLibSrc;

    src = kernel.src;

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

    buildFlags = [
      "KBUILD_BUILD_VERSION=1-NixOS"
      "rustdoc"
      "O=build"
    ];

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
      description =
        "The Linux kernel rust documentation";
      license = lib.licenses.gpl2Only;
      homepage = "https://github.com/rust-for-linux/linux";
      repositories.git = "https://github.com/rust-for-linux/linux";
      platforms = lib.platforms.linux;
      timeout = 14400; # 4 hours
    };
  };

in {
  inherit kernel doc;
}