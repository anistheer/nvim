-- Basic settings
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = true   -- Show relative line numbers
vim.opt.mouse = 'a'            -- Enable mouse support
vim.opt.ignorecase = true      -- Case insensitive searching
vim.opt.smartcase = true       -- Case sensitive if capital letter is present
vim.opt.hlsearch = true        -- Highlight search results
vim.opt.wrap = false           -- Don't wrap lines
vim.opt.breakindent = true     -- Indent wrapped lines
vim.opt.tabstop = 2            -- Number of spaces that a <Tab> counts for
vim.opt.shiftwidth = 2         -- Number of spaces to use for each step of (auto)indent
vim.opt.expandtab = true       -- Use spaces instead of tabs
vim.opt.smartindent = true     -- Smart autoindenting
vim.opt.termguicolors = true   -- Enable true color support
vim.opt.scrolloff = 8          -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8      -- Keep 8 characters left/right of cursor
vim.opt.updatetime = 50        -- Faster completion
vim.opt.signcolumn = "yes"     -- Always show the sign column
vim.opt.fileformat = "unix"    -- Use LF line endings
vim.opt.fileformats = "unix,dos" -- Prefer Unix line endings, fallback to DOS

-- Better command line completion
vim.opt.wildmenu = true        -- Enable wildmenu
vim.opt.wildmode = "longest:full,full"  -- Complete longest common string, then each full match
vim.opt.wildignorecase = true  -- Ignore case when completing file names
vim.opt.wildignore = "*.o,*.obj,*.bak,*.exe,*.pyc,*.jpg,*.gif,*.png"  -- Ignore these files
vim.opt.wildoptions = "pum"    -- Use popup menu style with up/down arrows

-- Enable syntax highlighting
vim.cmd('syntax on')
vim.cmd('filetype on')
vim.cmd('filetype plugin on')
vim.cmd('filetype indent on')
vim.cmd('colorscheme default')

vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    vim.bo.syntax = "lua"
  end
})

-- Set leader key to space
vim.g.mapleader = " "

-- Key mappings
local map = vim.keymap.set

-- NvimTree
map('n', '<leader>e', ':NvimTreeToggle<CR>')  -- Toggle NvimTree

-- Better window navigation
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- Clear search highlights
map('n', '<leader>h', ':nohlsearch<CR>')

-- Save file
map('n', '<leader>w', ':write<CR>')

-- Quit
map('n', '<leader>q', ':quit<CR>')

-- Plugin management (using lazy.nvim)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Initialize lazy.nvim
require("lazy").setup({
  -- Theme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        respect_buf_cwd = true,
        update_focused_file = {
          enable = true,
          update_cwd = true
        },
        renderer = {
          icons = {
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
            },
          },
        },
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup()
    end,
  },

  -- LSP Support
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      -- Setup nvim-cmp
      local cmp = require('cmp')
      local cmp_lsp = require('cmp_nvim_lsp')
      
      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
          { name = 'cmdline' },
        }),
        formatting = {
          format = function(entry, vim_item)
            vim_item.kind = string.format('%s %s', vim_item.kind, entry.source.name)
            return vim_item
          end
        },
        experimental = {
          ghost_text = true,
        },
      })

      -- Setup cmdline completion
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' },
          { name = 'cmdline' },
        })
      })

      -- Setup search completion
      cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })

      -- Setup LSP
      local capabilities = cmp_lsp.default_capabilities()
      local lspconfig = require('lspconfig')

      -- TypeScript/JavaScript LSP
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- Enable inlay hints
          client.server_capabilities.inlayHintProvider = true
        end,
      })

      -- ESLint LSP
      lspconfig.eslint.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- Enable format on save
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        end,
      })

      -- Key mappings for LSP
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = 0 })
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = 0 })
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = 0 })
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = 0 })
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = 0 })
      vim.keymap.set('n', '<leader>f', function()
        vim.lsp.buf.format({ async = true })
      end, { buffer = 0 })
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup()
    end,
  },

  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, {expr=true})

          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, {expr=true})
        end
      })
    end,
  },

  -- LazyGit integration
  {
    "kdheepak/lazygit.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      vim.keymap.set("n", "<leader>gg", ":LazyGit<CR>", { silent = true })
    end,
  },

  -- Commenting
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup({
        indent = {
          char = "│",
        },
        scope = {
          enabled = true,
          show_start = true,
          show_end = true,
        },
      })
    end,
  },

  -- Language mapping for Russian keyboard
  {
    "Wansmer/langmapper.nvim",
    lazy = false,
    priority = 1, -- Load before other plugins
    config = function()
      require('langmapper').setup({
        -- Default mapping mode
        default_mapping_mode = 'n',
        -- Russian layout mapping
        mappings = {
          n = {
            ['ф'] = 'a',
            ['и'] = 'b',
            ['с'] = 'c',
            ['в'] = 'd',
            ['у'] = 'e',
            ['а'] = 'f',
            ['п'] = 'g',
            ['р'] = 'h',
            ['ш'] = 'i',
            ['о'] = 'j',
            ['л'] = 'k',
            ['д'] = 'l',
            ['ь'] = 'm',
            ['т'] = 'n',
            ['щ'] = 'o',
            ['з'] = 'p',
            ['й'] = 'q',
            ['к'] = 'r',
            ['ы'] = 's',
            ['е'] = 't',
            ['г'] = 'u',
            ['м'] = 'v',
            ['ц'] = 'w',
            ['ч'] = 'x',
            ['н'] = 'y',
            ['я'] = 'z',
            ['Ф'] = 'A',
            ['И'] = 'B',
            ['С'] = 'C',
            ['В'] = 'D',
            ['У'] = 'E',
            ['А'] = 'F',
            ['П'] = 'G',
            ['Р'] = 'H',
            ['Ш'] = 'I',
            ['О'] = 'J',
            ['Л'] = 'K',
            ['Д'] = 'L',
            ['Ь'] = 'M',
            ['Т'] = 'N',
            ['Щ'] = 'O',
            ['З'] = 'P',
            ['Й'] = 'Q',
            ['К'] = 'R',
            ['Ы'] = 'S',
            ['Е'] = 'T',
            ['Г'] = 'U',
            ['М'] = 'V',
            ['Ц'] = 'W',
            ['Ч'] = 'X',
            ['Н'] = 'Y',
            ['Я'] = 'Z',
            ['.'] = '/',
            [','] = 'm',
            ['ж'] = ';',
            ['Ж'] = ':',
            ['э'] = "'",
            ['Э'] = '"',
            ['ю'] = '.',
            ['Ю'] = '>',
            ['б'] = ',',
            ['Б'] = '<',
            ['х'] = '[',
            ['Х'] = '{',
            ['ъ'] = ']',
            ['Ъ'] = '}',
          }
        }
      })
    end
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  { -- optional cmp completion source for require statements and module annotations
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-path",
    },
    opts = function(_, opts)
      local cmp = require('cmp')
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "lazydev",
        group_index = 0, -- set group index to 0 to skip loading LuaLS completions
      })

      -- Setup cmdline completion
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' },
          { name = 'cmdline' },
        })
      })
    end,
  },
  { -- optional blink completion source for require statements and module annotations
    "saghen/blink.cmp",
    version = '1.*',
    opts = {
      sources = {
        -- add lazydev to your completion providers
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
    },
  }
}) 
