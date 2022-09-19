{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "path:/home/hofsiedge/.nixos-config/nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    externalHostsfile = {
      url = "https://github.com/StevenBlack/hosts/raw/master/alternates/fakenews-gambling-porn/hosts";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs: {
    nixosConfigurations.hofsiedge = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = inputs // { inherit (inputs.neovim.packages.x86_64-linux) neovim; };
      modules = [ ./configuration.nix ];
    };
  };
}
