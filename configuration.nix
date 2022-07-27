# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  customNeovim = import ./nvim.nix;
  # 01.03.2022 revision
  oldpkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/c82b46413401efa740a0b994f52e9903a4f6dcd5.tar.gz";
  }) {};
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
    check-root-permissions || exit
    pushd /home/hofsiedge/.nixos-config/
    nixos-rebuild switch -I nixos-config=./configuration.nix "$@"
    popd
  '';
  nixcfg-clean = pkgs.writeShellScriptBin "nixcfg-clean" ''
    check-root-permissions || exit
    pushd /home/hofsiedge/.nixos-config/
    nix-collect-garbage -d
    nixos-rebuild boot -I nixos-config=./configuration.nix "$@"
    popd
  '';

in
{
  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos>
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
    packageOverrides = pkgs : {
      intel-graphics-compiler = oldpkgs.intel-graphics-compiler;
      intel-compute-runtime   = oldpkgs.intel-compute-runtime;
    };
  };
  programs.steam.enable = true;
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.hofsiedge = { pkgs, ... }: {
    # TODO: swaylock, swayidle, ly display manager

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      config = {
        terminal    = "wezterm";
      	modifier    = "Mod4";
      	# output      = { "*" = {
    	#   bg = "/home/hofsiedge/Wallpapers/Lain_04.jpg fill";
    	# }; };
      };
      extraOptions = ["--unsupported-gpu"];
      extraConfig = ''
        # Brightness
        bindsym XF86MonBrightnessDown exec "brightnessctl set 2%-"
        bindsym XF86MonBrightnessUp exec "brightnessctl set +2%"
        # Volume
        bindsym XF86AudioRaiseVolume exec "pactl set-sink-volume @DEFAULT_SINK@ +1%"
        bindsym XF86AudioLowerVolume exec "pactl set-sink-volume @DEFAULT_SINK@ -1%"
        bindsym XF86AudioMute exec "pactl set-sink-mute @DEFAULT_SINK@ toggle"
        # Keyboard
        input * {
          xkb_layout "us,ru"
          xkb_options "grp:alt_shift_toggle"
        }
        input 1:1:AT_Translated_Set_2_keyboard {
          repeat_delay 250
          repeat_rate  65
          xkb_numlock enable
        }
        input type:touchpad {
          tap enabled
          natural_scroll enabled
          scroll_factor 0.5
          dwt disabled
        }
        input 1386:222:Wacom_Bamboo_16FG_4x5_Finger {
          events disabled
        }
        # TODO
        input 1386:222:Wacom_Bamboo_16FG_4x5_Pen {
        }
      '';
    };
    home.stateVersion = "21.11";
    home.packages = with pkgs; [ 
      firefox surf ungoogled-chromium thunderbird
      tdesktop discord
      # media
      krita blender mpv inkscape obs-studio godot kdenlive kicad-small
      # sound & display controls
      pavucontrol pulseaudio brightnessctl

      go_1_18 gopls delve
      rnix-lsp
      python310 idris2 julia-bin clang_14
      # sway modules
      swaylock swayidle wl-clipboard mako wofi nerdfonts
      wezterm leafpad gotop tree neovide
      
      docker-compose

      gtypist
        
      gtk-engine-murrine libadwaita gtk_engines gsettings-desktop-schemas lxappearance-gtk2  
      graphite-gtk-theme
        
      # Nvidia stuff. FIXME: fine tune for the new hardware
      egl-wayland
    ];
    programs.home-manager.enable = true;
    gtk = {
      enable = true;
      # theme = {
      #   name = "Pop-GTK-theme";
      #   package = pkgs.pop-gtk-theme;
      # };
    };
    programs.neovim = customNeovim pkgs;
    programs.helix = {
      enable = true;
      languages = [
        { name = "go"; auto-format = true; }
      ];
      settings = {
        theme = "monokai_pro_spectrum";
	      editor = {
	        line-number = "relative";
	        mouse = false;
	        scrolloff = 7;
	        lsp.display-messages = true;
	        file-picker.hidden = false;
	        auto-pairs = true;
	      };
        keys.insert = {
          k = {j = "normal_mode"; };
        };
      };
    };
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        # asvetliakov.vscode-neovim
        # redhat.vscode-yaml
        # golang.go
        # ms-python.python ms-toolsai.jupyter
        # dbaeumer.vscode-eslint
        # haskell.haskell
      ];
      userSettings = {
        "workbench.colorTheme" = "Default Dark+";
        "python.defaultInterpreterPath" = "/run/current-system/sw/bin/python";
        "vscode-neovim.neovimExecutablePaths.linux" = "/etc/profiles/per-user/hofsiedge/bin/nvim"; # "/home/hofsiedge/.nix-profile/bin/nvim";
        "vscode-neovim.neovimInitVimPaths.linux" = "/home/hofsiedge/.config/nvim/init.vim";
      };
    };
    # TODO: plugins
    programs.nnn = {
      enable = true;
    };
    programs.git = {
      enable      = true;
      userName    = "Hofsiedge";
      userEmail   = "hofsiedge@gmail.com";
      ignores     = [ "*.swp" "*.bin" "*.pyc" "__pycache__" ];
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
    programs.bash.bashrcExtra = ''
        export XDG_DATA_HOME="$HOME/.local/share"
    '';
  };

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
    ];
    variables = {
      EDITOR = "neovide --multigrid";
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

