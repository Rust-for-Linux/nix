{ sources ? import nix/sources.nix
, nixpkgs ? sources.nixpkgs
, linux ? sources.linux
, system ? builtins.currentSystem
}:

let
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;
  callPackage = lib.callPackageWith (pkgs // rust-for-linux);

  rust-for-linux = rec {
    inherit pkgs;

    # rust nightly stuff
    rust_nightly = callPackage ./rust_nightly.nix {
      inherit (pkgs.darwin.apple_sdk.frameworks) CoreFoundation Security;
      buildPackages = pkgs.buildPackages // { inherit rust_nightly; };
    };
    rust = rust_nightly;

    # rust-for-linux itself
    kernel = callPackage ./kernel.nix {
      version = "5.12";
      modVersion = "5.12.0-rc4";
      src = linux;
    };
  };

in
  rust-for-linux
