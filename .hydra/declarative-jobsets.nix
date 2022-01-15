{ nixpkgs, declInput }:

let
  pkgs = import nixpkgs {};

  desc = {
    vm_test = {
      description = "rust-for-linux nixos-vm tests";
      checkinterval = "60";
      enabled = "1";
      nixexprinput = "expr";
      nixexprpath = "default.nix";
      schedulingshares = 100;
      enableemail = false;
      emailoverride = "";
      keepnr = 3;
      hidden = false;
      type = 0;
      inputs = {
        linux = {
          value = "https://github.com/rust-for-linux/linux rust";
          type = "git";
          emailresponsible = false;
        };
        nixpkgs = {
          value = "https://github.com/NixOS/nixpkgs staging";
          type = "git";
          emailresponsible = false;
        };
        expr = {
          value = "https://github.com/rust-for-linux/nix vm_test";
          type = "git";
          emailresponsible = false;
        };
      };
    };
    rust = {
      description = "Build linux rust tree";
      checkinterval = "60";
      enabled = "1";
      nixexprinput = "expr";
      nixexprpath = "default.nix";
      schedulingshares = 100;
      enableemail = false;
      emailoverride = "";
      keepnr = 3;
      hidden = false;
      type = 0;
      inputs = {
        linux = {
          value = "https://github.com/rust-for-linux/linux rust";
          type = "git";
          emailresponsible = false;
        };
        nixpkgs = {
          value = "https://github.com/NixOS/nixpkgs staging";
          type = "git";
          emailresponsible = false;
        };
        expr = {
          value = "https://github.com/rust-for-linux/nix main";
          type = "git";
          emailresponsible = false;
        };
      };
    };
    staging-next = {
      description = "Build linux rust tree";
      checkinterval = "60";
      enabled = "1";
      nixexprinput = "expr";
      nixexprpath = "default.nix";
      schedulingshares = 50;
      enableemail = false;
      emailoverride = "";
      keepnr = 3;
      hidden = false;
      type = 0;
      inputs = {
        linux = {
          value = "https://github.com/rust-for-linux/linux rust";
          type = "git";
          emailresponsible = false;
        };
        nixpkgs = {
          value = "https://github.com/NixOS/nixpkgs staging-next";
          type = "git";
          emailresponsible = false;
        };
        expr = {
          value = "https://github.com/rust-for-linux/nix main";
          type = "git";
          emailresponsible = false;
        };
      };
    };
    kloenk-net = {
      description = "Kloenk's try to provide network apis";
      checkinterval = "60";
      enabled = "1";
      nixexprinput = "expr";
      nixexprpath = "default.nix";
      schedulingshares = 50;
      enableemail = false;
      emailoverride = "";
      keepnr = 3;
      hidden = false;
      type = 0;
      inputs = {
        linux = {
          value = "https://github.com/kloenk/linux rust-netdevice";
          type = "git";
          emailresponsible = false;
        };
        nixpkgs = {
          value = "https://github.com/NixOS/nixpkgs staging";
          type = "git";
          emailresponsible = false;
        };
        expr = {
          value = "https://github.com/rust-for-linux/nix main";
          type = "git";
          emailresponsible = false;
        };
      };
    };
  };

in {
  jobsets = pkgs.runCommand "spec-jobsets.json" {} ''
    cat >$out <<EOF
    ${builtins.toJSON desc}
    EOF
  '';
}
