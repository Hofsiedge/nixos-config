{ config, pkgs, lib, home-manager, neovim, ... }:

let
  linja-sike = pkgs.callPackage ./packages/linja-sike.nix { };
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';
  nixcfg =
    let cmd = name: body: pkgs.writeShellScriptBin "nixcfg-${name}" ''
      pushd /home/hofsiedge/.nixos-config/
      ${body}
      popd
    '';
    in
    builtins.mapAttrs cmd {
      edit = "$EDITOR configuration.nix";
      switch = "sudo nixos-rebuild switch --flake .#hofsiedge \"$@\"";
      update = "sudo nix flake update";
      clean = ''
        sudo nix-collect-garbage -d
        sudo nixos-rebuild boot --flake .#hofsiedge "$@"
      '';
    };

in
{
  imports = [
    ./hardware-configuration.nix
    home-manager.nixosModule
    ./home.nix 
  ];

  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # systemd-resolved - resolvconf manager (required by iwd)
  services.resolved.enable = true;

  # TODO: fine tune for the new hardware
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.prime = {
    sync.enable = true;
    nvidiaBusId = "PCI:1:0:0";
    intelBusId = "PCI:0:2:0";
  };

  # services.openvpn.servers = {
  #   client =
  #     let chdef = cmd: ip: "sudo ip route ${cmd} default via ${ip}";
  #     in
  #     {
  #       config = '' config /home/hofsiedge/Projects/VPN/client.conf '';
  #       # up = ''${chdef "del" "192.168.1.1"} && ${chdef "add" "10.8.0.1"}'';
  #       # down = ''${chdef "del" "10.8.0.1"} && ${chdef "add" "192.168.1.1"}'';

  #       # up = "echo nameserver $nameserver | ${pkgs.openresolv}/sbin/resolvconf -m 0 -a $dev";
  #       # down = "${pkgs.openresolv}/sbin/resolvconf -d $dev";
  #     };
  # };

  networking = {
    wireless = {
      iwd = {
        enable = true;
        settings = {
          General.EnableNetworkConfiguration = true;
          Network.EnableIPv6 = true;
        };
      };
      networks = {
        "Shilova_46-56".PreSharedKey = "b1c22c9e43f1a7f8684446b9a68721448b9b89cc105e569ebb144e226260aa6c";
        "Redmi Note 9 Pro".PreSharedKey = "8774d68bcccf76b4565c832b8308c4a23b937704140ba21fa226d8f3f473057c";
      };
    };

    firewall =
      let
        reductor = attrs: args: with lib; with builtins; attrsets.genAttrs attrs (name: lists.unique (concatLists (catAttrs name args)));
        firewallReductor = reductor [ "allowedTCPPorts" "allowedUDPPorts" "allowedTCPPortRanges" "allowedUDPPortRanges" ];
        DS3 = {
          allowedTCPPorts = [ 27036 27037 ];
          allowedUDPPorts = [ 4380 27036 ];
          allowedTCPPortRanges = [{ from = 27015; to = 27030; }];
          allowedUDPPortRanges = [{ from = 27000; to = 27031; }];
        };
        TMNF = rec {
          allowedTCPPorts = [ 2350 3450 ];
          allowedUDPPorts = allowedTCPPorts;
        };
        Something = {
          allowedTCPPorts = [ 3000 ];
        };
        Prometheus = {
          allowedTCPPorts = [ 9090 ];
        };
        VPN = {
          allowedUDPPorts = [ 53 1194 ];
        };
      in
      firewallReductor [ TMNF DS3 Something VPN Prometheus ];

    extraHosts =
      let
        hostsFile = builtins.fetchurl {
          url = "https://github.com/StevenBlack/hosts/raw/master/alternates/fakenews-gambling-porn/hosts";
          sha256 = "1zm4l2sn1pi03l62jy8q4hw7rq11n90rg0c2biwjmda373frrnm5";
        };
      in
      builtins.readFile "${hostsFile}";
  };

  # Set your time zone.
  time.timeZone = "Asia/Chita";

  # Ethernet port auto config
  networking.interfaces.enp3s0.useDHCP = true;
  # soon to be deprecated
  networking.useDHCP = false;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";


  # Enable CUPS to print documents.
  services.printing.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  xdg.portal.wlr.enable = true; # enable screen sharing

  hardware.opengl = {
    enable = true;
    driSupport = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
    ];
  };

  virtualisation.docker.enable = true;

  users.mutableUsers = true;
  users.users.hofsiedge = {
    isNormalUser = true;
    home = "/home/hofsiedge";
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "video" # Brightness control
      "audio"
      "libvirtd"
    ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
      };
    };
  };
  programs.steam.enable = true;

  # GnuPG
  programs.gnupg.agent = {
    enable = true;
  };
  services.pcscd.enable = true;
  # TODO: find another solution to `org.freedesktop.secrets not provided by any service`
  services.gnome.gnome-keyring.enable = true;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  fonts.fontDir.enable = true;
  fonts.fonts = [ linja-sike ] ++ (with pkgs; [
    jetbrains-mono
    line-awesome
    dejavu_fonts
    ipafont
    kochi-substitute
  ]);
  # TODO: check
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "JetBrains Mono"
      "IPAGothic"
    ];
    sansSerif = [
      "DejaVu Sans"
      "IPAGothic"
    ];
    serif = [
      "DejaVu Serif"
      "IPAMincho"
    ];
  };
  environment = {
    systemPackages = with pkgs; [
      nvidia-offload
      virt-manager
      pinentry-curses
    ] ++ builtins.attrValues nixcfg;
    variables = {
      EDITOR = "nvim";
    };
    loginShellInit = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec sway
      fi
    '';
  };



  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
