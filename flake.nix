{
  description = "termux-nix flake for termux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      mk = system: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        modules = [ ./home.nix ];
      };
    in {
      homeConfigurations = {
        # the device is aarch64; built on the PC (binfmt) by `termux-nix switch`
        termux = mk "aarch64-linux";
      };
    };
}
