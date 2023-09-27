# BUG: doesn't work unless there is `pkgs` arg
{pkgs, ...} @ args: {
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.hofsiedge = import ./home.nix args; # inputs.neovim.packages.x86_64-linux.neovim;
}
