require("mason-lspconfig").setup {
    automatic_enable = {
        "lua_ls",
        "clangd",
        "gopls",
        "pyright",
        "black",
        "flake",
        "pylint",
    }
}
