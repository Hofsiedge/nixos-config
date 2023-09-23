{
  pkgs,
  # home-manager,
  externalHostsfile,
  ...
}: let
  linja-sike = pkgs.callPackage ./packages/linja-sike.nix {};
in {
  imports = [
    ./hardware-configuration.nix

    ./modules/scripts.nix
    ./modules/nvidia.nix
    ./modules/devices.nix
    ./modules/network.nix
  ];

  # nixcfg
  custom.nixcfg-commands.enable = true;
  # GPU configuration
  custom.nvidia.enable = true;
  # devices
  custom.devices = {
    enable = true;
    extra-drives = [
      {
        enable = true;
        mountPoint = "/home/hofsiedge/media/E";
        device = "/dev/sda1";
        fsType = "ntfs-3g";
        options = ["rw" "uid=1000"];
      }
    ];
    keyboards = {
      enable = true;
      defaultKeyboard = "input 1:1:AT_Translated_Set_2_keyboard";
      swaymsgBin = "/etc/profiles/per-user/hofsiedge/bin/swaymsg";
      externalKeyboards = [
        {
          # Vortex Core keyboard
          enable = true;
          usbKeyboardId = "4d9/293/1104";
        }
      ];
    };
  };
  # network settings
  custom.network = {
    enable = true;
    enableWifi = true;
    hosts = [externalHostsfile];
    firewall = {
      enable = true;
      openPorts = {
        DS3 = {
          tcp = ["27015-27030" 27036 27037];
          udp = [4380 "27000-27031" 27036];
        };
        TMNF = rec {
          tcp = [2350 3450];
          udp = tcp;
        };
        Grafana = {
          tcp = [3000];
        };
        PublicServer = {
          tcp = [80];
        };
      };
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  virtualisation = {
    docker = rec {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "daily";
      };
      rootless = {
        enable = true;
        setSocketVariable = true;
        daemon.settings = {
          dns = ["8.8.8.8"]; # fixes malformed default /etc/resolv.conf
          # FIXME: Cannot connect to the Docker daemon at unix:///run/user/1000/docker.sock. Is the docker daemon running?
          # no troubles with sudo
          # data-root = "${users.users.hofsiedge.home}/media/E/docker";
        };
      };
      daemon.settings = rootless.daemon.settings;
    };

    libvirtd = {
      enable = true;
      qemu = {
        ovmf.enable = true;
        ovmf.packages = with pkgs; [OVMFFull.fd virtiofsd win-virtio];
      };
    };
  };
  programs.dconf.enable = true; # is it really needed?

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        consoleMode = "max";
      };
    };

    plymouth = {
      enable = true;
      theme = "breeze";
    };
  };

  # systemd-resolved - resolvconf manager (required by iwd)
  services.resolved.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    enableTCPIP = true;
    # port = 5432;
    # enables local, ipv4 and ipv6 connections
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
      # ipv4
      host  all       all     127.0.0.1/32   trust
      # ipv6
      host  all       all     ::1/128        trust
    '';
    # allows root and postgres to log in as postgres
    # others - only as themselves
    identMap = ''
      # ArbitraryMapName systemUser DBUser
      superuser_map      root       postgres
      superuser_map      postgres   postgres
      # Let other names login as themselves
      superuser_map      /^(.*)$    \1
    '';
  };

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = with pkgs; [gutenprint samsung-unified-linux-driver splix];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  xdg.portal.wlr.enable = true; # enable screen sharing

  users.mutableUsers = true;
  users.users.hofsiedge = {
    isNormalUser = true;
    home = "/home/hofsiedge";
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "video" # Brightness control
      "audio"
      "libvirtd"
      "docker"
    ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
      };
    };
    permittedInsecurePackages = [];
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
  fonts.fonts =
    [linja-sike]
    ++ (with pkgs; [
      (nerdfonts.override {fonts = ["JetBrainsMono" "NerdFontsSymbolsOnly"];})
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
      virt-manager
      pinentry-curses
    ];
    loginShellInit = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec sway || echo "could not start sway: not found"
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
