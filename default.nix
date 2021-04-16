{ sources ? import nix/sources.nix
, nixpkgs ? sources.nixpkgs
, linux ? sources.linux
, system ? builtins.currentSystem
}:

let
  pkgs = import nixpkgs { inherit system; };


  kernel = pkgs.callPackage ./kernel.nix {
    version = "5.12";
    modVersion = "5.12.0-rc4";
    src = linux;
  };

  overlay = self: super: {
    linux_rust = kernel;
    linuxPackages_rust = super.linuxPackagesFor self.linux_rust;
  };

  vm = import ./vm.nix { inherit nixpkgs overlay; };
in {
  inherit vm kernel;

}
