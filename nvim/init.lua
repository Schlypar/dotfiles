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
            dap.listeners.after.event_initialized["dapui-config"] = function()
                dapui.open()
            end
            dap.listeners.after.event_terminated["dapui-config"] = function()
                dapui.close()
            end
            dap.listeners.after.event_exited["dapui-config"] = function()
                dapui.close()
            end
        end
    },
    {
        "mfussenegger/nvim-dap-python",
        ft = "python",
        dependencies = { "mfussenegger/nvim-dap", "rcarriga/nvim-dap-ui" },
        config = function(_, opts)
            local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
            require("dap-python").setup(path)
        end
    },
    {
        "rust-lang/rust.vim",
        ft = "rust",
        init = function()
            vim.g.rustfmt_autosave = 0
        end
    },
    {
        "simrat39/rust-tools.nvim",
        ft = "rust",
        -- opts = function ()
        --     return require "after.rust-tools"
        -- end,
        -- config = function (_, opts)
        --     require('rust-tools').setup(opts)
        -- end
    },
    {
        "saecki/crates.nvim",
        ft = { "rust", "toml" },
        config = function(_, opts)
            local crates = require "crates"
            crates.setup(opts)
            crates.show()
        end,
    },
    {
        "mg979/vim-visual-multi",
        -- branch = "master",
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
    {
        "L3MON4D3/LuaSnip",
        version = "2.*",
        build = "make install_jsregexp",
        -- config = function()
        --     require("luasnip").setup({})
        -- end,
    },
    {
        "danymat/neogen",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = true,
        -- Uncomment next line if you want to follow only stable versions
        -- version = "*"
    },
    {
        'glepnir/dashboard-nvim',
        event = 'VimEnter',
        config = function()
            require('dashboard').setup {
                -- config
            }
        end,
        dependencies = { { 'nvim-tree/nvim-web-devicons' } }
    },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            position = "bottom", -- position of the list can be: bottom, top, left, right
            height = 10, -- height of the trouble list when position is top or bottom
            width = 50, -- width of the list when position is left or right
            icons = true, -- use devicons for filenames
            mode = "workspace_diagnostics", -- "workspace_diagnostics", "document_diagnostics", "quickfix", "lsp_references", "loclist"
            severity = nil, -- nil (ALL) or vim.diagnostic.severity.ERROR | WARN | INFO | HINT
            fold_open = "", -- icon used for open folds
            fold_closed = "", -- icon used for closed folds
            group = true, -- group results by file
            padding = true, -- add an extra new line on top of the list
            cycle_results = true, -- cycle item list when reaching beginning or end of list
            action_keys = { -- key mappings for actions in the trouble list
                -- map to {} to remove a mapping, for example:
                -- close = {},
                close = "q",                                                                      -- close the list
                cancel = "<esc>",                                                                 -- cancel the preview and get back to your last window / buffer / cursor
                refresh = "r",                                                                    -- manually refresh
                jump = { "<cr>", "<tab>", "<2-leftmouse>" },                                      -- jump to the diagnostic or open / close folds
                open_split = { "<C-x>" },                                                         -- open buffer in new split
                open_vsplit = { "<C-v>" },                                                        -- open buffer in new vsplit
                open_tab = { "<C-t>" },                                                           -- open buffer in new tab
                jump_close = { "o" },                                                             -- jump to the diagnostic and close the list
                toggle_mode = "m",                                                                -- toggle between "workspace" and "document" diagnostics mode
                switch_severity = "s",                                                            -- switch "diagnostics" severity filter level to HINT / INFO / WARN / ERROR
                toggle_preview = "P",                                                             -- toggle auto_preview
                hover = "K",                                                                      -- opens a small popup with the full multiline message
                preview = "p",                                                                    -- preview the diagnostic location
                open_code_href = "c",                                                             -- if present, open a URI with more information about the diagnostic error
                close_folds = { "zM", "zm" },                                                     -- close all folds
                open_folds = { "zR", "zr" },                                                      -- open all folds
                toggle_fold = { "zA", "za" },                                                     -- toggle fold of current file
                previous = "k",                                                                   -- previous item
                next = "j",                                                                       -- next item
                help = "?",                                                                       -- help menu
            },
            multiline = true,                                                                     -- render multi-line messages
            indent_lines = true,                                                                  -- add an indent guide below the fold icons
            win_config = { border = "single" },                                                   -- window configuration for floating windows. See |nvim_open_win()|.
            auto_open = false,                                                                    -- automatically open the list when you have diagnostics
            auto_close = false,                                                                   -- automatically close the list when you have no diagnostics
            auto_preview = true,                                                                  -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
            auto_fold = false,                                                                    -- automatically fold a file trouble list at creation
            auto_jump = { "lsp_definitions" },                                                    -- for the given modes, automatically jump if there is only a single result
            include_declaration = { "lsp_references", "lsp_implementations", "lsp_definitions" }, -- for the given modes, include the declaration of the current symbol in the results
            signs = {
                -- icons / text used for a diagnostic
                error = "",
                warning = "",
                hint = "",
                information = "",
                other = "",
            },
            use_diagnostic_signs = false -- enabling this will use the signs defined in your lsp client
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
        "neanias/everforest-nvim",
        version = false,
        lazy = false,
        priority = 1000, -- make sure to load this before all the other start plugins
        -- Optional; default configuration will be used if setup isn't called.
        config = function()
            require("everforest").setup({
                -- Your config here
            })
        end,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "macchiato", -- latte, frappe, macchiato, mocha
                background = {         -- :h background
                    light = "latte",
                    dark = "mocha",
                },
                transparent_background = false, -- disables setting the background color.
                show_end_of_buffer = true,      -- shows the '~' characters after the end of buffers
                term_colors = true,             -- sets terminal colors (e.g. `g:terminal_color_0`)
                dim_inactive = {
                    enabled = true,             -- dims the background color of inactive window
                    shade = "dark",
                    percentage = 0.0,           -- percentage of the shade to apply to the inactive window
                },
                no_italic = false,              -- Force no italic
                no_bold = false,                -- Force no bold
                no_underline = false,           -- Force no underline
                styles = {                      -- Handles the styles of general hi groups (see `:h highlight-args`):
                    comments = { "italic" },    -- Change the style of comments
                    conditionals = { "italic" },
                    loops = { "italic" },
                    functions = { "bold", "italic" },
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
                    mini = true,
                    -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
                },
            })
        end,
    },
    {
        "navarasu/onedark.nvim",
        priority = 1000,
        config = function()
            require('onedark').setup {
                -- Main options --
                style = 'warmer',             -- Default theme style. Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
                transparent = true,           -- Show/hide background
                term_colors = true,           -- Change terminal color as per the selected theme style
                ending_tildes = false,        -- Show the end-of-buffer tildes. By default they are hidden
                cmp_itemkind_reverse = false, -- reverse item kind highlights in cmp menu

                -- toggle theme style ---
                toggle_style_key = nil,                                                              -- keybind to toggle theme style. Leave it nil to disable it, or set it to a string, for example "<leader>ts"
                toggle_style_list = { 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light' }, -- List of styles to toggle between

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
                colors = {},     -- Override default colors
                highlights = {}, -- Override highlight groups

                -- Plugins Config --
                diagnostics = {
                    darker = true,     -- darker colors for diagnostic
                    undercurl = true,  -- use undercurl instead of underline for diagnostics
                    background = true, -- use background color for virtual text
                },
            }
        end,
    },
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v2.x',
        dependencies = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' }, -- Required
            {                            -- Optional
                'williamboman/mason.nvim',
                build = function()
                    pcall(vim.cmd, 'MasonUpdate')
                end,
            },
            { 'williamboman/mason-lspconfig.nvim' }, -- Optional

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },     -- Required
            { 'hrsh7th/cmp-nvim-lsp' }, -- Required
            { 'L3MON4D3/LuaSnip' },     -- Required
        }
    }
})


