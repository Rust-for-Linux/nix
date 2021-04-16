{
  sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
, overlay ? (import ./. { inherit sources nixpkgs; }).overlay
}:

import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ pkgs, ... }: {
  system = "x86_64-linux";

  nodes.machine ={ config, pkgs, ... }: {
    nixpkgs.overlays = [
      overlay
    ];

    virtualisation.graphics = false;

    boot.kernelPackages = pkgs.linuxPackages_latest;

    environment.etc.kernel.source = pkgs.linux_rust;
  };

  testScript = ''
    start_all()

    machine.succeed("modprobe rust_minimal")

    # machine.wait_for_consol_text("Rust minimal sample")
  '';
}) {}
