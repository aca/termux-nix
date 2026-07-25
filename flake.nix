{
  description = "termux-nix flake for termux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05?shallow=1";
    # bleeding edge, for packages that move faster than the release (claude-code)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master?shallow=1";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      mk = system: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        extraSpecialArgs = {
          pkgsUnstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
        };
        modules = [ ./home.nix ];
      };
    in {
      homeConfigurations = {
        # the device is aarch64; built on the PC (binfmt) by `termux-nix switch`
        termux = mk "aarch64-linux";
      };
    };
}
