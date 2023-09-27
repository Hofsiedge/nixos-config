{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    unstable.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim.url = "path:/home/hofsiedge/.nixos-config/nvim";
    helix.url = "github:helix-editor/helix";
    externalHostsfile = {
      url = "https://github.com/StevenBlack/hosts/raw/master/alternates/fakenews-gambling-porn/hosts";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-index-database,
    ...
  } @ inputs: {
    nixosConfigurations.hofsiedge = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs =
        inputs
        // {
          inherit (inputs.neovim.packages.x86_64-linux) neovim;
          helix-nightly = inputs.helix.packages.x86_64-linux.helix;
          unstable = inputs.unstable.legacyPackages.${system};
        };
      modules = [
        {
          # Pin registry so `nix search` doesn't download all the time.
          nix.registry.stale.flake = inputs.nixpkgs;
          nix.registry.unstable.flake = inputs.unstable;
        }
        ./configuration.nix
        home-manager.nixosModules.home-manager
        ./home

        # TODO: move to home-manager
        # https://github.com/nix-community/nix-index-database#usage-in-home-manager
        nix-index-database.nixosModules.nix-index
        {
          programs.nix-index-database.comma.enable = true;
          programs.command-not-found.enable = false;
        }
      ];
    };
  };
}
