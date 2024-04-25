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
    notify = msg: ''notify-send -t 5000 nixcfg "${msg}" '';
  in
    builtins.mapAttrs cmd {
      edit = "$EDITOR configuration.nix";
      switch = ''
        sudo nixos-rebuild switch --flake .#hofsiedge "$@" \
          && ${notify "switch: ok"} \
          && nix profile diff-closures --profile /nix/var/nix/profiles/system \
          || ${notify "switch: error"}
      '';
      update = ''
        sudo nix flake update "$@" \
          && ${notify "update: ok"} \
          || ${notify "update: error"}
      '';
      clean = ''
        sudo nix-collect-garbage -d
        sudo nixos-rebuild boot --flake .#hofsiedge "$@"
      '';
      # nvim-offline = ''
      #   pushd nvim
      #   nix flake lock --update-input extra_config --no-warn-dirty
      #   nix build --offline --no-warn-dirty
      #   popd
      #   sudo nix flake lock --update-input neovim --offline --no-warn-dirty
      #   nixcfg-switch "$@"
      # '';
      repair = ''
        sudo nix-store --verify --check-contents --repair \
          && ${notify "repair: ok"} \
          || ${notify "repair: error"}
      '';
    };
in {
  imports = [];
  options.custom.nixcfg-commands = {
    enable = lib.mkEnableOption "nixcfg-... commands";
  };
  config = lib.mkIf config.custom.nixcfg-commands.enable {
    environment.systemPackages = builtins.attrValues nixcfg;
  };
}
