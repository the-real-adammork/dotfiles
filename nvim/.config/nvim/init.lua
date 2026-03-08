-- Neovim Lua Config
-- Migrated from init.vim

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  -- Colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        auto_integrations = true,
      })
      vim.opt.background = "light"
      vim.cmd.colorscheme("catppuccin-latte")
    end,
  },

  -- File tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        filesystem = {
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
      })
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin",
          section_separators = "",
          component_separators = "",
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            "branch",
            "diagnostics",
          },
          lualine_c = {
            "filename",
            {
              function()
                local reg = vim.fn.reg_recording()
                if reg ~= "" then return "recording @" .. reg end
                return ""
              end,
              color = { fg = "#d20f39" },
            },
          },
          lualine_x = {
            "searchcount",
            {
              function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients == 0 then return "" end
                local names = {}
                for _, c in ipairs(clients) do
                  table.insert(names, c.name)
                end
                return " " .. table.concat(names, ", ")
              end,
            },
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- Winbar breadcrumbs
  {
    "Bekaboo/dropbar.nvim",
    opts = {},
  },

  -- Motion
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  -- Surround (cs, ds, ys — same keybinds as vim-surround)
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  -- Fuzzy finder
  -- TODO: consider nvim-spectre for dedicated search-and-replace UI
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    },
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()
      require("nvim-treesitter").install({
        "bash", "css", "dockerfile", "go", "html", "javascript", "json",
        "kotlin", "lua", "markdown", "markdown_inline", "nginx", "python",
        "rust", "sql", "swift", "tsx", "typescript", "vim", "vimdoc", "yaml",
      })
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          if pcall(vim.treesitter.start) then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- LSP installer
  {
    "williamboman/mason.nvim",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "pyright", "ts_ls", "jsonls", "html", "cssls", "rust_analyzer",
        "kotlin_language_server", "sqls", "marksman", "dockerls",
        "bashls", "gopls", "lua_ls",
      },
      automatic_installation = true,
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        -- Formatters
        "prettier",
        "black",
        "ruff",
        "stylua",
        "shfmt",
        "sql-formatter",
        "ktlint",
      },
    },
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      -- Global config for all LSP servers
      vim.lsp.config("*", {
        root_markers = { ".git" },
      })

      -- Server-specific config
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
          },
        },
      })

      -- Enable all LSP servers
      vim.lsp.enable({
        "pyright", "ts_ls", "jsonls", "html", "cssls", "sourcekit",
        "rust_analyzer", "kotlin_language_server", "sqls", "marksman",
        "dockerls", "bashls", "gopls", "lua_ls",
      })

      -- LSP keybindings
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })
    end,
  },

  -- Completion
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      keymap = { preset = "default" },
      sources = {
        default = { "lsp", "path", "buffer" },
      },
    },
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python = { "ruff_format", "black", stop_after_first = true },
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          json = { "prettier" },
          html = { "prettier" },
          css = { "prettier" },
          markdown = { "prettier" },
          rust = { "rustfmt" },
          go = { "gofmt", "goimports" },
          lua = { "stylua" },
          swift = { "swiftformat" },
          kotlin = { "ktlint" },
          sql = { "sql_formatter" },
          bash = { "shfmt" },
          sh = { "shfmt" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_format = "fallback",
        },
      })
    end,
  },

  -- TODO: investigate debugging plugins (nvim-dap, nvim-dap-ui)
  -- TODO: investigate testing plugins (neotest)
}, {
  ui = {
    border = "rounded",
  },
})

-- Floating window borders for LSP and diagnostics
vim.diagnostic.config({ float = { border = "rounded" } })
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

-- Settings
vim.opt.colorcolumn = "100"
vim.opt.confirm = true
vim.opt.startofline = false

-- Keymaps
vim.keymap.set("n", "<leader>confe", "<cmd>e $MYVIMRC<cr>", { desc = "Edit config" })
vim.keymap.set("n", "<leader>confr", "<cmd>source $MYVIMRC<cr>", { desc = "Reload config" })

