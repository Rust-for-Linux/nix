{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    oxalica.url = "github:oxalica/rust-overlay";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }: {
  } // flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ inputs.oxalica.overlays.default ];
    };
  in {
    devShells = {
      default = pkgs.callPackage ./nix/shell.nix { rustAttrs = pkgs.rust-bin.stable.latest; llvmPackages = pkgs.llvmPackages_18; };
      clang = self.devShells.${system}.default.override { isClang = true; };
    };
  });
}
