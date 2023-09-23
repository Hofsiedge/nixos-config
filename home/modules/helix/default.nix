{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.custom.helix;
in {
  options.custom.helix = {
    enable = lib.mkEnableOption "helix editor";
    makeDefaultEditor = lib.mkOption {
      description = "set helix as default editor";
      type = lib.types.bool;
      default = false;
    };
  };
  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      package = let
        languageServers = with pkgs; [
          # nix
          nil
          alejandra

          # debugger for several languages
          vscode-extensions.llvm-org.lldb-vscode

          # html (FIXME)
          rome

          # nickel language server
          nls

          # zig language server
          zls

          # elm
          elmPackages.elm-language-server
          elmPackages.elm-format # TODO: check if it is default

          # latex
          texlab

          # TODO: gopls from unstable

          # other
          marksman
          taplo
          yaml-language-server
          python311Packages.python-lsp-server # TODO: pylsp plugins
        ];
      in
        pkgs.symlinkJoin {
          name = "helix";
          paths = [pkgs.helix];
          buildInputs = [pkgs.makeWrapper];
          postBuild = ''
            wrapProgram $out/bin/hx \
              --prefix PATH : ${pkgs.lib.makeBinPath languageServers}
          '';
        };
      settings = {
        theme = "kanagawa";
        editor = {
          line-number = "relative";
          mouse = false;
          idle-timeout = 100;
          completion-trigger-len = 1;
          rulers = [80 100];
          bufferline = "always";

          lsp = {
            display-inlay-hints = true;
          };
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          soft-wrap = {
            enable = true;
          };
        };
        keys = {
          normal = {
            space = {
              H = ":toggle lsp.display-inlay-hints";
            };
          };
        };
      };
      languages = {
        language = [
          {
            name = "nix";
            auto-format = true;
            language-server = {
              # command = "rnix-lsp";
              # args = [ "--stdio" ];
              # command = "nixd";
              # args = [ "--log=verbose" ];
              command = "nil";
            };
            formatter = {
              command = "alejandra";
              # args = ["--stdin"];
            };
          }
          {
            name = "html";
            auto-format = true;
            language-server = {
              command = "rome";
              args = ["lsp-proxy"];
            };
          }
          {
            name = "go";
            auto-format = true;
            config = {
              "formatting.gofumpt" = true;

              "completion.usePlaceholders" = true;

              "diagnostic.analyses.fieldalignment" = true;
              "diagnostic.analyses.shadow" = true;
              "diagnostic.analyses.unusedparams" = true;
              "diagnostic.analyses.unusedwrite" = true;
              "diagnostic.analyses.useany" = true;
              "diagnostic.analyses.unusedvariable" = true;
              "diagnostic.staticcheck" = true;
              "diagnostic.vulncheck" = "Imports";
              "inlayhint.hints" = {
                assignVariableTypes = true;
                compositeLiteralFields = true;
                functionTypeParameters = true;
                rangeVariableTypes = true;
              };
            };
          }
        ];
      };
    };
    home.file.helixExtraRuntime = {
      target = ".config/helix/runtime";
      source = ./runtime;
      recursive = true;
    };
    home.sessionVariables = lib.mkIf cfg.makeDefaultEditor {
      EDITOR = "hx";
    };
  };
}
