{
  pkgs,
  externalHostsfile,
  unstable,
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
    ./modules/bluetooth.nix
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
  networking.extraHosts = ''
    192.168.1.52 lanlocalhost.home
  '';
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
    cpuFreqGovernor = "powersave";
  };
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  virtualisation = {
    docker = rec {
      enable = true;
      # NOTE: nvidia runtime is only available with sudo
      enableNvidia = true;
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
        memtest86.enable = true;
      };
    };

    plymouth = {
      enable = false;
      theme = "breeze";
    };
  };

  # systemd-resolved - resolvconf manager (required by iwd)
  services.resolved.enable = true;

  services.postgresql = {
    enable = false;
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
  xdg.portal = {
    config.common.default = ["gtk"];
    wlr.enable = true; # enable screen sharing
  };

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

  programs.nix-ld.enable = true;

  # GnuPG
  programs.gnupg.agent = {
    enable = true;
  };
  services.pcscd.enable = true;
  # TODO: find another solution to `org.freedesktop.secrets not provided by any service`
  services.gnome.gnome-keyring.enable = true;

  nix = {
    package = unstable.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-going = true
      max-silent-time = 240
      auto-optimise-store = true
    '';
  };

  fonts.fontDir.enable = true;
  fonts.packages =
    [linja-sike]
    ++ (with pkgs; [
      (nerdfonts.override {fonts = ["JetBrainsMono" "NerdFontsSymbolsOnly"];})
      line-awesome
      open-sans
      libertine
      ipafont
      kochi-substitute
      freefont_ttf
    ]);
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "JetBrainsMono Nerd Font Mono"
      "IPAGothic"
      "FreeMono"
    ];
    sansSerif = [
      "Open Sans"
      "IPAGothic"
      "FreeSans"
    ];
    serif = [
      "Linux Libertine O"
      "IPAMincho"
      "FreeSerif"
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

  stylix = {
    enable = true;
    image = ./wallpapers/great_wave_off_kanagawa-starry_night.jpg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    polarity = "dark";
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };
    # FIXME: stylix does not seem to support fallback fonts...
    # fonts = {
    #   serif = {
    #     package = pkgs.dejavu_fonts;
    #     name = "DejaVu Serif";
    #   };
    #   sansSerif = {
    #     package = pkgs.dejavu_fonts;
    #     name = "DejaVu Sans";
    #   };
    #   monospace = {
    #     package =
    #       pkgs.nerdfonts.override
    #       {
    #         fonts = [
    #           "JetBrainsMono"
    #           "NerdFontsSymbolsOnly"
    #         ];
    #       };
    #     name = "JetBrainsMono Nerd Font Mono";
    #   };
    #   emoji = {
    #     package = pkgs.noto-fonts-emoji;
    #     name = "Noto Color Emoji";
    #   };
    # };
  };

  programs.nh = {
    enable = true;
    flake = "/home/hofsiedge/.nixos-config";

    clean = {
      enable = true;
      extraArgs = "--keep 3 --keep-since 3d";
    };
  };

  services.ollama = {
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
