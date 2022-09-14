pkgs:

let
  luaCfg = s: ''
    lua << EOF
    local map = vim.api.nvim_set_keymap
    ${s}
    EOF
  '';

  themes = with pkgs.vimPlugins; {
    tender = {
      plugin = tender-vim;
      config = ''
        colorscheme tender
      '';
    };
    codedark = {
      plugin = vim-code-dark;
      config = ''
        let g:codedark_italics = 1
        colorscheme codedark
      '';
    };
  };

  utils = with pkgs.vimPlugins; {
    easyAlign = {
      plugin = easy-align;
      config = luaCfg ''
        map('x', '<leader>a', '<Plug>(EasyAlign)', {})
        map('n', '<leader>a', '<Plug>(EasyAlign)', {})
      '';
    };
    nvimTreeBundle = [{
      plugin = nvim-tree-lua;
      config = luaCfg ''
        -- TODO: git
        map('n', '<C-n>', ':NvimTreeToggle<CR>', {noremap = true, silent = true})
        require'nvim-tree'.setup{}
      '';
    }
      nvim-web-devicons];
    hop = {
      plugin = hop-nvim;
      config = luaCfg ''
        require'hop'.setup{}
        map("n", '<leader> w', "<cmd>HopWord<cr>", {})
        map("n", '<leader> c', "<cmd>HopChar1<cr>", {})
        map("n", '<leader> /', "<cmd>HopPattern<cr>", {})
      '';
    };
    telescopeBundle = [
      plenary-nvim
      {
        plugin = telescope-nvim;
        config = luaCfg ''
          map("n", '<leader>ff', '<cmd>Telescope find_files<cr>', {})
          map("n", '<leader>fg', '<cmd>Telescope live_grep<cr>', {})
          map("n", '<leader>fb', '<cmd>Telescope buffers<cr>', {})
          map("n", '<leader>fh', '<cmd>Telescope help_tags<cr>', {})
        '';
      }
    ];
  };

  code = with pkgs.vimPlugins; rec {
    lspConfig = {
      plugin = nvim-lspconfig;
      config =
        let
          mappings = {
            gD = "declaration";
            gd = "definition";
            gi = "implementation";
            gr = "references";
            K = "hover";
            "<C-k>" = "signature_help";
            "<leader>D" = "type_definition";
            "<leader>rn" = "rename";
            "<leader>ca" = "code_action";
            "<leader>f" = "formatting";
          };
          nvimKeymap = { k, v }: "vim.api.nvim_buf_set_keymap(bufnr, 'n', '${k}'," +
            " '<cmd>lua vim.lsp.buf.${v}()<CR>', opts)";
          keymaps = builtins.map
            (k: nvimKeymap { inherit k; v = builtins.getAttr k mappings; })
            (builtins.attrNames mappings);
          onAttach = ''
            local on_attach = function(client, bufnr)
              vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
              ${builtins.concatStringsSep "\n" keymaps}
            end
          '';
        in
        luaCfg (''
          local nvim_lsp = require('lspconfig')
          local opts = { silent=true }
          vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
          vim.keymap.set('n', '[d',        vim.diagnostic.goto_prev,  opts)
          vim.keymap.set('n', ']d',        vim.diagnostic.goto_next,  opts)
          vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
        '' + onAttach + ''
          -- local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
          for _, ls in ipairs{
            'gopls',
            'rnix',
            'tsserver',
            'tailwindcss',
            'astro',
            'nimls',
            'pyright',
            'rls',
            'zls'
          } do
            if nvim_lsp[ls] ~= nil then
              nvim_lsp[ls].setup{
                on_attach = on_attach
              }
            end
          end
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
                  logFile = "~/.cache/idris2-lsp/server.log",
                  longActionTimeout = 2000, -- 2 second
                },
              },
              autostart_semantic             = true,      -- Should start and refresh semantic highlight automatically
              code_action_post_hook          = function (...) vim.cmd('silent write') end, -- Function to execute after a code action is performed:
              use_default_semantic_hl_groups = true,      -- Set default highlight groups for semantic tokens
            })
          end
        '');
    };
    # TODO: depends on plenary-nvim. Add dependency resolution system
    # works fine at the moment due to Telescope depending on plenary as well
    null-ls = {
      plugin = null-ls-nvim;
      config = luaCfg ''
        require("null-ls").setup({
          sources = {
            require("null-ls").builtins.diagnostics.statix,
          },
        })
      '';
    };
    _luaSnip = {
      plugin = luasnip;
      # FIXME
      config = luaCfg ''
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
        
        
        vim.api.nvim_create_autocmd({"BufWritePre"}, {
            pattern = { "*.go" },
            callback = vim.lsp.buf.formatting_sync
        })
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
            pattern = {"*.nim"},
            command = "set ft=nim"
        })
        
        ls.add_snippets('go', {
          s('tt', fmt("// {} {}\ntype {} {} {{\n\t{}\n}}\n\n",
            {rep(1), i(0, 'TODO: description'), i(1, 'name'), c(2, {t('struct'), t('interface')}), i(3, 'body')})),
          -- TODO: for, function, test, if err, return default, log, embed, struct tags, HTTP handler, etc
        })
        
        ls.add_snippets('nix', {
          s('req', fmt("local {} = require('{}')", {i(1, 'default'), rep(1)})),
        })
      '';
    };
    _nvimCmp = {
      plugin = nvim-cmp;
      config = ''
        set completeopt=menu,menuone,noselect 
      '' + luaCfg ''
        -- Setup nvim-cmp.
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
      '';
    };
    cmpBundle = [
      lspkind-nvim
      cmp-buffer
      cmp-nvim-lsp
      cmp-path
      cmp_luasnip
      _nvimCmp
      _luaSnip
    ];
    idris2-nvim = [
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "idris2-nvim";
          src = pkgs.fetchFromGitHub {
            owner = "ShinKage";
            repo = "idris2-nvim";
            rev = "dc211b56157d9ecf5edfdf3c8d7e98d17a86911b";
            sha256 = "9HVuWGpiQba2R8u4NEbGWwJTTrpvYXFnNTJRp+FY9ko=";
          };
        };
        config = luaCfg ''
        '';
      }
      pkgs.vimPlugins.nui-nvim
    ];

    _nvimDap = {
      plugin = nvim-dap;
      config = luaCfg ''
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
      '';
    };
    _nvimDapGo = {
      plugin = pkgs.vimUtils.buildVimPlugin {
        name = "dap-go";
        src = pkgs.fetchFromGitHub {
          owner = "leoluz";
          repo = "nvim-dap-go";
          rev = "fca8bf90bf017e8ecb3a3fb8c3a3c05b60d1406d";
          sha256 = "ZbQw4244BLiSoBipiPc1eEF2aV3BJLT7W8LmBl8xH4Q=";
        };
      };
      config = luaCfg ''
        require'dap-go'.setup()
        vim.keymap.set('n', '<leader>dt', require('dap-go').debug_test, {silent=true})
      '';
    };
    _nvimDapUi = {
      plugin = nvim-dap-ui;
      config = luaCfg ''
        require'dapui'.setup()
        local opts = { noremap=true, silent=true }
        map('n', '<leader>di', '<cmd>lua require"dapui".toggle()<CR>', opts)
      '';
    };
    _nvimDapVT = {
      plugin = nvim-dap-virtual-text;
      config = luaCfg ''
        require("nvim-dap-virtual-text").setup()
      '';
    };
    dapBundle = [ _nvimDap _nvimDapGo _nvimDapUi _nvimDapVT ];
    treeSitter = {
      plugin = nvim-treesitter.withPlugins (plugins: with pkgs.tree-sitter-grammars; [
        tree-sitter-go
        tree-sitter-gomod # tree-sitter-gowork
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
        # tree-sitter-vim
        # pkgs.vimUtils.buildVimPlugin {
        #   name = "tree-sitter-astro";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "virchau13";
        #     repo = "tree-sitter-astro";
        #     rev = "ec0f9f945a08372952403f736a1f783d1679b0ac";
        #     sha256 = "AAA";
        #   };
        # }
      ]);
      config = (luaCfg ''
        require'nvim-treesitter.configs'.setup {
          highlight = {
            -- `false` will disable the whole extension
            enable = true,
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
        }
      '') + ''

        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
      '';
    };
    treeSitterPlayground = {
      plugin = playground;
      config = luaCfg ''
        require "nvim-treesitter.configs".setup {
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
      '';
    };
    hexokinase = { plugin = vim-hexokinase; };
  };

in
{
  enable = true;
  vimAlias = true;
  withRuby = false;
  withPython3 = false;
  plugins = [
    themes.codedark
    utils.easyAlign
    utils.hop
    code.lspConfig
    code.null-ls
    code.treeSitter
    code.treeSitterPlayground
    code.hexokinase
  ] ++ utils.nvimTreeBundle
  ++ code.cmpBundle
  ++ code.dapBundle
  ++ code.idris2-nvim
  ++ utils.telescopeBundle;
  extraPackages = with pkgs; [
    gopls
    # telescope dependencies
    ripgrep
    fd
  ];
  extraConfig = ''
    nnoremap <SPACE> <Nop>
    map <Space> <Leader>

    set guifont=FiraCode\ Nerd\ Font:h16
  '' + luaCfg ''
    local cmd  = vim.cmd           -- execute Vim commands
    local exec = vim.api.nvim_exec -- execute Vimscript
    local g    = vim.g             -- global variables
    local opt  = vim.opt           -- global/buffer/windows-scoped options
  
  
    --[[                            Behaviour                       ]]--
  
    opt.mouse       = 'a'           -- enable mouse
    opt.encoding    = 'utf-8'
    opt.swapfile    = false
    opt.tabstop     = 4
    opt.softtabstop = 4
    opt.shiftwidth  = 4
    opt.expandtab   = true
    opt.autoindent  = true
    opt.fileformat  = 'unix'
    cmd('filetype indent on')       -- load filetype-specific indent files
  
  
    --[[                            VISUALS                         ]]--
  
    opt.colorcolumn    = '100'
    opt.cursorline     = true
    opt.number         = true
    opt.relativenumber = true
    opt.splitright     = true
    opt.splitbelow     = true
    opt.scrolloff      = 7
    opt.termguicolors  = true      --  24-bit RGB colors
  
    --[[ augroups ]]--
    vim.cmd [[
        autocmd FileType python          setlocal indentkeys-=<:>
        autocmd FileType python          setlocal indentkeys-=:
        autocmd FileType css             setlocal tabstop=2 shiftwidth=2 expandtab
        autocmd FileType typescriptreact setlocal tabstop=2 shiftwidth=2 expandtab
        autocmd FileType nix             setlocal tabstop=2 shiftwidth=2 expandtab

        autocmd BufNewFile,BufRead *.astro set filetype=astro
    ]]
    --[[ neovide ]]--
    g.neovide_fullscreen = true
    -- This doesn't work for some reason
    -- g.guifont            = "FiraCode Nerd Font:h16"
  '';
}
