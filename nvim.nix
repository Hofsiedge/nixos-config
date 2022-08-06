pkgs:

let
  # commonLets = {
  #   ".*^map\(.*" = "let map = vim.api.nvim_set_keymap";
  # };
  # luaCfg = s: ''
  #   lua << EOF
  # '' + (map (k: ) commonLets)) + s + ''
  # EOF
  # '';

  luaCfg = s: ''
    lua << EOF
    local map = vim.api.nvim_set_keymap
  '' + s + "EOF";

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
        require'nvim-tree'.setup{
        --[[
          renderer.icons.glyphs = {
            folder = {
              default = '▸',
              open    = '▾'
            }
          }
        ]]--
        }
      '';
    }
      nvim-web-devicons];
    hop = {
      plugin = hop-nvim;
      config = luaCfg ''
        require'hop'.setup{}
        vim.api.nvim_set_keymap("n", '<leader> w', "<cmd>HopWord<cr>", {})
        vim.api.nvim_set_keymap("n", '<leader> c', "<cmd>HopChar1<cr>", {})
        vim.api.nvim_set_keymap("n", '<leader> /', "<cmd>HopPattern<cr>", {})
      '';
    };
    telescopeBundle = [
      plenary-nvim
      {
        plugin = telescope-nvim;
        config = luaCfg ''
          vim.api.nvim_set_keymap("n", '<leader>ff', '<cmd>Telescope find_files<cr>', {})
          vim.api.nvim_set_keymap("n", '<leader>fg', '<cmd>Telescope live_grep<cr>', {})
          vim.api.nvim_set_keymap("n", '<leader>fb', '<cmd>Telescope buffers<cr>', {})
          vim.api.nvim_set_keymap("n", '<leader>fh', '<cmd>Telescope help_tags<cr>', {})
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
          nvimKeymap = { k, v }: "vim.api.nvim_buf_set_keymap(bufnr, 'n', '" + k
            + "', '<cmd>lua vim.lsp.buf." + v + "()<CR>', opts)";
          keymaps = builtins.map (k: nvimKeymap { k = k; v = builtins.getAttr k mappings; })
            (builtins.attrNames mappings);
          onAttach = ''
            local on_attach = function(client, bufnr)
              vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
          '' + (builtins.concatStringsSep "\n" keymaps) + ''

          end
        '';
        in
        luaCfg (''
          local nvim_lsp = require('lspconfig')
          local opts = { noremap=true, silent=true }
          vim.api.nvim_set_keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
          vim.api.nvim_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
          vim.api.nvim_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
          vim.api.nvim_set_keymap('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
        '' + onAttach + ''
          -- local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
          for _, ls in ipairs{
            'gopls',
            'tsserver',
            'rnix',
            'zls',
            'tailwindcss',
            'nimls',
            'pyright',
            'rls'
          } do
            if nvim_lsp[ls] ~= nil then
              nvim_lsp[ls].setup{
                on_attach = on_attach
              }
            end
          end
        '');
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
          s('tt', fmt("// {} {}\ntype {} {} {{\n\t{}\n}}\n\n", {rep(1), i(0, 'TODO: description'), i(1, 'name'), c(2, {t('struct'), t('interface')}), i(3, 'body')})),
          -- TODO: for, function, test, if err, return default, log, embed, struct tags, HTTP handler, etc
        })
        
        ls.add_snippets('nix', {
          s('req', fmt("local {} = require('{}')", { i(1, 'default'), rep(1)})),
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

    _nvimDap = {
      plugin = nvim-dap;
      config = ''
        nnoremap <silent> <F5>       <Cmd>lua require'dap'.continue()<CR>
        nnoremap <silent> <F10>      <Cmd>lua require'dap'.step_over()<CR>
        nnoremap <silent> <F11>      <Cmd>lua require'dap'.step_into()<CR>
        nnoremap <silent> <F12>      <Cmd>lua require'dap'.step_out()<CR>
        nnoremap <silent> <Leader>db <Cmd>lua require'dap'.toggle_breakpoint()<CR>
        nnoremap <silent> <Leader>dB <Cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '), nil, vim.fn.input('Log point message: '))<CR>
        nnoremap <silent> <Leader>dr <Cmd>lua require'dap'.repl.open()<CR>
        nnoremap <silent> <Leader>dl <Cmd>lua require'dap'.run_last()<CR>
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
      config = ''
        lua require'dap-go'.setup()
        nnoremap <silent> <leader>dt :lua require('dap-go').debug_test()<CR>
      '';
    };
    _nvimDapUi = {
      plugin = nvim-dap-ui;
      config = luaCfg ''
        require'dapui'.setup()
        local opts = { noremap=true, silent=true }
        vim.api.nvim_set_keymap('n', '<leader>di', '<cmd>lua require"dapui".toggle()<CR>', opts)
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
    code.treeSitter
    code.hexokinase
  ] ++ utils.nvimTreeBundle
  ++ code.cmpBundle
  ++ code.dapBundle
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
    ]]
    --[[ neovide ]]--
    g.neovide_fullscreen = true
    -- This doesn't work for some reason
    -- g.guifont            = "FiraCode Nerd Font:h16"
  '';
}
