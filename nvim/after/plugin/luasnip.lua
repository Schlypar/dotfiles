local ls = require"luasnip"

vim.keymap.set({"i"}, "<C-K>", function() ls.expand() end, {silent = true, desc = "Expand snip"})
vim.keymap.set({"i", "s"}, "<C-Tab>", function() ls.jump( 1) end, {silent = true, desc = "Jump to next parameter in snip"})
vim.keymap.set({"i", "s"}, "<S-Tab>", function() ls.jump(-1) end, {silent = true, desc = "Jump to prev parameter in snip"})
