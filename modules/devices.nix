# TODO: keyboard udev rules
{
  lib,
  config,
  ...
}: let
  cfg = config.custom.devices;
in {
  imports = [];
  options.custom.devices = {
    enable = lib.mkEnableOption "enable device-specific settings";
    extra-drives = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          enable =
            lib.mkEnableOption
            "enable auto-mounting (on start) of an internal drive";
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
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["rw" "uid=1000"];
            description = "extra options for the filesystem";
          };
        };
      });
    };
  };
  config = lib.mkIf cfg.enable {
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
  };
}
