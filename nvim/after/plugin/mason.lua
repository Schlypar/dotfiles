require("mason-lspconfig").setup {
    automatic_enable = {
        "lua_ls",
        "clangd",
        "gopls",
        "pylsp",
    }
}