-- Quick save
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>update<cr>", { desc = "Save file" })
vim.keymap.set("n", "<leader>s", "<cmd>update<cr>", { desc = "Save file" })

-- Center screen after search jumps
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "*", "*zz")
vim.keymap.set("n", "#", "#zz")
vim.keymap.set("n", "g*", "g*zz")
vim.keymap.set("n", "g#", "g#zz")

-- File tree
vim.keymap.set("n", ",n", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })
vim.keymap.set("n", ",nf", "<cmd>Neotree reveal<cr>", { desc = "Find file in tree" })
vim.keymap.set("n", "<leader>v", "<cmd>Neotree reveal<cr>", { desc = "Find file in tree" })

-- Navigate between splits
vim.keymap.set("n", "<C-h>", "<C-w><C-h>")
vim.keymap.set("n", "<C-j>", "<C-w><C-j>")
vim.keymap.set("n", "<C-k>", "<C-w><C-k>")
vim.keymap.set("n", "<C-l>", "<C-w><C-l>")

-- Buffer switching
vim.keymap.set("n", "<leader>[", "<cmd>bp<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>]", "<cmd>bn<cr>", { desc = "Next buffer" })

-- Clear search highlights with Esc
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Tab navigation
vim.keymap.set("n", "{", "gT", { desc = "Previous tab" })
vim.keymap.set("n", "}", "gt", { desc = "Next tab" })
vim.keymap.set("n", "+", "<cmd>tabnew<cr>", { desc = "New tab" })

-- Toggle wrap
vim.keymap.set("n", "<leader>w", function()
  if vim.wo.wrap then
    print("Wrap OFF")
    vim.wo.wrap = false
  else
    print("Wrap ON")
    vim.wo.wrap = true
    vim.wo.linebreak = true
  end
end, { desc = "Toggle wrap" })

-- Move by visual line when wrapped (but actual line with count)
vim.keymap.set("n", "j", "v:count ? 'j' : 'gj'", { expr = true })
vim.keymap.set("n", "k", "v:count ? 'k' : 'gk'", { expr = true })

-- Paste without overwriting register
vim.keymap.set("x", "p", function()
  return 'pgv"' .. vim.v.register .. "y"
end, { expr = true })

-- Search for visually selected text
vim.keymap.set("v", "//", "y/\\V<C-R>=escape(@\",'/\\\\')<CR><CR>")

-- Show cursorline only in insert mode
vim.api.nvim_create_autocmd("InsertEnter", { callback = function() vim.opt.cursorline = true end })
vim.api.nvim_create_autocmd("InsertLeave", { callback = function() vim.opt.cursorline = false end })

-- Disable backup and swap files
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- UI
vim.opt.wildignore = "*.dll,*.o,*.obj,*.bak,*.exe,*.pyc,*.swp,*.jpg,*.gif,*.png"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.lazyredraw = true
vim.opt.whichwrap:append("<,>,h,l")
vim.opt.shortmess = "atI"
vim.opt.report = 0

-- Clipboard
vim.opt.clipboard = "unnamedplus"
local paste_orig = vim.paste
vim.paste = function(lines, phase)
  if not vim.bo.modifiable then return false end
  return paste_orig(lines, phase)
end

-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.copyindent = true

-- Text formatting
vim.opt.formatoptions = "tcrq"
vim.opt.shiftround = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.preserveindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- vim.opt.cursorcolumn = true

-- Folding (treesitter-based, but don't auto-fold)
vim.opt.foldenable = true
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99

-- Visual cues
vim.opt.showmatch = true
vim.opt.matchtime = 5
vim.opt.hlsearch = true
vim.opt.scrolloff = 5

-- Toggle hybrid line numbers
vim.keymap.set("n", "<leader>h", function()
  vim.opt.number = not vim.o.number
  vim.opt.relativenumber = not vim.o.relativenumber
end, { desc = "Toggle hybrid line numbers" })

-- Open Neo-tree on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    require("neo-tree.command").execute({ action = "show" })
  end,
})
