{ sources ? import nix/sources.nix
, nixpkgs ? sources.nixpkgs
, linux ? sources.linux
, system ? builtins.currentSystem
}:

let
  pkgs = import nixpkgs { inherit system; };

  rust-for-linux = let
    version = "5.16";
    modVersion = "5.16.0";
    src = linux;

    kernel = pkgs.callPackage ./packages/kernel.nix {
      inherit version modVersion src;
      };
  in {
    doc = pkgs.callPackage ./packages/rustdoc.nix {
      inherit version src;
      inherit (kernel) configfile;
    };
    htmldoc = pkgs.callPackage ./packages/htmldoc.nix {
      inherit version src;
      inherit (kernel) configfile;
    };

    inherit kernel;
    # TODO: expose configfile somewhere

    tests = import ./tests { inherit nixpkgs kernel pkgs; };
  };

in
  rust-for-linux
