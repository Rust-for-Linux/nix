{ lib
, mkShellNoCC
, writeShellScriptBin

, b4

, gnumake
, pkg-config
, ncurses
, rustAttrs
, rust-bindgen-unwrapped

, elfutils
, bison
, flex
, perl
, bc
, nettools
, openssl
, rsync
, gmp
, libmpc
, mpfr
, zstd
, python3Minimal
, kmod
, hexdump
  
, isClang ? false
, llvmPackages
, gcc ? null
}:

#assert !isClang -> gcc;

let
  makeBinArg = package: name: bin: "${name}=${package}/bin/${bin}";
  makeHostToolArg = package: unwrapped: name: bin: "${makeBinArg unwrapped name bin} ${makeBinArg package "HOST${name}" bin}";
  makeMakeVars = vars: lib.concatStringsSep " \\\n  " ((map (v:
    if v ? package-unwrapped then
      makeHostToolArg v.package v.package-unwrapped v.name v.bin
    else
      makeBinArg v.package v.name v.bin)) vars);
  clangTool = { name, bin, hostPackage ? "clang", package ? "${hostPackage}-unwrapped" }: [
    { inherit name; value = "${llvmPackages.${package}}/bin/${bin}"; }
    { name = "HOST${name}"; value = "${llvmPackages.${hostPackage}}/bin/${bin}"; }
  ];

  # Env variables that make wants
  makeEnv = if isClang then ({
    LLVM = "1";
    NM = "${llvmPackages.libllvm}/bin/llvm-nm";
    STRIP = "${llvmPackages.libllvm}/bin/llvm-strip";
    OBJCOPY = "${llvmPackages.libllvm}/bin/llvm-objcopy";
    READELF = "${llvmPackages.libllvm}/bin/llvm-readelf";
    LLVM_AS = "${llvmPackages.libllvm}/bin/llvm-as";
    LLVM_LINK = "${llvmPackages.libllvm}/bin/llvm-link";
    KCFLAGS = "\"-isystem ${llvmPackages.clang}/resource-root/include\"";
  } // (lib.listToAttrs (lib.flatten (map clangTool [
    { name = "CC"; bin = "clang"; }
    { name = "LD"; bin = "ld.lld"; hostPackage = "bintools"; }
    { name = "AR"; bin = "ar"; hostPackage = "bintools"; }
  ])))) else {
    TODO = builtins.warn "TODO gcc build";
  };

  gnumake' = writeShellScriptBin "make" ''
    ${gnumake}/bin/make "$@" \
      ${lib.concatStringsSep " \\\n  " (lib.mapAttrsToList (name: value: "${name}=${value}") makeEnv)}
  '';
in mkShellNoCC {
  name = "linux";

  packages = [
    b4

    gnumake'
    pkg-config
    ncurses

    elfutils
    bison
    flex
    perl
    bc
    nettools
    openssl
    rsync
    gmp
    libmpc
    mpfr
    zstd
    python3Minimal
    kmod
    hexdump

    (rustAttrs.default.override {
      extensions = [ "rust-src" "rust-analyzer" ];
    })
    rust-bindgen-unwrapped
  ];

  env = makeEnv;
  
  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

  hardeningDisable =
    [ "bindnow" "format" "fortify" "stackprotector" "pic" "pie" ];
}
