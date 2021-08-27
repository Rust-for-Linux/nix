{
  nixpkgs, system
, linuxPackages_rust
}:

import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ pkgs, ... }: {
  name = "rust-samples";
  inherit system;

  nodes.machine = { config, pkgs, ... }: {
    virtualisation.graphics = false;

    boot.kernelPackages = linuxPackages_rust;
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")

    # rust_chrdev
    machine.succeed("modprobe rust_chrdev")
    machine.wait_for_console_text("Rust character device sample \(init\)")
    # TODO: use chardev
    machine.succeed("rmmod rust_chrdev")
    machine.wait_for_console_text("Rust character device sample \(exit\)")

    # rust_minimal
    machine.succeed("modprobe rust_minimal")
    machine.wait_for_console_text("Rust minimal sample \(init\)")
    machine.wait_for_console_text("Am I built-in?")
    machine.succeed("rmmod rust_minimal")
    machine.wait_for_console_text("My message is on the heap!")
    machine.wait_for_console_text("Rust minimal sample \(exit\)")

    # rust_miscdev
    machine.succeed("modprobe rust_miscdev")
    machine.wait_for_console_text("Rust miscellaneous device sample \(init\)")
    machine.succeed("echo test > /dev/rust_miscdev &")
    machine.log("testing if /dev/rust_miscdev does contain '\0x1'")
    assert machine.succeed("cat /dev/rust_miscdev"), '\0x1'
    machine.succeed("rmmod rust_miscdev")
    machine.wait_for_console_text("Rust miscellaneous device sample \(exit\)")

    # rust_module_parameters
    machine.succeed("modprobe rust_module_parameters")
    machine.wait_for_console_text("Rust module parameters sample \(init\)")
    machine.wait_for_console_text("Parameters")
    machine.wait_for_console_text("my_bool:\s*true")
    machine.wait_for_console_text("my_i32:\s*42")
    machine.wait_for_console_text("my_str:\s*default str val")
    machine.wait_for_console_text("my_usize:\s*42")
    machine.wait_for_console_text("my_array:\s*\[0, 1\]")
    # todo: tests
    machine.succeed("rmmod rust_module_parameters")
    machine.wait_for_console_text("Rust module parameters sample \(exit\)")

    # rust_print
    machine.succeed("modprobe rust_print")
    machine.wait_for_console_text("Rust printing macros sample \(init\)")
    machine.wait_for_console_text("Emergency message \(level 0\) without args")
    machine.wait_for_console_text("Alert message \(level 1\) without args")
    machine.wait_for_console_text("Critical message \(level 2\) without args")
    machine.wait_for_console_text("Error message \(level 3\) without args")
    machine.wait_for_console_text("Warning message \(level 4\) without args")
    machine.wait_for_console_text("Notice message \(level 5\) without args")
    machine.wait_for_console_text("Info message \(level 6\) without args")
    machine.wait_for_console_text("A line that is continued without args")
    machine.wait_for_console_text("Emergency message \(level 0\) with args")
    machine.wait_for_console_text("Alert message \(level 1\) with args")
    machine.wait_for_console_text("Critical message \(level 2\) with args")
    machine.wait_for_console_text("Error message \(level 3\) with args")
    machine.wait_for_console_text("Warning message \(level 4\) with args")
    machine.wait_for_console_text("Notice message \(level 5\) with args")
    machine.wait_for_console_text("Info message \(level 6\) with args")
    machine.wait_for_console_text("A line that is continued with args")
    machine.succeed("rmmod rust_print")
    machine.wait_for_console_text("Rust printing macros sample \(exit\)")

    machine.succeed("modprobe rust_random")
    machine.wait_for_file("/dev/rust_random")
    machine.succeed("rmmod rust_random")

    machine.succeed("modprobe rust_semaphore")
    machine.wait_for_console_text("Rust semaphore sample \(init\)")
    machine.succeed("rmmod rust_semaphore")
    machine.wait_for_console_text("Rust semaphore sample \(exit\)")

    machine.succeed("modprobe rust_stack_probing")
    machine.wait_for_console_text("Rust stack probing sample \(init\)")
    machine.wait_for_console_text("arge array has length:")
    machine.succeed("rmmod rust_stack_probing")
    machine.wait_for_console_text("Rust stack probing sample \(exit\)")

    machine.succeed("modprobe rust_sync")
    machine.wait_for_console_text("Rust synchronisation primitives sample \(init\)")
    machine.wait_for_console_text("Value: 10")
    machine.wait_for_console_text("Value: 10")
    machine.succeed("rmmod rust_sync")
    machine.wait_for_console_text("Rust synchronisation primitives sample \(exit\)")
  '';
})