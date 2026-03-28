require('telescope').load_extension('arcadia_cs')

-- vim.api.nvim_create_autocmd('BufWritePost', {
--     pattern = { "*.cpp", "*.hpp" },
--     callback = function()
--       local fname = vim.api.nvim_buf_get_name(0)
--       vim.system({'ya', 'tool', 'tt', 'format', fname}):wait()
--       vim.cmd('edit')
--     end
-- })

vim.api.nvim_create_autocmd('BufEnter', {
    pattern = { "*.hpp" },
    callback = function()
        vim.g.fsnonewfiles = 1
	-- for userver only
	local root = vim.fs.root(0, 'AUTHORS')
	if root and vim.uv.fs_stat(root .. '/chaotic') then
            vim.b.fswitchlocs = 'reg:!include/userver/!src/!'
	end
    end
})


vim.keymap.set('n', '<leader>afo', "<cmd>:OpenInArcanum<CR>", { desc = "Open in Arcanum" })
vim.keymap.set('n', '<leader>aff', "<cmd>:Telescope arcadia_cs<CR>", { desc = "Open in Arcanum" })
