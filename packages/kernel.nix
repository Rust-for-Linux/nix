{ lib, stdenv, llvmPackages_latest, rustPlatform, rustfmt, rust-bindgen
, buildLinux, linuxManualConfig, kernelPatches

, src, version, modVersion ? null, features ? null, ... }@args:

let
  llvmPackages = llvmPackages_latest;
  inherit (llvmPackages_latest) clang;

  inherit (rustPlatform.rust) rustc;

  addRust = old: {
    RUST_LIB_SRC = rustPlatform.rustLibSrc;
    buildInputs = (old.buildInputs or [ ]) ++ [ rustc ];
    nativeBuildInputs = (old.nativeBuildInputs or [ ])
      ++ [ rust-bindgen rustfmt ];
  };

in (linuxManualConfig rec {
  inherit src version stdenv lib;

  kernelPatches = with args.kernelPatches; [
    #bridge_stp_helper
    #request_key_helper
  ];

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = if modVersion != null then
    modVersion
  else
    with lib; concatStringsSep "." (take 3 (splitVersion "${version}.0"));

  # branchVersion needs to be x.y
  extraMeta = { branch = lib.versions.majorMinor version; };

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

  config = {
    CONFIG_MODULES = "y";
    CONFIG_FW_LOADER = "m";

    # needed to get the vm test working. whatever.
    isEnabled = f: true;
    isYes = f: true;
  };
}).overrideAttrs addRust
