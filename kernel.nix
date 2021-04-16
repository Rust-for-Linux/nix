{ lib
, llvmPackages_11
, rustPlatform
, rustfmt
, rust-bindgen
, buildLinux
, linuxManualConfig
, kernelPatches

, src
, version
, modVersion ? null
}@args:

let
  llvmPackages = llvmPackages_11;
  inherit (llvmPackages) clang stdenv;

  rustcNightly = rustPlatform.rust.rustc.overrideAttrs (oldAttrs: {
    configureFlags = map (flag:
      if flag == "--release-channel=stable" then
        "--release-channel=nightly"
      else
        flag
    ) oldAttrs.configureFlags;
  });

  addRust = old: {
    buildInputs = (old.buildInputs or []) ++ [
      rustcNightly
    ];
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
      (rust-bindgen.override { inherit clang llvmPackages; })
      rustfmt
    ];
    postPatch = ''
      substituteInPlace rust/Makefile --replace 'rustc_src = $(rustc_sysroot)/lib/rustlib/src/rust' "rust_lib_src = ${rustPlatform.rustLibSrc}"
      substituteInPlace rust/Makefile --replace '$(rustc_src)/library' '$(rust_lib_src)'
    '';
  };

in

(linuxManualConfig rec {
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
}).overrideAttrs addRust
