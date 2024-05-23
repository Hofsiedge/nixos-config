{
  pkgs,
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
      terminal = "wezterm";
      modifier = "Mod4";
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
    bemenu # dmenu clone

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
