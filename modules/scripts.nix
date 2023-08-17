{
  pkgs,
  lib,
  config,
  ...
}: let
  nixcfg = let
    cmd = name: body:
      pkgs.writeShellScriptBin "nixcfg-${name}" ''
        pushd /home/hofsiedge/.nixos-config/
        ${body}
        popd
      '';
  in
    builtins.mapAttrs cmd {
      edit = "$EDITOR configuration.nix";
      switch = "sudo nixos-rebuild switch --flake .#hofsiedge \"$@\"";
      update = "sudo nix flake update \"$@\"";
      clean = ''
        sudo nix-collect-garbage -d
        sudo nixos-rebuild boot --flake .#hofsiedge "$@"
      '';
      # TODO: generalize
      nvim-offline = ''
        pushd nvim
        nix flake lock --update-input extra_config --no-warn-dirty
        nix build --offline --no-warn-dirty
        popd
        sudo nix flake lock --update-input neovim --offline --no-warn-dirty
        nixcfg-switch "$@"
      '';
      search-offline = ''
        nix search stale --offline "$@"
      '';
      repair = ''
        sudo nix-store --verify --check-contents --repair
      '';
    };
in {
  imports = [];
  options.custom.nixcfg-commands = {
    enable = lib.mkEnableOption "enable nixcfg-... commands";
  };
  config = lib.mkIf config.custom.nixcfg-commands.enable {
    environment.systemPackages = builtins.attrValues nixcfg;
  };
}
