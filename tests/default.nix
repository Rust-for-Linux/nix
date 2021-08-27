{
  kernel
, nixpkgs
, pkgs
, system ? builtins.currentSystem
}:

let
  linuxPackages_rust = pkgs.linuxPackagesFor kernel;
in {
  minimal = import ./minimal.nix { inherit nixpkgs system linuxPackages_rust; };
  samples = import ./samples.nix { inherit nixpkgs system linuxPackages_rust; };
}
