{pkgs, ...} @ inputs: {
  imports = [
    ./modules/nnn
    ./modules/helix
  ];

  # add unstable and helix-nightly to submodule arguments
  _module.args = {
    inherit (inputs) unstable;
    inherit (inputs) helix-nightly;
  };

  custom = {
    nnn.enable = true;
    helix = {
      enable = true;
      makeDefaultEditor = true;
    };
  };

  # TODO: swaylock, swayidle, ly display manager

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    config = {
      terminal = "wezterm";
      modifier = "Mod4";
      output = {
        "*" = {
          bg = "/home/hofsiedge/Wallpapers/great_wave_off_kanagawa-starry_night.jpg fill";
        };
      };
    };
    extraOptions = ["--unsupported-gpu"];
    extraConfig = ''
      set $menu bemenu-run

      # Brightness
      bindsym XF86MonBrightnessDown exec "brightnessctl set 2%-"
      bindsym XF86MonBrightnessUp exec "brightnessctl set +2%"
      # Volume
      bindsym XF86AudioRaiseVolume exec "pactl set-sink-volume @DEFAULT_SINK@ +1%"
      bindsym XF86AudioLowerVolume exec "pactl set-sink-volume @DEFAULT_SINK@ -1%"
      bindsym XF86AudioMute exec "pactl set-sink-mute @DEFAULT_SINK@ toggle"
      # Screenshot
      bindsym Print exec grim -g "$(slurp)" /tmp/$(date +'%H:%M:%S.png')

      # Password manager
      bindsym Mod4+p exec passmenu
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
      # TODO
      input 1386:890:Wacom_One_by_Wacom_S_Pen {
      }

      # HDMI workspace 9
      workspace 9 output HDMI-A-1
    '';
  };
  home.stateVersion = "22.05";
  home.packages = with pkgs; [
    firefox
    chromium
    luakit
    # thunderbird
    librewolf-wayland
    tdesktop
    # discord

    # nixops

    libreoffice-fresh
    # media
    krita
    blender
    mpv
    inkscape
    obs-studio
    godot
    kdenlive
    # kicad-small
    okular
    typst

    zettlr
    # sound & display controls
    # TODO: use a graph instead (https://github.com/futpib/pagraphcontrol)
    # TODO: add effects (https://github.com/wwmm/easyeffects)
    pavucontrol
    pulseaudio
    brightnessctl

    python311
    postman

    dbeaver
    # TODO
    # jetbrains.pycharm-community

    # sway modules
    swaylock
    swayidle
    wl-clipboard
    grim # screenshot
    slurp # screenshot
    mako # notifications
    bemenu # dmenu clone

    libnotify

    anki-bin

    leafpad
    gotop
    tree
    cloc

    docker-compose

    gtypist

    gtk-engine-murrine
    libadwaita
    gtk_engines
    gsettings-desktop-schemas
    lxappearance-gtk2
    graphite-gtk-theme

    # Nvidia stuff. FIXME: fine tune for the new hardware
    egl-wayland

    pass-wayland
  ];
  # ++ [neovim];

  programs.home-manager.enable = true;
  gtk = {
    enable = true;
    /*
    theme = {
    name = "Materia-dark";
    package = pkgs.materia-theme;
    };
    */
  };
  programs.wezterm = {
    enable = true;
    # TODO: check whether this is still an issue
    # this causes recompilation for whatever reason... too bad
    extraConfig = ''
      local wezterm = require 'wezterm'
      return {
        enable_tab_bar = false,
        -- color_scheme = "MaterialDesignColors",
        color_scheme = "Dark Pastel",
        font_size = 14.1,
        font = wezterm.font {
          family = 'JetBrains Mono',
        },
        window_padding = {
          left = 0,
          right = 0,
          top = 0,
          bottom = 0,
        },
      }
    '';
  };

  # programs.nushell = {
  #   enable = true;
  #   configFile.text = ''
  #   '';
  #   environmentVariables = {
  #     EDITOR = "hx";
  #   };
  # };

  # for those use cases where helix is lacking yet
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      golang.go
    ];
    userSettings = {
      "workbench.colorTheme" = "Default Dark+";
      "python.defaultInterpreterPath" = "/run/current-system/sw/bin/python";
    };
  };

  programs.git = {
    enable = true;
    userName = "Hofsiedge";
    userEmail = "hofsiedge@gmail.com";
    ignores = ["*.swp" "*.bin" "*.pyc" "__pycache__" "node_modules" ".nix_node"];
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      export XDG_DATA_HOME="$HOME/.local/share"
    '';
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "firefox.desktop";
    };
  };
}
