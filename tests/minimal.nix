{
  kernel
, nixpkgs
, pkgs
, system ? builtins.currentSystem
}:

let
  packages = pkgs.linuxPackagesFor kernel;
in

import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ pkgs, ... }: {
  inherit system;

  nodes.machine = { config, pkgs, ... }: {
    virtualisation.graphics = false;

    boot.kernelPackages = packages;
  };

  testScript = ''
    start_all()
    machine.succeed("modprobe rust_minimal")
    machine.wait_for_console_text("Rust minimal sample")
  '';
})