{ system ? builtins.currentSystem }:

let
  sources = import nix/sources.nix;
  pkgs = import sources.nixpkgs { inherit system; };

  rust-for-linux = {
    kernel = pkgs.callPackage ./kernel.nix {
      version = "5.11";
      src = sources.linux;
    };
  };

in
  rust-for-linux
