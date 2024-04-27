{
  unstable,
  tree-sitter-idris,
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
          # rome

          # nickel language server
          nls

          # zig language server
          zls

          # elm
          elmPackages.elm-language-server
          elmPackages.elm-format # TODO: check if it is default

          # latex
          texlab

          # other
          marksman
          taplo
          yaml-language-server

          # python
          unstable.python311Packages.python-lsp-server
          unstable.ruff-lsp
          unstable.python311Packages.yapf
          unstable.python311Packages.pylsp-mypy
          # unstable.python311Packages.debugpy # TODO
          # issue: https://github.com/helix-editor/helix/issues/5079
          # issue: https://github.com/helix-editor/helix/issues/6265

          # go
          unstable.go_1_22
          unstable.gopls
          unstable.delve
          unstable.gotools
          unstable.go-tools
          unstable.golangci-lint
          unstable.golangci-lint-langserver

          # postgresql
          unstable.postgres-lsp
          unstable.pgformatter
          # unstable.sqlfluff

          # js / ts
          unstable.javascript-typescript-langserver
        ];
      in
        pkgs.symlinkJoin {
          name = "helix";
          paths = [
            unstable.helix
            # helix ignores this for whatever reason
            /*
            (pkgs.stdenv.mkDerivation {
              name = "helix-tree-sitter-idris";
              src = tree-sitter-idris.tree-sitter-idris;
              buildPhase = "";
              installPhase = ''
                mkdir -p $out/lib/runtime/{grammars,queries/idris}
                cp parser $out/lib/runtime/grammars/idris.so
                cp -r queries/* $out/lib/runtime/queries/idris
              '';
            })
            */
          ];
          buildInputs = [pkgs.makeWrapper];
          # TODO: why not just add languageServers to paths?
          # TODO: append treesitter queries to already existing files

          # TODO: a separate derivation for hx (I don't understand how to develop it rapidly otherwise)
          postBuild = ''
            wrapProgram $out/bin/hx \
              --prefix PATH : ${pkgs.lib.makeBinPath languageServers}

            # for i in `find ${builtins.trace ./runtime ./runtime} -name "*.scm" -type f`; do
            #   # cat ~/.config/helix/$i $i
            #   echo $i
            # done
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
          # yaml
          yaml-language-server = {
            command = "yaml-language-server";
            args = ["--stdio"];
            config = {
              yaml = {
                keyOrdering = true;
                schemas = {
                  # "TODO: OpenAPI 3.0 instead of 3.1" = "/openapi.yaml";
                };
              };
            };
          };
          # postgresql
          postgres_lsp = {
            command = "postgres_lsp";
          };

          # astro
          astro-ls = {
            command = "astro-ls";
            args = ["--stdio"];
          };

          # js / ts
          javascript-typescript-langserver = {
            command = "javascript-typesctipt-stdio";
          };
        };
        language = [
          {
            name = "idris";
            scope = "source.idris";
            injection-regex = "idris";
            file-types = ["idr"];
            shebangs = [];
            comment-token = "--";
            block-comment-tokens = {
              start = "{-";
              end = "-}";
            };
            indent = {
              tab-width = 2;
              unit = "  ";
            };
            language-servers = ["idris2-lsp"];
          }
          {
            name = "nix";
            auto-format = true;
            formatter.command = "alejandra";
          }
          {
            name = "c";
            auto-format = true;
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
            language-servers = [
              "gopls"
              "golangci-lint-langserver"
            ];
          }
          {
            name = "python";
            auto-format = true;
            language-servers = [
              "pylsp"
              "ruff-lsp"
            ];
            formatter.command = "yapf";
            indent = {
              tab-width = 4;
              unit = " ";
            };
          }
          {
            name = "yaml";
            language-servers = [
              "yaml-language-server"
            ];
            indent = {
              tab-width = 2;
              unit = " ";
            };
          }
          {
            name = "sql";
            file-types = ["sql" "pgsql"];
            language-servers = [
              "postgres_lsp"
            ];
            formatter.command = "pg_format";
            # auto-format = true;
            # formatter = {
            #   command = "sqlfluff";
            #   args = ["render" "--dialect" "postgres" "-"];
            # };
          }
          {
            name = "astro";
            language-servers = ["astro-ls"];
          }
          {
            name = "javascript";
            language-servers = ["javascript-typescript-langserver"];
          }
        ];
      };
    };
    home.file = {
      # FIXME: overwrites the shipped files
      # FIX: actually not (they still remain in the nix store, but are ignored by helix since ~/.config/helix/runtime takes precedence)
      # FIX: should just insert a copy of the relevant files from nix store
      # helixExtraRuntime = {
      #   target = ".config/helix/runtime";
      #   source = ./runtime;
      #   recursive = true;
      # };

      # idris 2 files
      idrisParser = {
        target = ".config/helix/runtime/grammars/idris.so";
        source = "${tree-sitter-idris.tree-sitter-idris}/parser";
      };
      idrisHighlights = {
        # does not work with whole dir, so a single file
        target = ".config/helix/runtime/queries/idris/highlights.scm";
        source = "${tree-sitter-idris.tree-sitter-idris}/queries/highlights.scm";
      };
    };
    home.sessionVariables = lib.mkIf cfg.makeDefaultEditor {
      EDITOR = "hx";
    };

    xdg.desktopEntries.helix = {
      name = "Helix";
      genericName = "Text Editor";
      exec = "wezterm start -- hx %U"; # opens hx in wezterm
      terminal = false;
      categories = ["Application" "Development" "IDE"];
      mimeType = [
        "text/plain"
        "text/markdown"
        "text/xml"
        "text/x-scheme"
        "text/css"
        "text/html"
        "text/x-javascript"
        "text/x-devicetree-source" # .nix apparently...
        "text/x-python"
        # TODO: other filetypes as well
      ];
    };
  };
}
