{ config, pkgs, lib, home-manager, neovim, externalHostsfile, ... }:

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

in
{
  imports = [
    ./hardware-configuration.nix
    home-manager.nixosModule
    ./home.nix
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      ovmf.enable = true;
      ovmf.packages = with pkgs; [ OVMFFull.fd virtiofsd win-virtio ];
    };
  };
  programs.dconf.enable = true;
  /* services.samba = {
    enable = true;
    openFirewall = true;
    shares = {
    public = {
    path = "/home/hofsiedge/media/virt/";
    # public = "yes";
    browsable = "yes";
    "read only" = "no";
    # "guest ok" = "yes";
    };
    };
    /* extraConfig = ''
    guest account = nobody
    map to guest = bad user
    ''; * /
    }; */

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot = {
    enable = true;
    consoleMode = "max";
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;
  boot.plymouth.theme = "breeze";

  # systemd-resolved - resolvconf manager (required by iwd)
  services.resolved.enable = true;

  # TODO: fine tune for the new hardware
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.package = pkgs.linuxPackages.nvidiaPackages.production;
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.prime = {
    sync.enable = true;
    nvidiaBusId = "PCI:1:0:0";
    intelBusId = "PCI:0:2:0";
  };
  # services.xserver.libinput.enable = true;

  services.udev =
    let
      swaymsg = "/etc/profiles/per-user/hofsiedge/bin/swaymsg";
      laptop_keyboard = "input 1:1:AT_Translated_Set_2_keyboard";
      set_keyboard_status = pkgs.writeShellScriptBin "set_keyboard_status" ''
        eval "${swaymsg} --socket $(ls /run/user/1000/sway-ipc.* | head -n 1) '${laptop_keyboard} events $@'"
      '';
      usb_kb_id = "4d9/293/1104";
    in
    {
      extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ENV{PRODUCT}=="${usb_kb_id}", ENV{DEVTYPE}=="usb_device", RUN+="${set_keyboard_status}/bin/set_keyboard_status disabled" 
        ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="${usb_kb_id}", ENV{DEVTYPE}=="usb_device", RUN+="${set_keyboard_status}/bin/set_keyboard_status enabled" 
      '';
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
        reductor = attrs: args: with lib; with builtins;
          attrsets.genAttrs attrs
            (name: lists.unique
              (concatLists (catAttrs name args)));
        firewallReductor = reductor [
          "allowedTCPPorts"
          "allowedUDPPorts"
          "allowedTCPPortRanges"
          "allowedUDPPortRanges"
        ];
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
        # Probably, loki in docker
        Something = {
          allowedTCPPorts = [ 3000 ];
        };
        Prometheus = {
          allowedTCPPorts = [ 9090 ];
        };
        VPN = {
          allowedUDPPorts = [ 53 1194 ];
        };
        publicHTTP = rec {
          allowedTCPPorts = [ 80 ];
          allowedUDPPorts = allowedTCPPorts;
        };
      in
      firewallReductor [ TMNF DS3 Something VPN Prometheus publicHTTP ];

    extraHosts = builtins.readFile externalHostsfile.outPath;
  };

  # Set your time zone.
  time.timeZone = "Asia/Chita";

  # Ethernet port auto config
  # FIXME
  /*
    Dec 08 21:57:19 nixos dhcpcd[5092]: DUID 00:04:27:4e:4c:75:12:87:43:4a:96:fb:4b:65:e0:bc:c0:c6
    Dec 08 21:57:19 nixos dhcpcd[5092]: enp3s0: waiting for carrier
    Dec 08 21:57:45 nixos dhcpcd[5092]: ps_root_dispatch: No such file or directory
    Dec 08 21:57:45 nixos dhcpcd[5092]: ps_root_dispatch: No such file or directory
    Dec 08 21:57:45 nixos dhcpcd[5089]: ps_root_dispatch: No such file or directory
    Dec 08 21:57:45 nixos dhcpcd[5089]: ps_root_dispatch: No such file or directory
    Dec 08 21:57:45 nixos dhcpcd[5089]: ps_root_dispatch: No such process
    Dec 08 21:57:45 nixos dhcpcd[5092]: ps_root_dispatch: No such process
    Dec 08 21:57:49 nixos dhcpcd[5092]: timed out
    Dec 08 21:57:49 nixos systemd[1]: Started DHCP Client.
  */
  # networking.interfaces.enp3s0.useDHCP = false;
  # networking.interfaces.enp3s0.useDHCP = false;
  /* networking.interfaces.enp3s0.ipv4.addresses = [{
    address = "192.168.1.153";
    prefixLength = 24;
    }]; */
  # soon to be deprecated
  # networking.useDHCP = false;
  networking.useDHCP = false;
  networking.interfaces = {
    enp3s0.ipv4.addresses = [{
      address = "192.168.1.153";
      prefixLength = 24;
    }];
    wlan0.ipv4.addresses = [{
      address = "192.168.10.94";
      prefixLength = 24;
    }];
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";


  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint samsung-unified-linux-driver splix ];
  };

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
      # "adbusers"
    ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
      };
    };
    permittedInsecurePackages = [ ];
  };
  programs.steam.enable = true;

  # programs.adb.enable = true;

  # GnuPG
  programs.gnupg.agent = {
    enable = true;
  };
  services.pcscd.enable = true;
  # TODO: find another solution to `org.freedesktop.secrets not provided by any service`
  services.gnome.gnome-keyring.enable = true;
  /*
    security.pam.services.gnupg.enableGnomeKeyring = true;
    security.pam.services.gnome-keyring.text = ''
    auth     optional    ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so
    session  optional    ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
    password  optional    ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so
    '';
  */ # doesn't solve the boot issue


  nix = {
    # TODO: check if there are more suitable versions
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes repl-flake
      keep-going = true
      max-silent-time = 180
      auto-optimise-store = true
    '';
  };

  fonts.fontDir.enable = true;
  fonts.fonts = [ linja-sike ] ++ (with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "NerdFontsSymbolsOnly" ]; })
    line-awesome
    # dejavu_fonts
    open-sans
    libertine
    ipafont
    kochi-substitute
  ]);
  # TODO: check
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "JetBrainsMono Nerd Font Mono"
      "IPAGothic"
    ];
    sansSerif = [
      "Open Sans"
      "IPAGothic"
    ];
    serif = [
      "Linux Libertine O"
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
      EDITOR = "hx";
    };
    loginShellInit = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec sway
      fi
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
