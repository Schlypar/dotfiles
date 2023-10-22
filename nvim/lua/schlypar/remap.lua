vim.g.mapleader = " "
-- vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move highlighted code down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move highlighted code up" })

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without overriding register" })

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank into void register" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank into void register" })

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete into void register" })

-- This is going to get me cancelled
vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format this buffer" })

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Rename string" })
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make current file executable" })

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end, { desc = "Source current file" })

-- vim.keymap.set("n", "<leader>db", "<cmd> DapToggleBreakpoint <CR>")
vim.keymap.set("n", "<leader>db", function()
    require 'dap'.toggle_breakpoint()
end, { desc = "Toggle breakpoint" })

vim.keymap.set("n", "<F5>", function()
    require 'dap'.continue()
end, { desc = "Start / continue debugging" })

vim.keymap.set("n", "<F10>", function()
    require 'dap'.step_over()
end, { desc = "Step over (debug)" })

vim.keymap.set("n", "<F11>", function()
    require 'dap'.step_into()
end, { desc = "Step in (debug)" })

vim.keymap.set("n", "<C-h>", "<cmd> TmuxNavigateLeft <CR>", { desc = "window left" })
vim.keymap.set("n", "<C-l>", "<cmd> TmuxNavigateRight <CR>", { desc = "window right" })
vim.keymap.set("n", "<C-j>", "<cmd> TmuxNavigateDown <CR>", { desc = "window down" })
vim.keymap.set("n", "<C-k>", "<cmd> TmuxNavigateUp <CR>", { desc = "window up" })

vim.keymap.set("n", "<C-Right>", "nil")
vim.keymap.set("n", "<C-Left>", "nil")
vim.keymap.set("n", "<C-Down>", "nil")
vim.keymap.set("n", "<C-Up>", "nil")

vim.keymap.set("n", "<C-Left>", "<cmd> TmuxNavigateLeft <CR>", { desc = "window left" })
vim.keymap.set("n", "<C-Right>", "<cmd> TmuxNavigateRight <CR>", { desc = "window right" })
vim.keymap.set("n", "<C-Down>", "<cmd> TmuxNavigateDown <CR>", { desc = "window down" })
vim.keymap.set("n", "<C-Up>", "<cmd> TmuxNavigateUp <CR>", { desc = "window up" })
