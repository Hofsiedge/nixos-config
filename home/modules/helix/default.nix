{
  helix-nightly,
  unstable,
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

          # python
          unstable.python311Packages.python-lsp-server
          unstable.ruff-lsp
          unstable.python311Packages.yapf
          unstable.python311Packages.pylsp-mypy

          # go
          unstable.go_1_21
          unstable.gopls
          unstable.delve
          unstable.gotools
          unstable.go-tools
          unstable.golangci-lint
          unstable.golangci-lint-langserver
        ];
      in
        pkgs.symlinkJoin {
          name = "helix";
          # paths = [unstable.helix];
          paths = [helix-nightly];
          buildInputs = [pkgs.makeWrapper];
          # TODO: why not just add languageServers to paths?
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
        language-server = {
          # python
          ruff-lsp.command = "ruff-lsp";
          pylsp.command = "pylsp";
          # go
          gopls = {
            command = "gopls";
            config = {
              "formatting.gofumpt" = true;
              "ui.completion.usePlaceholders" = true;
              "ui.diagnostic.analyses" = {
                fieldalignment = true;
                shadow = true;
                unusedparams = true;
                unusedwrite = true;
                useany = true;
                unusedvariable = true;
              };
              # "ui.diagnostic.staticcheck" = true;
              "ui.diagnostic.vulncheck" = "Imports";
              "ui.inlayhint.hints" = {
                assignVariableTypes = true;
                compositeLiteralFields = true;
                constantValues = true;
                functionTypeParameters = true;
                parameterNames = true;
                rangeVariableTypes = true;
              };
            };
          };
          golangci-lint-langserver = {
            command = "golangci-lint-langserver";
            config.command = [
              "golangci-lint"
              "run"
              "--out-format"
              "json"
              "--issues-exit-code=1"
            ];
          };
        };
        language = [
          {
            name = "nix";
            auto-format = true;
            formatter.command = "alejandra";
          }
          {
            name = "html";
            auto-format = true;
            # language-servers = [
            #   {
            #     command = "rome";
            #     args = ["lsp-proxy"];
            #   }
            # ];
          }
          {
            name = "go";
            auto-format = true;
            language-servers = ["gopls" "golangci-lint-langserver"];
          }
          {
            name = "python";
            auto-format = true;
            language-servers = [
              "pylsp"
              "ruff-lsp"
            ];
            formatter.command = "yapf";
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
