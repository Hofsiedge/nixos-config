{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.devices;
in {
  imports = [];
  options.custom.devices = {
    enable = lib.mkEnableOption "device-specific settings";
    extra-drives = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          enable =
            lib.mkEnableOption
            "auto-mounting (on start) of an internal drive";
          mountPoint = lib.mkOption {
            type = lib.types.path;
            # TODO: ensure target dir exists
            example = "/home/<user>/media/<drive-name>";
            description = "the directory to mount the drive at";
          };
          device = lib.mkOption {
            type = lib.types.path;
            example = "/dev/sda1";
            description = "path to the device";
          };
          fsType = lib.mkOption {
            # TODO: more FS types
            # TODO: if ntfs-3g check that boot.supportedFilesystems includes "ntfs"
            type = lib.types.enum ["auto" "ext4" "ntfs-3g"];
            default = "auto";
            example = "ntfs-3g";
            description = "filesystem type";
          };
          options = lib.mkOption {
            type = lib.types.listOf lib.types.nonEmptyStr;
            default = [];
            example = ["rw" "uid=1000"];
            description = "extra options for the filesystem";
          };
        };
      });
    };
    keyboards = lib.mkOption {
      description = ''
        keyboards configuration - disable default keyboard while an external
        one is plugged in.
        Note: this depends on Sway currently
      '';
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "external keyboard focusing";
          defaultKeyboard = lib.mkOption {
            type = lib.types.nonEmptyStr;
            example = "input 1:1:AT_Translated_Set_2_keyboard";
          };
          swaymsgBin = lib.mkOption {
            type = lib.types.path;
            example = "/etc/profiles/per-user/hofsiedge/bin/swaymsg";
          };
          externalKeyboards = lib.mkOption {
            description = ''
              list of external keyboards
            '';
            type = lib.types.listOf (lib.types.submodule {
              options = {
                enable = lib.mkEnableOption "focusing for this keyboard";
                usbKeyboardId = lib.mkOption {
                  type = lib.types.nonEmptyStr;
                  # TODO: describe how to obtain this value
                  # TODO: add bluetooth keyboards configuration as well
                  description = "USB keyboard id";
                  example = "4d9/293/1104";
                };
              };
            });
          };
        };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    # extra drives
    # TODO: auto-mount known external drives
    boot = {
      supportedFilesystems = let
        ntfs = lib.lists.optional (
          builtins.any (x: x.enable && x.fsType == "ntfs-3g") cfg.extra-drives
        ) "ntfs";
      in
        ntfs;
    };
    fileSystems = builtins.listToAttrs (
      builtins.map (attrs: {
        name = attrs.mountPoint;
        value = lib.mkIf attrs.enable {
          inherit (attrs) device fsType options;
        };
      })
      cfg.extra-drives
    );

    # external keyboards
    services.udev.extraRules =
      lib.mkIf
      cfg.keyboards.enable (let
        set_keyboard_status = pkgs.writeShellScriptBin "set_keyboard_status" ''
          eval "${cfg.keyboards.swaymsgBin} --socket $(ls /run/user/1000/sway-ipc.* | head -n 1) '${cfg.keyboards.defaultKeyboard} events $@'"
        '';
        keyboardRules = usb_kb_id: ''
          ACTION=="add", SUBSYSTEM=="usb", ENV{PRODUCT}=="${usb_kb_id}", ENV{DEVTYPE}=="usb_device", RUN+="${set_keyboard_status}/bin/set_keyboard_status disabled"
          ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="${usb_kb_id}", ENV{DEVTYPE}=="usb_device", RUN+="${set_keyboard_status}/bin/set_keyboard_status enabled"
        '';
        rules = builtins.map (x: keyboardRules x.usbKeyboardId) cfg.keyboards.externalKeyboards;
      in
        builtins.concatStringsSep "\n" rules);
  };
}
