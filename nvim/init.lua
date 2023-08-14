require("schlypar")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		'nvim-telescope/telescope.nvim',
		tag = '0.1.1',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	{
		"nvim-treesitter/nvim-treesitter",
		version = false,
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
	},
    {
        'christoomey/vim-tmux-navigator',
        lazy = false,
    },
    {
        "mfussenegger/nvim-dap",
    },
    {
        "jay-babu/mason-nvim-dap.nvim",
        event = "VeryLazy",

        dependencies = {
            "williamboman/mason.nvim",
            "mfussenegger/nvim-dap",
        },
        opts = {
            handlers = {},
            ensure_installed = {
                "codelldb",
            }
        }
    },
    {
        "rcarriga/nvim-dap-ui",
        event = "VeryLazy",

        dependencies = { "mfussenegger/nvim-dap" },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            dapui.setup()
            dap.listeners.after.event_initialized["dapui-config"] = function ()
                dapui.open()
            end
            dap.listeners.after.event_terminated["dapui-config"] = function ()
                dapui.close()
            end
            dap.listeners.after.event_exited["dapui-config"] = function ()
                dapui.close()
            end
        end
    },
    {
        "mfussenegger/nvim-dap-python",
        ft = "python",
        dependencies = { "mfussenegger/nvim-dap", "rcarriga/nvim-dap-ui"},
        config = function (_, opts)
            local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
            require("dap-python").setup(path)
        end
    },
	{
		"theprimeagen/harpoon"
	},
	{
		"mbbill/undotree"
	},
	{
		"tpope/vim-fugitive"
	},
    {
        'jose-elias-alvarez/null-ls.nvim'
    },
    {
        'Civitasv/cmake-tools.nvim'
    },
    {
        'windwp/nvim-autopairs',
        config = function()
            require('nvim-autopairs')
        end,
    },
    {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup()
        end
    },
    -- {
    --     "L3MON4D3/LuaSnip",
    --     version = "<CurrentMajor>.*",
    --     -- config = function()
    --     --     require("luasnip").setup()
    --     -- end,
    -- },
    {
        'glepnir/dashboard-nvim',
        event = 'VimEnter',
        config = function()
            require('dashboard').setup{
                -- config
            }
        end,
        dependencies = { {'nvim-tree/nvim-web-devicons'}}
    },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            vim.keymap.set("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>",
            {silent = true, noremap = true})
        },
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        }
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons', opt = true }
    },
    {
        'norcalli/nvim-colorizer.lua',
        config = function()
            require("colorizer").setup({
                '*',
                -- RGB      = true;
                -- RRGGBB   = true;
                -- names    = true;
                -- RRGGBBAA = true;
                -- rgb_fn   = true;
                -- hsl_fn   = true;
                -- css      = true;
                -- css_fn   = true;
            })
        end,
    },
    {
        'stevearc/oil.nvim',
        opts = {},
        -- Optional dependencies
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = function()
			require("gruvbox").setup({
				undercurl = true,
				underline = true,
				bold = true,
				italic = {
					strings = true,
					comments = true,
					operators = false,
					folds = true,
				},
				strikethrough = true,
				invert_selection = false,
				invert_signs = false,
				invert_tabline = false,
				invert_intend_guides = false,
				inverse = true, -- invert background for search, diffs, statuslines and errors
				contrast = "", -- can be "hard", "soft" or empty string
				palette_overrides = {},
				overrides = {},
				dim_inactive = false,
				transparent_mode = false,
			})
		end,
	},
    {
        'shaunsingh/nord.nvim',
        priority = 1000,
    },
    {
        "catppuccin/nvim", name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha", -- latte, frappe, macchiato, mocha
                background = { -- :h background
                light = "latte",
                dark = "mocha",
            },
            transparent_background = false, -- disables setting the background color.
            show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
            term_colors = true, -- sets terminal colors (e.g. `g:terminal_color_0`)
            dim_inactive = {
                enabled = false, -- dims the background color of inactive window
                shade = "dark",
                percentage = 0.15, -- percentage of the shade to apply to the inactive window
            },
            no_italic = false, -- Force no italic
            no_bold = false, -- Force no bold
            no_underline = false, -- Force no underline
            styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
            comments = { "italic" }, -- Change the style of comments
            conditionals = { "italic" },
            loops = {},
            functions = {},
            keywords = {},
            strings = {},
            variables = {},
            numbers = {},
            booleans = {},
            properties = {},
            types = {},
            operators = {},
        },
        color_overrides = {},
        custom_highlights = {},
        integrations = {
            cmp = true,
            gitsigns = true,
            nvimtree = true,
            telescope = true,
            notify = false,
            mini = false,
            -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
        },
    })
    end,
    },
    {
        "navarasu/onedark.nvim",
        priority = 1000,
        config = function()
            require('onedark').setup  {
                -- Main options --
                style = 'warmer', -- Default theme style. Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
                transparent = true,  -- Show/hide background
                term_colors = true, -- Change terminal color as per the selected theme style
                ending_tildes = false, -- Show the end-of-buffer tildes. By default they are hidden
                cmp_itemkind_reverse = false, -- reverse item kind highlights in cmp menu

                -- toggle theme style ---
                toggle_style_key = nil, -- keybind to toggle theme style. Leave it nil to disable it, or set it to a string, for example "<leader>ts"
                toggle_style_list = {'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light'}, -- List of styles to toggle between

                -- Change code style ---
                -- Options are italic, bold, underline, none
                -- You can configure multiple style with comma separated, For e.g., keywords = 'italic,bold'
                code_style = {
                    comments = 'italic',
                    keywords = 'none',
                    functions = 'none',
                    strings = 'none',
                    variables = 'none'
                },

                -- Lualine options --
                lualine = {
                    transparent = false, -- lualine center bar transparency
                },

                -- Custom Highlights --
                colors = {}, -- Override default colors
                highlights = {}, -- Override highlight groups

                -- Plugins Config --
                diagnostics = {
                    darker = true, -- darker colors for diagnostic
                    undercurl = true,   -- use undercurl instead of underline for diagnostics
                    background = true,    -- use background color for virtual text
                },
            }
        end,
    },
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v2.x',
        dependencies = {
            -- LSP Support
            {'neovim/nvim-lspconfig'},             -- Required
            {                                      -- Optional
            'williamboman/mason.nvim',
            build = function()
                pcall(vim.cmd, 'MasonUpdate')
            end,
        },
        {'williamboman/mason-lspconfig.nvim'}, -- Optional

        -- Autocompletion
        {'hrsh7th/nvim-cmp'},     -- Required
        {'hrsh7th/cmp-nvim-lsp'}, -- Required
        {'L3MON4D3/LuaSnip'},     -- Required
    }
}
    })

