{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11"; # stable
    unstable.url = "nixpkgs/nixos-unstable"; # unstable
    unstable-small.url = "nixpkgs/nixos-unstable-small"; # even more unstable

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    externalHostsfile = {
      url = "https://github.com/StevenBlack/hosts/raw/master/alternates/fakenews-gambling-porn/hosts";
      flake = false;
    };

    tree-sitter-idris.url = "path:/home/hofsiedge/Projects/Idris2/tree-sitter-idris";
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
          inherit (inputs.neovim.packages.${system}) neovim;
          unstable = import inputs.unstable {
            inherit system;
            config.allowUnfree = true;
          };
          firefox-addons = inputs.firefox-addons.packages.${system};
          tree-sitter-idris = inputs.tree-sitter-idris.packages.${system};
        };
      modules = [
        {
          # registries for `nix search`
          nix.registry = {
            # Pin registries so `nix search` doesn't download all the time.
            stale.flake = inputs.nixpkgs;
            unstable.flake = inputs.unstable;
            rolling.flake = inputs.unstable-small;

            # BUG: `nix search` does not understand that `flake.nix` is in a subdir
            firefox-addons.flake = inputs.firefox-addons;
          };
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
