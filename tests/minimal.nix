{
  nixpkgs, system
, linuxPackages_rust
}:

import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ pkgs, ... }: {
  name = "rust-minimal";
  inherit system;

  nodes.machine = { config, pkgs, ... }: {
    virtualisation.graphics = false;

    boot.kernelPackages = linuxPackages_rust;
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")

    machine.succeed("modprobe rust_minimal")
    machine.wait_for_console_text("Rust minimal sample")
  '';
})