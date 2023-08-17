# basic nvidia gpu configuration for wayland
{
  lib,
  pkgs,
  config,
  ...
}: let
  # the values that user has set
  cfg = config.custom.nvidia;
in {
  imports = [];
  options.custom.nvidia = {
    enable = lib.mkEnableOption "nvidia drivers";
    # TODO: version, mode, bus ids
  };
  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = ["nvidia"];
    hardware = {
      nvidia = {
        package = pkgs.linuxPackages.nvidiaPackages.stable;
        modesetting.enable = true; # check if needed
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          nvidiaBusId = "PCI:1:0:0";
          intelBusId = "PCI:0:2:0";
        };
      };
      opengl = {
        enable = true;
        driSupport = true;
        extraPackages = with pkgs; [
          intel-compute-runtime
        ];
      };
    };
  };
}
