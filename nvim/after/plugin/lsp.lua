local lsp = require("lsp-zero")

lsp.preset("recommended")

lsp.ensure_installed({
	'clangd',
	'rust_analyzer',
    -- 'pyright',
    -- "python-lsp-server",
})

local mason = require("mason")

mason.ensure_installed = {
    -- 'mypy',
    'ruff',
    -- "python-lsp-server",
    'black',
    'debugpy',
}

-- Fix Undefined global 'vim'
lsp.nvim_workspace()


local cmp = require('cmp')
local cmp_select = {behavior = cmp.SelectBehavior.Select}
local cmp_mappings = lsp.defaults.cmp_mappings({
	['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
	['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
	['<enter>'] = cmp.mapping.confirm({ select = true }),
	["<C-Space>"] = cmp.mapping.complete(),
})

-- cmp_mappings['<Tab>'] = nil
-- cmp_mappings['<S-Tab>'] = nil

lsp.setup_nvim_cmp({
	mapping = cmp_mappings
})

require'cmp'.setup({
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        -- { name = 'vsnip' }, -- For vsnip users.
        { name = 'luasnip' }, -- For luasnip users.
        -- { name = 'ultisnips' }, -- For ultisnips users.
        -- { name = 'snippy' }, -- For snippy users.
    }, {
        { name = 'buffer' },
    })
})

lsp.set_preferences({
	suggest_lsp_servers = false,
	sign_icons = {
		error = 'E',
		warn = 'W',
		hint = 'H',
		info = 'I'
	}
})

lsp.on_attach(function(client, bufnr)
	local opts = {buffer = bufnr, remap = false}
    lsp.default_keymaps({buffer = bufnr})

	vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, {desc = "Go to definition"})
	vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, {desc = "Show type / prototype"})
	vim.keymap.set("n", "<leader>ws", function() vim.lsp.buf.workspace_symbol() end, {desc = "Show ocurrences of symbol"})
	vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, {desc = "Show diagnostics (errors)"})
	vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, {desc = "Go to next diagnostic message"})
	vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, {desc = "Go to prev diagnostic message"})
	vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, {desc = "Code action"})
	vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, {desc = "Show symbol references"})
	vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, {desc = "Rename symbol"})
	vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, {desc = "Signature help"})
end)

vim.diagnostic.config({
	virtual_text = true
})

local null_ls = require('null-ls')
local formatting = null_ls.builtins.formatting
local lint  = null_ls.builtins.diagnostics

null_ls.setup({
    sources = {
        formatting.clang_format,
        lint.clang_check,

        formatting.black,
        -- lint.mypy,
        -- lint.ruff,
    },
})

lsp.format_on_save({
  format_opts = {
    async = false,
    timeout_ms = 10000,
  },
  servers = {
    -- ['lua_ls'] = {'lua'},
    -- ['rust_analyzer'] = {'rust'},
    -- if you have a working setup with null-ls
    -- you can specify filetypes it can format.
    ['null-ls'] = {'cpp', 'c', 'rust', 'python'},
  }
})

lsp.setup()
