vim.opt.list = true
-- vim.opt.listchars:append "space:⋅"
vim.opt.listchars:append "eol:↴"

vim.cmd [[highlight IndentBlanklineIndent1 guifg=#4c566a gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guifg=#81a1c1 gui=nocombine]]

require("indent_blankline").setup {
    show_end_of_line = true,
    -- space_char_blankline = "⋅",
    -- char_highlight_list = {
    --     "IndentBlanklineIndent1",
    -- },
    space_char_highlight_list = {
        "IndentBlanklineIndent2",
    },
}
