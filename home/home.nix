{
  pkgs,
  lib,
  unstable,
  ...
} @ inputs: {
  imports = [
    ./modules/nnn
    ./modules/helix
  ];

  # add unstable and tree-sitter-idris to submodule arguments
  _module.args = {
    inherit (inputs) unstable tree-sitter-idris;
  };

  custom = {
    nnn.enable = true;
  };

  stylix.targets.helix.enable = false;
  programs.helix = {
    enable = true;
    defaultEditor = true;
  };

  # TODO: swaylock, swayidle, ly display manager

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    config = {
      bars = [
        {command = "waybar";}
      ];
      terminal = "wezterm";
      modifier = "Mod4";
      menu = "${pkgs.fuzzel}/bin/fuzzel";
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

  programs.fuzzel = {
    enable = true;
    settings.main.dpi-aware = lib.mkForce true;
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top"; # Waybar at top layer
        position = "bottom"; # Waybar position (top|bottom|left|right)
        height = 30; # Waybar height (to be removed for auto height)
        # "width": 1280, # Waybar width
        spacing = 4; # Gaps between modules (4px)
        # Choose the order of the modules
        modules-left = ["sway/workspaces" "sway/mode" "sway/scratchpad" "custom/media"];
        modules-center = ["sway/window"];
        modules-right = [
          "mpd"
          "idle_inhibitor"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "keyboard-state"
          "sway/language"
          "battery"
          "battery#bat2"
          "clock"
          "tray"
        ];
        # Modules configuration
        # "sway/workspaces": {
        #     "disable-scroll": true,
        #     "all-outputs": true,
        #     "warp-on-scroll": false,
        #     "format": "{name}: {icon}",
        #     "format-icons": {
        #         "1": "",
        #         "2": "",
        #         "3": "",
        #         "4": "",
        #         "5": "",
        #         "urgent": "",
        #         "focused": "",
        #         "default": ""
        #     }
        # },
        keyboard-state = {
          numlock = true;
          capslock = true;
          format = "{name} {icon}";
          format-icons = {
            locked = "";
            unlocked = "";
          };
        };
        "sway/mode" = {
          format = "<span style=\"italic\">{}</span>";
        };
        "sway/scratchpad" = {
          format = "{icon} {count}";
          show-empty = false;
          format-icons = ["" ""];
          tooltip = true;
          tooltip-format = "{app}: {title}";
        };
        mpd = {
          format = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ";
          format-disconnected = "Disconnected ";
          format-stopped = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
          unknown-tag = "N/A";
          interval = 2;
          consume-icons = {
            on = " ";
          };
          random-icons = {
            off = "<span color=\"#f53c3c\"></span> ";
            on = " ";
          };
          repeat-icons = {
            "on" = " ";
          };
          single-icons = {
            on = "1 ";
          };
          state-icons = {
            paused = "";
            playing = "";
          };
          tooltip-format = "MPD (connected)";
          tooltip-format-disconnected = "MPD (disconnected)";
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };
        tray = {
          # "icon-size": 21,
          spacing = 10;
        };
        clock = {
          # "timezone": "America/New_York",
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
        cpu = {
          format = "{usage}% ";
          tooltip = false;
        };
        memory = {
          format = "{}% ";
        };
        temperature = {
          # "thermal-zone": 2,
          # "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
          critical-threshold = 80;
          # "format-critical": "{temperatureC}°C {icon}",
          format = "{temperatureC}°C {icon}";
          format-icons = ["" "" ""];
        };
        backlight = {
          # "device"= "acpi_video1",
          format = "{percent}% {icon}";
          format-icons = ["" "" "" "" "" "" "" "" ""];
        };
        battery = {
          states = {
            # good= 95,
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          # format-good= "", # An empty format will hide the module
          # format-full= "",
          format-icons = ["" "" "" "" ""];
        };
        "battery#bat2" = {
          bat = "BAT2";
        };
        network = {
          # interface= "wlp2*", # (Optional) To force the use of this interface
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}= {ipaddr}/{cidr}";
        };
        pulseaudio = {
          # scroll-step= 1, # %, can be a float
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };
        "custom/media" = {
          format = "{icon} {}";
          return-type = "json";
          max-length = 40;
          format-icons = {
            spotify = "";
            default = "🎜";
          };
          escape = true;
          exec = "$HOME/.config/waybar/mediaplayer.py 2> /dev/null"; # Script in resources folder
          # exec= "$HOME/.config/waybar/mediaplayer.py --player spotify 2> /dev/null" # Filter player based on name
        };
      };
    };

    # settings = {
    #   mainBar = {
    #     layer = "top";
    #     position = "top";
    #     height = 30;
    #     output = [
    #       "eDP-1"
    #       "HDMI-A-1"
    #     ];
    #     modules-left = ["sway/workspaces" "sway/mode" "wlr/taskbar"];
    #     modules-center = ["sway/window" "custom/hello-from-waybar"];
    #     modules-right = ["mpd" "custom/mymodule#with-css-id" "temperature"];

    #     "sway/workspaces" = {
    #       disable-scroll = true;
    #       all-outputs = true;
    #     };
    #     "custom/hello-from-waybar" = {
    #       format = "hello {}";
    #       max-length = 40;
    #       interval = "once";
    #       exec = pkgs.writeShellScript "hello-from-waybar" ''
    #         echo "from within waybar"
    #       '';
    #     };
    #   };
    # };
  };

  home.stateVersion = "22.05";
  home.packages = with pkgs; [
    nvd # nix diffs

    chromium
    luakit
    librewolf-wayland
    unstable.telegram-desktop
    unstable.fluffychat

    # nixops

    libreoffice-fresh
    # media
    krita
    blender
    mpv
    inkscape
    obs-studio
    godot_4
    kdenlive
    kicad-small
    okular
    typst

    # zettlr
    # sound & display controls
    # TODO: use a graph instead (https://github.com/futpib/pagraphcontrol)
    # TODO: add effects (https://github.com/wwmm/easyeffects)
    pavucontrol
    pulseaudio
    brightnessctl

    (unstable.python312.withPackages (ps:
      with ps; [
        requests
        ipython
      ]))

    unstable.dbeaver-bin
    # TODO
    # jetbrains.pycharm-community

    # sway modules
    swayidle
    wl-clipboard
    grim # screenshot
    slurp # screenshot

    libnotify

    # preview Markdown
    python311Packages.grip

    anki-bin

    leafpad
    gotop
    tree
    cloc
    jq

    docker-compose

    gtypist

    # FIXME
    # gtk-engine-murrine
    # libadwaita
    # gtk_engines
    # gsettings-desktop-schemas
    # lxappearance-gtk2
    # graphite-gtk-theme

    # Nvidia stuff. FIXME: fine tune for the new hardware
    egl-wayland

    pass-wayland

    unstable.anydesk

    (pkgs.writeShellScriptBin "go-playground" ''
      pushd /home/hofsiedge/Projects/go-playground
      nix develop --offline --command $EDITOR code.go
      popd
    '')
  ];

  programs.swaylock.enable = true;
  services.mako.enable = true; # notifications

  programs.home-manager.enable = true;

  gtk.enable = true;

  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      return {
        enable_tab_bar = false,
        -- color_scheme = "MaterialDesignColors",
        color_scheme = "Dark Pastel",
        font_size = 14.1,
        font = wezterm.font_with_fallback {
          'JetBrains Mono',
          'FreeMono',
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

  programs.lazygit.enable = true;

  programs.firefox = {
    enable = true;
    package = unstable.firefox;
    profiles.hofsiedge = {
      extensions = with inputs.firefox-addons; [
        # vimium-c
        # ublock-origin
        # ublacklist
        # youtube-shorts-block
      ];
      search = {
        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@np"];
          };

          "NixOS Wiki" = {
            urls = [{template = "https://nixos.wiki/index.php?search={searchTerms}";}];
            iconUpdateURL = "https://nixos.wiki/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000; # every day
            definedAliases = ["@nw"];
          };

          "Bing".metaData.hidden = true;
          "Google".metaData.alias = "@g";
        };
        force = true;
      };
    };
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
      # "workbench.colorTheme" = "Default Dark+";
      "python.defaultInterpreterPath" = "/run/current-system/sw/bin/python";
    };
  };

  programs.git = {
    enable = true;
    userName = "Hofsiedge";
    userEmail = "hofsiedge@gmail.com";
    ignores = [
      "*.swp"
      "*.bin"
      "*.pyc"
      "__pycache__"
      "node_modules"
      ".nix_node"
      ".nix_go"
    ];
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      export XDG_DATA_HOME="$HOME/.local/share"
      export PS1="\n(''${name:-sys-env}) \[\033[1;32m\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\n\$\[\033[0m\] "
    '';
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/xhtml_xml" = "firefox.desktop";
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop;"; # yeah, that's how telegram wants it
    };
  };
}
