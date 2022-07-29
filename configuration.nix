# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  linja-sike = pkgs.callPackage ./packages/linja-sike.nix { };
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';
  check-root-permissions = pkgs.writeShellScriptBin "check-root-permissions" ''
    if [ "$EUID" -ne 0 ]
      then printf "\033[31m[%s]\033[0m %s\n" "permission denied"
      exit 1
    fi
  '';
  nixcfg-switch = pkgs.writeShellScriptBin "nixcfg-switch" ''
    pushd /home/hofsiedge/.nixos-config/
    sudo nixos-rebuild switch -I nixos-config=./configuration.nix "$@"
    popd
  '';
  nixcfg-clean = pkgs.writeShellScriptBin "nixcfg-clean" ''
    pushd /home/hofsiedge/.nixos-config/
    sudo nix-collect-garbage -d
    sudo nixos-rebuild boot -I nixos-config=./configuration.nix "$@"
    popd
  '';

in
{
  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos>
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
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.prime = {
    sync.enable = true;
    nvidiaBusId = "PCI:1:0:0";
    intelBusId  = "PCI:0:2:0";
  };

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
        "Shilova_46-56".PreSharedKey    = "b1c22c9e43f1a7f8684446b9a68721448b9b89cc105e569ebb144e226260aa6c";
        "Redmi Note 9 Pro".PreSharedKey = "8774d68bcccf76b4565c832b8308c4a23b937704140ba21fa226d8f3f473057c";
      };
    };
    firewall = {
      allowedTCPPorts = [ 2350 3450 3000 ];
      allowedUDPPorts = [ 2350 ];
    };
    extraHosts = let
      hostsPath = https://github.com/StevenBlack/hosts/raw/master/alternates/fakenews-gambling-porn/hosts;
      hostsFile = builtins.fetchurl hostsPath;
    in builtins.readFile "${hostsFile}";
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
  xdg.portal.wlr.enable    = true;     # enable screen sharing

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
    home         = "/home/hofsiedge";
    extraGroups  = [
      "wheel"        # Enable ‘sudo’ for the user.
      "video"        # Brightness control
      "audio"
      "libvirtd"
    ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs : { };
  };
  programs.steam.enable = true;

  # GnuPG
  programs.gnupg.agent = {
    enable = true;
  };
  services.pcscd.enable = true;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  fonts.fontDir.enable = true;
  fonts.fonts = [ linja-sike ] ++ (with pkgs; [
      fira-code
      dejavu_fonts
      ipafont
      kochi-substitute
    ]);
  # TODO: check
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "Fira Code Regular"
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
        check-root-permissions
        nixcfg-switch
        nixcfg-clean
        virt-manager
        pinentry
    ];
    variables = {
      EDITOR = "nvim";
      NEOVIDE_MULTIGRID = "1";
      NEOVIDE_FRAMELESS = "1";
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

