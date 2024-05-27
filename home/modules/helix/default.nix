{
  unstable,
  tree-sitter-idris,
  pkgs,
  lib,
  ...
}: let
  general = {
    # FIXME: overwrites the shipped files
    # FIX: actually not (they still remain in the nix store, but are ignored by helix since ~/.config/helix/runtime takes precedence)
    # FIX: should just insert a copy of the relevant files from ${unstable.helix}/lib/runtime..
    # helixExtraRuntime = {
    #   target = ".config/helix/runtime";
    #   source = ./runtime;
    #   recursive = true;
    # };

    # lib.filesystem.listFilesRecursive ./home/modules/helix/runtime

    programs.helix = {
      enable = true;
      package = unstable.helix;
      extraPackages = with pkgs; [
        vscode-extensions.llvm-org.lldb-vscode # debugger for several languages
      ];

      settings = {
        theme = "kanagawa";
        editor = {
          line-number = "relative";
          mouse = true;
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
    };

    xdg.desktopEntries.helix = {
      name = "Helix";
      genericName = "Text Editor";
      exec = "wezterm start -- hx %U"; # opens hx in wezterm
      terminal = false;
      categories = ["Application" "Development" "IDE"];
      mimeType = [
        "text/plain"
        "text/xml"
        "text/x-scheme"
        "application/json"
      ];
    };
  };

  nix = {
    programs.helix = {
      extraPackages = with pkgs; [nil alejandra];
      languages.language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "alejandra";
        }
      ];
    };
    xdg.desktopEntries.helix.mimeType = ["text/x-devicetree-source"];
  };

  elm = {
    programs.helix = {
      # TODO: check if elm-format is default
      extraPackages = with pkgs.elmPackages; [elm-language-server elm-format];
    };
  };

  python = {
    programs.helix = {
      extraPackages = with unstable.python312Packages; [
        python-lsp-server
        yapf
        pylsp-mypy
        unstable.ruff-lsp
        # unstable.python311Packages.debugpy # TODO
        # issue: https://github.com/helix-editor/helix/issues/5079
        # issue: https://github.com/helix-editor/helix/issues/6265
      ];
      languages = {
        language-server = {
          ruff-lsp.command = "ruff-lsp";
          pylsp.command = "pylsp";
        };
        language = [
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
        ];
      };
    };

    xdg.desktopEntries.helix.mimeType = ["text/x-python"];
  };

  go = {
    programs.helix = {
      extraPackages = with unstable; [
        go_1_22
        gopls
        delve
        gotools
        go-tools
        golangci-lint
        golangci-lint-langserver
      ];
      languages = {
        language-server = {
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
        };

        language = [
          {
            name = "go";
            auto-format = true;
            language-servers = [
              "gopls"
              "golangci-lint-langserver"
            ];
          }
        ];
      };
    };

    xdg.desktopEntries.helix.mimeType = ["text/x-go"];
  };

  idris2 = {
    programs.helix = {
      languages = {
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
        ];
      };
    };
    home.file = {
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
  };
  web = {
    programs.helix = {
      extraPackages = with unstable; [
        nodePackages.typescript-language-server
        vscode-langservers-extracted
      ];
      languages = {
        language = [
          {
            name = "html";
            auto-format = true;
          }
          {
            name = "javascript";
            auto-format = true;
          }
        ];
      };
    };

    xdg.desktopEntries.helix.mimeType = [
      "text/css"
      "text/html"
      "text/x-javascript"
    ];
  };

  yaml = {
    programs.helix = {
      extraPackages = with unstable; [
        yaml-language-server
      ];
      languages = {
        language-server = {
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
        };
        language = [
          {
            name = "yaml";
            language-servers = ["yaml-language-server"];
            indent = {
              tab-width = 2;
              unit = " ";
            };
          }
        ];
      };
    };
    xdg.desktopEntries.helix.mimeType = ["application/yaml"];
  };

  sql = {
    programs.helix = {
      extraPackages = with unstable; [
        postgres-lsp
        pgformatter
        # sqlfluff
      ];
      languages = {
        language-server = {
          postgres_lsp = {
            command = "postgres_lsp";
          };
        };
        language = [
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
        ];
      };
    };
    xdg.desktopEntries.helix.mimeType = ["application/sql"];
  };

  markdown = {
    programs.helix.extraPackages = with unstable; [marksman];
    xdg.desktopEntries.helix.mimeType = ["text/markdown"];
  };
in
  lib.mkMerge [
    general
    nix
    elm
    python
    go
    idris2
    web
    yaml
    sql
    markdown
    # miscellaneous
    {
      programs.helix = {
        extraPackages = with pkgs; [
          taplo # TOML
        ];
        languages = {
          language-server = {};
          language = [
            {
              name = "c";
              auto-format = true;
            }
          ];
        };
      };
    }
  ]
