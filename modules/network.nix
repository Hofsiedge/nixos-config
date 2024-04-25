{
  lib,
  config,
  ...
}: let
  cfg = config.custom.network;
  t = lib.types;
  rangePattern = "^([[:digit:]]+)-([[:digit:]]+)$";
  firewallException = t.submodule {
    options = {
      tcp = lib.mkOption {
        type = t.listOf (t.either t.port (t.strMatching rangePattern));
        default = [];
        example = [8080 "8000-8010" 9000];
        description = "TCP ports and port ranges to open";
      };
      udp = lib.mkOption {
        type = t.listOf (t.either t.int (t.strMatching rangePattern));
        default = [];
        example = [8080 "8000-8010" 9000];
        description = "UDP ports and port ranges to open";
      };
    };
  };
in {
  imports = [];
  options.custom.network = {
    enable = lib.mkEnableOption "network settings";

    enableWifi = lib.mkEnableOption "wifi with iwd";

    hosts = lib.mkOption {
      description = "list of host files";
      type = t.listOf t.path;
      default = [];
    };

    firewall = lib.mkOption {
      type = t.submodule {
        options = {
          enable = lib.mkOption {
            default = true;
            example = false;
            description = "Whether to enable firewall";
            type = t.bool;
          };

          openPorts = lib.mkOption {
            description = "services that need open ports";
            example = {
              SomeService = {
                tcp = [2000 "2050-2080" 3100];
                udp = [2700];
              };
              AnotherService = {
                tcp = [3200];
              };
            };
            type = t.attrsOf firewallException;
          };
        };
      };
    };
  };
  config.networking = lib.mkIf cfg.enable {
    # TODO: or not?
    useDHCP = true;

    wireless = lib.mkIf cfg.enableWifi {
      iwd = {
        enable = true;
        settings = {
          General.EnableNetworkConfiguration = true;
          Network.EnableIPv6 = true;
        };
      };
    };

    hostFiles = cfg.hosts;

    firewall = let
      inherit
        (builtins)
        attrValues
        concatMap
        getAttr
        filter
        isInt
        isString
        match
        elemAt
        sort
        ;
      portProcessor = field:
        lib.pipe (attrValues cfg.firewall.openPorts) [
          (concatMap (getAttr field))
          (filter isInt)
          lib.lists.unique
        ];
      portRangeProcessor = field:
        lib.pipe (attrValues cfg.firewall.openPorts) [
          # extract values from cfg.firewallOpenPorts.tcp
          (concatMap (entry: entry.tcp))
          # take only strings
          (filter isString)
          # parse & validate bounds
          (map (
            range: let
              # matching is guaranteed by option type
              bounds = map lib.toInt (match rangePattern range);
              # lower and upper are positive, guaranteed by option type
              lower = elemAt bounds 0;
              upper = elemAt bounds 1;
            in
              if lower < upper
              then {
                from = lower;
                to = upper;
              }
              else abort "invalid port range: ${range}"
          ))
          # sort by (from, to) ascending
          (sort
            (a: b: (a.from < b.from) || (a.from == b.from) && (a.to < b.to)))
          # TODO: merge overlapping ranges
        ];
    in
      lib.mkIf cfg.firewall.enable {
        enable = true;
        allowedTCPPorts = portProcessor "tcp";
        allowedUDPPorts = portProcessor "udp";
        allowedTCPPortRanges = portRangeProcessor "tcp";
        allowedUDPPortRanges = portRangeProcessor "udp";
      };
  };
}
