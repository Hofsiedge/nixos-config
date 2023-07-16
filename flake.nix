{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    unstable.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "path:/home/hofsiedge/.nixos-config/nvim";
    };
    externalHostsfile = {
      url = "https://github.com/StevenBlack/hosts/raw/master/alternates/fakenews-gambling-porn/hosts";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: {
    nixosConfigurations.hofsiedge = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs =
        inputs
        // {
          inherit (inputs.neovim.packages.x86_64-linux) neovim;
        };
      modules = [
        ./configuration.nix
        {
          # Pin registry so `nix search` doesn't download all the time.
          nix.registry.stale.flake = inputs.nixpkgs;
          nix.registry.unstable.flake = inputs.unstable;
        }
      ];
    };
  };
}
