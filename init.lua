-------------------- this can be removed if you have v0.10.4 -------------------------

-- see https://github.com/neovim/neovim/issues/31675

local version = vim.version()

if version.major == 0 and version.minor == 10 and version.patch == 3 then
	vim.hl = vim.highlight
end

--------------------------------------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smarttab = true
vim.opt.shiftround = true

vim.opt.signcolumn = "yes"

require("lazy").setup({
	spec = {

		-- colorscheme
		{
			"0xstepit/flow.nvim",
			lazy = false,
			priority = 1000,
			version = "v2",
			opts = {
				theme = { contrast = "high" },
				colors = { fluo = "pink" },
			},
			config = function(_, opts)
				require("flow").setup(opts)
				vim.cmd("colorscheme flow")
			end,
		},

		-- treesitter (language parsing)
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",

			event = { "BufReadPost", "BufWritePost", "BufNewFile", "VeryLazy" },

			opts = {
				ensure_installed = { "c", "lua", "luadoc", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
				highlight = { enable = true },
			},

			config = function(_, opts)
				require("nvim-treesitter.configs").setup(opts)
			end,
		},

		-- autocompletion
		{
			"saghen/blink.cmp",
			dependencies = "rafamadriz/friendly-snippets",

			event = "InsertEnter",

			version = "*",

			---@module "blink.cmp"
			---@type blink.cmp.Config
			opts = {
				keymap = { preset = "default" },

				appearance = {
					use_nvim_cmp_as_default = true,
					nerd_font_variant = "mono",
				},

				sources = {
					default = { "lsp", "path", "snippets", "buffer" },
				},
			},
		},

		-- note: you can nest plugin specs
		{
			-- updates LuaLS workspace libraries to include Neovim files
			{
				"folke/lazydev.nvim",
				ft = "lua",
				opts = {
					library = {
						{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
					},
				},
			},

			{
				"saghen/blink.cmp",

				---Extend `opts` table
				---`opts` can be a function that modifies an existing table
				---@param opts blink.cmp.Config
				opts = function(_, opts)
					---@diagnostic disable-next-line: param-type-mismatch
					opts.sources.default = vim.list_extend({ "lazydev" }, opts.sources.default or {})

					opts.sources.providers = vim.tbl_extend("force", opts.sources.providers or {}, {
						lazydev = {
							name = "LazyDev",
							module = "lazydev.integrations.blink",
							score_offset = 100,
						},
					})
				end,
			},
		},

		-- dev tool installer
		{
			"williamboman/mason.nvim",
			dependencies = {
				"williamboman/mason-lspconfig.nvim",
				"WhoIsSethDaniel/mason-tool-installer.nvim",
			},
			event = "VeryLazy",
			opts = {
				mason = {},
				installer = {
					ensure_installed = {
						-- lua
						"lua_ls",
						"stylua",

						-- -- go
						-- "gopls",
						-- "gofumpt",
					},
				},
			},
			config = function(_, opts)
				require("mason").setup(opts.mason)
				require("mason-lspconfig").setup()
				require("mason-tool-installer").setup(opts.installer)
			end,
		},

		-- LSP support
		{
			"neovim/nvim-lspconfig",
			dependencies = {
				"saghen/blink.cmp",
				"williamboman/mason.nvim",
				"williamboman/mason-lspconfig.nvim",
			},
			event = { "BufReadPre", "BufNewFile", "VeryLazy" },
			opts = {
				servers = {
					lua_ls = {},
					-- gopls = {},
				},
			},
			config = function(_, opts)
				local lspconfig = require("lspconfig")
				for server, config in pairs(opts.servers) do
					config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
					lspconfig[server].setup(config)
				end
			end,
		},

		-- formatting
		{
			"stevearc/conform.nvim",
			event = { "BufWritePre" },
			opts = {
				formatters_by_ft = {
					lua = { "stylua" },
					-- go = { "gofumpt" },
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_format = "fallback",
				},
			},
			config = function(_, opts)
				require("conform").setup(opts)
			end,
		},

		{
			"folke/snacks.nvim",
			lazy = false,
			priority = 1000,

			---@type snacks.Config
			---@diagnostic disable-next-line: missing-fields
			opts = {
				dashboard = { enabled = true },

				-- fuzzy finder
				-- alternatives:
				--    ibhagwan/fzf-lua
				--    nvim-telescope/telescope.nvim
				picker = { enabled = true },
			},

      -- stylua: ignore
			keys = {
				{ "<leader>ff", function() require("snacks").picker.files() end, mode = "n", desc = "Find Files" },
				{ "<leader>fr", function() require("snacks").picker.recent() end, mode = "n", desc = "Recent Files" },
			},
		},

		-- autopairs
		-- alternatives:
		--    mini.pairs
		--    | echasnovski/mini.nvim (main repo)
		--    | echasnovski/mini.pairs (standalone)
		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			opts = {},
		},

		{
			"echasnovski/mini.icons",
			lazy = true,
			opts = {},
			config = function(_, opts)
				require("mini.icons").setup(opts)
				MiniIcons.mock_nvim_web_devicons() -- for extra compatibility. See :h MiniIcons.mock_nvim_web_devicons()
			end,
		},
	},

	install = { colorscheme = { "flow", "default" } },
	checker = { enabled = true },
})

-- other useful plugins:
--
-- honestly just have a look in mini.nvim or snacks.nvim, usually a good starting point
--
-- echasnovski/mini.ai > better text objects
-- echasnovski/mini.surround > add, change, delete surroundings, e.g. speech marks, brackets etc
-- folke/which-key.nvim > menu to show you available keymaps

-- keymaps

local set = vim.keymap.set

set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })
set("n", "<leader>m", "<cmd>Mason<cr>", { desc = "Mason" })
set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

-- autocmds

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("UserHighlightYank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})