if vim.g.neovide then
    vim.o.guifont = "CaskaydiaCove Nerd Font Mono:h14"

    vim.g.neovide_scale_factor = 1.0

    vim.g.neovide_padding_top = 10
    vim.g.neovide_padding_bottom = 8
    vim.g.neovide_padding_right = 5
    vim.g.neovide_padding_left = 5

    -- g:neovide_transparency should be 0 if you want to unify transparency of content and title bar.
    vim.g.neovide_transparency = 1.0
    -- vim.g.transparency = 0.0

    local alpha = function()
        return string.format("%x", math.floor(255 * 0.5))
    end

    vim.g.neovide_background_color = "#ff0000" .. alpha()

    vim.g.neovide_floating_blur_amount_x = 2.0
    vim.g.neovide_floating_blur_amount_y = 2.0

    vim.g.neovide_hide_mouse_when_typing = true

    vim.g.neovide_theme = 'dark'

    vim.g.neovide_refresh_rate = 60
    vim.g.neovide_refresh_rate_idle = 5

    vim.g.neovide_cursor_animation_length = 0.03
    vim.g.neovide_cursor_trail_size = 0.8

    vim.g.neovide_cursor_antialiasing = true

    vim.g.neovide_cursor_animate_in_insert_mode = true
    vim.g.neovide_cursor_animate_command_line = true
end
