{
  pkgs,
  lib,
  config,
  ...
}: let
  /*
  Potentially useful commands

  # open the nix store directory of a package
  nnn $(nix eval --raw  unstable#gotools)

  nix store optimise
  */
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
        # TODO: nix store optimise?
        sudo nixos-rebuild boot --flake .#hofsiedge "$@"
        ${notify "clean: finished"}
      '';
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
