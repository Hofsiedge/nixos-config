{ config, pkgs, home-manager, neovim, ... }:
{
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.hofsiedge = { pkgs, ... }: {
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
      extraOptions = [ "--unsupported-gpu" ];
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
      luakit
      # thunderbird
      librewolf-wayland
      tdesktop
      # discord

      # TODO: make available only to nnn
      unzip

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
      # sound & display controls
      # TODO: use a graph instead (https://github.com/futpib/pagraphcontrol)
      # TODO: add effects (https://github.com/wwmm/easyeffects)
      pavucontrol
      pulseaudio
      brightnessctl

      python310

      # sway modules
      swaylock
      swayidle
      wl-clipboard
      grim
      slurp
      mako
      bemenu

      libnotify

      anki-bin

      leafpad
      gotop
      tree

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

      # TODO: bind this to an F-key
      (pkgs.writeShellScriptBin "toggle-laptop-kbd" ''
        swaymsg 'input "1:1:AT_Translated_Set_2_keyboard" events toggle'
      '')
    ] ++ [ neovim ];
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

    programs.vscode = {
      enable = false;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [ ];
      userSettings = {
        "workbench.colorTheme" = "Default Dark+";
        "python.defaultInterpreterPath" = "/run/current-system/sw/bin/python";
        # "vscode-neovim.neovimExecutablePaths.linux" = "/etc/profiles/per-user/hofsiedge/bin/nvim";
        # "vscode-neovim.neovimInitVimPaths.linux" = "/home/hofsiedge/.config/nvim/init.vim";
      };
    };
    # TODO: plugins
    programs.nnn = {
      enable = true;
    };
    programs.git = {
      enable = true;
      userName = "Hofsiedge";
      userEmail = "hofsiedge@gmail.com";
      ignores = [ "*.swp" "*.bin" "*.pyc" "__pycache__" "node_modules" ".nix_node" ];
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
    programs.bash.bashrcExtra = ''
      export XDG_DATA_HOME="$HOME/.local/share"
    '';
  };
  xdg.mime =
    {
      enable = true;
      defaultApplications = {
        "application/pdf" = "librewolf.desktop";
      };
    };
}
