{
  description = "Neovim PDE. Most of the plugins are from nixpkgs.vimPlugins, not from the flake inputs";

  inputs =
    {
      nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
      flake-utils.url = "github:numtide/flake-utils";
      neovim-flake = {
        url = "github:neovim/neovim?dir=contrib";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      tree-sitter-astro.url = "github:virchau13/tree-sitter-astro";

      extra_config = {
        url = "./extra_config";
        flake = false;
      };

      /*
        "plugin:extra_config" = {
        url = "path:./extra_config";
        flake = false;
        };
      */
      "plugin:idris2-nvim" = {
        url = "github:ShinKage/idris2-nvim";
        flake = false;
      };
      "plugin:nvim-dap-go" = {
        url = "github:leoluz/nvim-dap-go";
        flake = false;
      };
      "plugin:femaco" = {
        url = "github:AckslD/nvim-FeMaco.lua";
        flake = false;
      };
    };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs: flake-utils.lib.eachDefaultSystem (system:
    let
      pluginOverlay = final: prev:
        let
          inherit (prev.vimUtils) buildVimPluginFrom2Nix;
          plugins = builtins.filter
            (s: (builtins.match "plugin:.*" s) != null)
            (builtins.attrNames inputs);
          plugName = input:
            builtins.substring
              (builtins.stringLength "plugin:")
              (builtins.stringLength input)
              input;
          buildPlug = name: buildVimPluginFrom2Nix {
            pname = plugName name;
            version = "master";
            src = builtins.getAttr name inputs;
          };
          extraConfig = buildVimPluginFrom2Nix {
            pname = "extra_config";
            version = "master";
            src = inputs.extra_config;
          };
        in
        {
          neovimPlugins = (builtins.listToAttrs (map
            (plugin: {
              name = plugName plugin;
              value = buildPlug plugin;
            })
            plugins)) // { "extra_config" = extraConfig; };
        };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          pluginOverlay
          (final: prev: {
            neovim-unwrapped = inputs.neovim-flake.packages.${prev.system}.neovim;
          })
        ];
      };
      luaCfg = s: ''
        lua << EOF
        ${s}
        EOF
      '';
      plugins = {
        utils = {
          plugins = with pkgs.vimPlugins; [
            easy-align
            nvim-tree-lua
            nvim-web-devicons
            hop-nvim
            plenary-nvim
            telescope-nvim
          ];
          extraPackages = with pkgs; [
            # telescope dependencies
            ripgrep
            fd
          ];
          config = luaCfg ''
            vim.keymap.set('x', '<leader>a', '<Plug>(EasyAlign)')
            vim.keymap.set('n', '<leader>a', '<Plug>(EasyAlign)')

            -- TODO: git
            vim.keymap.set('n', '<C-n>', '<cmd>NvimTreeToggle<CR>', {silent = true})
            require'nvim-tree'.setup{}

            require'hop'.setup{}
            vim.keymap.set("n", '<leader> w', "<cmd>HopWord<cr>")
            vim.keymap.set("n", '<leader> c', "<cmd>HopChar1<cr>")
            vim.keymap.set("n", '<leader> /', "<cmd>HopPattern<cr>")

            vim.keymap.set("n", '<leader>ff', '<cmd>Telescope find_files<cr>')
            vim.keymap.set("n", '<leader>fg', '<cmd>Telescope live_grep<cr>')
            vim.keymap.set("n", '<leader>fb', '<cmd>Telescope buffers<cr>')
            vim.keymap.set("n", '<leader>fh', '<cmd>Telescope help_tags<cr>')
          '';
        };
        code = {
          plugins = with pkgs.vimPlugins; [
            nvim-lspconfig
            null-ls-nvim

            luasnip
            nvim-cmp
            lspkind-nvim
            cmp-buffer
            cmp-nvim-lsp
            cmp-path
            cmp_luasnip

            pkgs.neovimPlugins.idris2-nvim
            nui-nvim

            nvim-dap
            pkgs.neovimPlugins.nvim-dap-go
            nvim-dap-ui
            nvim-dap-virtual-text

            (nvim-treesitter.withPlugins (p: with p; [
              tree-sitter-go
              tree-sitter-gomod
              tree-sitter-python
              tree-sitter-html
              tree-sitter-json5
              tree-sitter-lua
              tree-sitter-make
              tree-sitter-nix
              tree-sitter-markdown
              tree-sitter-dockerfile
              tree-sitter-c
              tree-sitter-cpp
              tree-sitter-css
              tree-sitter-javascript
              tree-sitter-latex
              tree-sitter-tsx
              tree-sitter-typescript
              tree-sitter-yaml
              tree-sitter-zig
              tree-sitter-scheme
              tree-sitter-query
              tree-sitter-bash

              (pkgs.callPackage "${nixpkgs}/pkgs/development/tools/parsing/tree-sitter/grammar.nix" { } {
                language = "astro";
                version = "0";
                source = "${inputs.tree-sitter-astro}";
              })
            ]))
            playground
            # TODO: replace with lua-only one
            vim-hexokinase

            pkgs.neovimPlugins.femaco

            twilight-nvim
          ];
          extraPackages = with pkgs; [
            rnix-lsp
            statix
            sumneko-lua-language-server
          ];
          # TODO: use ftdetect instead of `set filetype=...`
          config = luaCfg ''
            --[[ augroups ]]--
            vim.cmd [[
              autocmd FileType python          setlocal indentkeys-=<:>
              autocmd FileType python          setlocal indentkeys-=:
              autocmd FileType css             setlocal tabstop=2 shiftwidth=2 expandtab
              autocmd FileType typescriptreact setlocal tabstop=2 shiftwidth=2 expandtab
              autocmd FileType nix             setlocal tabstop=2 shiftwidth=2 expandtab

              autocmd BufNewFile,BufRead *.astro set filetype=astro
            ]]

            -- TreeSitter
            require "nvim-treesitter.configs".setup {
              highlight = {
                enable = true, -- `false` will disable the whole extension
              },
              incremental_selection = {
                enable = true,
                keymaps = {
                  init_selection    = "gnn",
                  node_incremental  = "grn",
                  scope_incremental = "grc",
                  node_decremental  = "grm",
                },
              },
              playground = {
                enable = true,
                disable = {},
                updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
                persist_queries = false, -- Whether the query persists across vim sessions
                keybindings = {
                  toggle_query_editor = 'o',
                  toggle_hl_groups = 'i',
                  toggle_injected_languages = 't',
                  toggle_anonymous_nodes = 'a',
                  toggle_language_display = 'I',
                  focus_language = 'f',
                  unfocus_language = 'F',
                  update = 'R',
                  goto_node = '<cr>',
                  show_help = '?',
                },
              }
            }
            vim.cmd [[
              set foldmethod=expr
              set foldexpr=nvim_treesitter#foldexpr()
            ]]

            require("twilight").setup({})

            -- DAP
            dap = require('dap')
            _set_bp = function ()
              dap.set_breakpoint(
                vim.fn.input('Breakpoint condition: '),
                nil,
                vim.fn.input('Log point message: ')
              )
            end
            vim.keymap.set('n', '<F5>',       dap.continue,          {silent=true})
            vim.keymap.set('n', '<F10>',      dap.step_over,         {silent=true})
            vim.keymap.set('n', '<F11>',      dap.step_into,         {silent=true})
            vim.keymap.set('n', '<F12>',      dap.step_out,          {silent=true})
            vim.keymap.set('n', '<Leader>db', dap.toggle_breakpoint, {silent=true})
            vim.keymap.set('n', '<Leader>dB', _set_bp,               {silent=true})
            vim.keymap.set('n', '<Leader>dr', dap.repl.open,         {silent=true})
            vim.keymap.set('n', '<Leader>dl', dap.run_last,          {silent=true})

            dap.configurations.python = {
              {
                type = 'python';
                request = 'launch';
                name = "Launch file";
                program = "''${file}";
                pythonPath = function()
                  return vim.fn.exepath('python')
                end;
              },
            }
            dap.adapters.python = function(callback, config)
              callback({
                type = 'executable';
                command = vim.fn.exepath('python');
                args = { '-m', 'debugpy.adapter' };
              })
            end

            require'dapui'.setup()
            vim.keymap.set('n', '<leader>di', require"dapui".toggle, {silent=true})
            require("nvim-dap-virtual-text").setup()

            require'dap-go'.setup()
            vim.keymap.set('n', '<leader>dt', require('dap-go').debug_test, {silent=true})

            -- nvim-cmp
            vim.cmd 'set completeopt=menu,menuone,noselect'
            local lspkind = require'lspkind'
            lspkind.init()
            local cmp = require'cmp'
            cmp.setup {
              mapping = {
                ["<C-n>"] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
                ["<C-p>"] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
                ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-e>"] = cmp.mapping.close(),
                ["<C-y>"] = cmp.mapping (
                  cmp.mapping.confirm {
                    behavior = cmp.ConfirmBehavior.Insert,
                    select = true,
                  },
                  { "i", "c" }
                ),
                ["C-space>"] = cmp.mapping.complete(),
                ["<tab>"] = cmp.config.disable,
              },
              sources = {
                { name = "nvim_lua" },
                { name = "nvim_lsp" },
                { name = "path" },
                { name = "luasnip" },
                { name = "buffer", keyword_length = 4 },
              },
              snippet = {
                expand = function(args)
                  require'luasnip'.lsp_expand(args.body)
                end,
              },
              formatting = {
                format = lspkind.cmp_format {
                  with_text = true,
                  menu = {
                    buffer = "[buf]",
                    nvim_lsp = "[LSP]",
                    nvim_lua = "[api]",
                    path = "[FS]",
                    luasnip = "[snip]",
                  },
                },
              },
            }

            -- luasnip
            local ls = require 'luasnip'
            local types = require 'luasnip.util.types'

            ls.config.set_config {
              history = true,
              updateevents = "TextChanged,TextChangedI",
              enable_autosnippets = true,
              
              ext_opts = {
                [types.choiceNode] = {
                  active = {
                    virt_text = { { "<-", "Error" } },
                  },
                },
              },
            }
            
            vim.keymap.set({"i", "s"}, "<c-j>", function()
              if ls.expand_or_jumpable() then
                ls.expand_or_jump()
              end
            end, {silent = true})

            vim.keymap.set({"i", "s"}, "<c-k>", function()
              if ls.jumpable(-1) then
                ls.jump(-1)
              end
            end, {silent = true})

            vim.keymap.set("i", "<c-l>", function()
              if ls.choice_active() then
                ls.change_choice(1)
              end
            end)
            
            local s = ls.snippet
            local sn = ls.snippet_node
            local t = ls.text_node
            local i = ls.insert_node
            local f = ls.function_node
            local c = ls.choice_node
            local d = ls.dynamic_node
            local r = ls.restore_node
            local l = require("luasnip.extras").lambda
            local rep = require("luasnip.extras").rep
            local p = require("luasnip.extras").partial
            local m = require("luasnip.extras").match
            local n = require("luasnip.extras").nonempty
            local dl = require("luasnip.extras").dynamic_lambda
            local fmt = require("luasnip.extras.fmt").fmt
            local fmta = require("luasnip.extras.fmt").fmta
            local types = require("luasnip.util.types")
            local conds = require("luasnip.extras.expand_conditions")
            
            
            vim.api.nvim_create_autocmd({'BufWritePre'}, {
                pattern = {'*.go'},
                callback = vim.lsp.buf.format,
            })
            vim.api.nvim_create_autocmd({'BufEnter'}, {
                pattern = {'*.nim'},
                command = 'set ft=nim',
            })
            
            ls.add_snippets('go', {
              s('tt', fmt("// {} {}\ntype {} {} {{\n\t{}\n}}\n\n",
                {rep(1), i(0, 'TODO: description'), i(1, 'name'), c(2, {t('struct'), t('interface')}), i(3, 'body')})),
              -- TODO: for, function, test, if err, return default, log, embed, struct tags, HTTP handler, etc
            })
            
            ls.add_snippets('nix', {
              s('req', fmt("local {} = require('{}')", {i(1, 'default'), rep(1)})),
            })

            -- LSP
            local nvim_lsp = require('lspconfig')
            local opts = { silent=true }
            vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
            vim.keymap.set('n', '[d',        vim.diagnostic.goto_prev,  opts)
            vim.keymap.set('n', ']d',        vim.diagnostic.goto_next,  opts)
            vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

            local on_attach = function(client, bufnr)
              o = {silent = true, buffer = bufnr}
              vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
              vim.keymap.set('n', 'gD',         vim.lsp.buf.declaration,                        o)
              vim.keymap.set('n', 'gd',         vim.lsp.buf.definition,                         o)
              vim.keymap.set('n', 'gi',         vim.lsp.buf.implementation,                     o)
              vim.keymap.set('n', 'gr',         vim.lsp.buf.references,                         o)
              vim.keymap.set('n', 'K',          vim.lsp.buf.hover,                              o)
              vim.keymap.set('n', '<C-k>',      vim.lsp.buf.signature_help,                     o)
              vim.keymap.set('n', '<leader>D',  vim.lsp.buf.type_definition,                    o)
              vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,                             o)
              vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,                        o)
              vim.keymap.set('n', '<leader>f',  function() vim.lsp.buf.format {async=true} end, o)
            end

            -- local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
            for _, ls in ipairs{
              'gopls',
              'rnix',
              'tsserver',
              'tailwindcss',
              'nimls',
              'jedi_language_server',
              'rls',
              'zls'
            } do
              if nvim_lsp[ls] ~= nil then
                nvim_lsp[ls].setup{
                  on_attach = on_attach
                }
              end
            end
            if nvim_lsp['astro'] ~= nil then
              nvim_lsp['astro'].setup{
                on_attach = on_attach,
                init_options = {
                  configuration = {},
                  typescript = {
                    serverPath = "typescript"
                  }
                }
              }
            end
            require'lspconfig'.sumneko_lua.setup {
              settings = {
                Lua = {
                  runtime = {
                    version = 'LuaJIT',
                  },
                  diagnostics = {
                    globals = {'vim'},
                  },
                  workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                  },
                  telemetry = {
                    enable = false,
                  },
                },
              },
            }
            if (nvim_lsp['idris2_lsp'] ~= nil) and (vim.fn.executable('idris2') == 1) then
              require('idris2').setup({
                client = {
                  hover = {
                    use_split         = false,    -- Persistent split instead of popups for hover
                    split_size        = '30%',    -- Size of persistent split, if used
                    auto_resize_split = false,    -- Should resize split to use minimum space
                    split_position    = 'bottom', -- bottom, top, left or right
                    with_history      = false,    -- Show history of hovers instead of only last
                  },
                },
                server = {
                  on_attach = function(...)
                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {silent=true})
                    vim.keymap.set('n', 'K',  vim.lsp.buf.hover,      {silent=true})

                    local ca = require('idris2.code_action')
                    vim.keymap.set('n', '<leader>is', ca.case_split, {silent=true})
                    vim.keymap.set('n', '<leader>ia', ca.add_clause, {silent=true})
                    vim.keymap.set('n', '<leader>ie', ca.expr_search)
                    vim.keymap.set('n', '<leader>id', ca.generate_def)
                    vim.keymap.set('n', '<leader>ir', ca.refine_hole)
                    vim.keymap.set('n', '<leader>mc', ca.make_case)
                    vim.keymap.set('n', '<leader>mw', ca.make_with)
                    vim.keymap.set('n', '<leader>ml', ca.make_lemma)

                    local hover = require('idris2.hover')
                    vim.keymap.set('n', '<leader>so', hover.open_split,  {silent=true})
                    vim.keymap.set('n', '<leader>sc', hover.close_split, {silent=true})

                    local metavars = require('idris2.metavars')
                    vim.keymap.set('n', '<leader>mm', metavars.request_all, {silent=true})
                    vim.keymap.set('n', '<leader>mn', metavars.goto_next,   {silent=true})
                    vim.keymap.set('n', '<leader>mp', metavars.goto_prev,   {silent=true})

                    vim.keymap.set('n', '<leader>x',  require('idris2.repl').evaluate)
                    vim.keymap.set('n', '<leader>ib', require('idris2.browse').browse)
                  end,
                  init_options = {
                    logFile = '~/.cache/idris2-lsp/server.log',
                    longActionTimeout = 2000, -- 2 second
                  },
                },
                autostart_semantic             = true,      -- Should start and refresh semantic highlight automatically
                code_action_post_hook          = function (...) vim.cmd('silent write') end, -- Function to execute after a code action is performed:
                use_default_semantic_hl_groups = true,      -- Set default highlight groups for semantic tokens
              })
            end

            require('null-ls').setup({
              sources = {
                require('null-ls').builtins.diagnostics.statix,
                require('null-ls').builtins.diagnostics.mypy,
                require('null-ls').builtins.formatting.yapf,
              },
            })

            require('femaco').setup()
          '';
        };

        visuals =
          let
            themes = {
              material = {
                plugins = with pkgs.vimPlugins; [ material-nvim ];
                config = luaCfg ''
                  vim.g.material_style = 'deep ocean'
                  require('material').setup({italics = {comments = true}})
                  vim.cmd 'colorscheme material'
                '';
              };
              codedark = {
                plugins = with pkgs.vimPlugins; [ vim-code-dark ];
                config = luaCfg ''
                  vim.g.codedark_italics = true
                  vim.cmd 'colorscheme codedark'
                '';
              };
              kanagawa = {
                plugins = with pkgs.vimPlugins; [ kanagawa-nvim ];
                config = luaCfg ''
                  vim.cmd 'colorscheme kanagawa'
                '';
              };
            };
            theme = themes.kanagawa;
          in
          {
            plugins = [ ] ++ theme.plugins;
            config = luaCfg ''
              vim.opt.colorcolumn    = '100'
              vim.opt.cursorline     = true
              vim.opt.number         = true
              vim.opt.relativenumber = true
              vim.opt.splitright     = true
              vim.opt.splitbelow     = true
              vim.opt.scrolloff      = 7
              vim.opt.termguicolors  = true      --  24-bit RGB colors
            '' + theme.config;
          };

        extra = {
          plugins = [ pkgs.neovimPlugins.extra_config ];
          config = luaCfg ''
            vim.g.mapleader = ' '
            --[[                            Behaviour                       ]]--
            vim.opt.mouse       = 'a'           -- enable mouse
            vim.opt.encoding    = 'utf-8'
            vim.opt.swapfile    = false
            vim.opt.tabstop     = 4
            vim.opt.softtabstop = 4
            vim.opt.shiftwidth  = 4
            vim.opt.expandtab   = true
            vim.opt.autoindent  = true
            vim.opt.fileformat  = 'unix'
            vim.cmd('filetype indent on')       -- load filetype-specific indent files
          '';
        };
      };
      makeNeovim = modules:
        let
          dependencies = builtins.concatLists (map (x: x.extraPackages or [ ]) modules);
          wrappedNeovim = pkgs.wrapNeovim pkgs.neovim-unwrapped {
            withPython3 = false;
            withRuby = false;
            withNodeJs = false;
            configure = {
              customRC = builtins.concatStringsSep "\n" (map (x: x.config or "") modules);
              packages.qux.start = builtins.concatLists (map (x: x.plugins or [ ]) modules);
              # TODO
              packages.qux.opt = [ ];
            };
          };
        in
        pkgs.symlinkJoin {
          name = "neovim";
          paths = [ wrappedNeovim ] ++ dependencies;
        };
    in
    rec {
      packages = {
        neovim = makeNeovim (with plugins; [ extra visuals utils code ]);
      };
      defaultPackage = packages.neovim;
    }
  );
}
