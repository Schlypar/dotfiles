local colors = {
    bg_dim    = "#1e2326",
    bg0       = "#272e33",
    bg1       = "#2e383c",
    bg2       = "#374145",
    bg3       = "#414b50",
    bg4       = "#495156",
    bg5       = "#4f5b58",
    bg_visual = "#4c3743",
    bg_red    = "#493b40",
    bg_green  = "#3c4841",
    bg_blue   = "#384b55",
    bg_yellow = "#45443c",

    bg        = '#202328',
    fg        = '#bbc2cf',
    yellow    = '#ECBE7B',
    cyan      = '#008080',
    darkblue  = '#081633',
    green     = '#98be65',
    orange    = '#FF8800',
    violet    = '#a9a1e1',
    magenta   = '#c678dd',
    blue      = '#51afef',
    red       = '#ec5f67',
}

local diagnostics =
{
    'diagnostics',

    -- Table of diagnostic sources, available sources are:
    --   'nvim_lsp', 'nvim_diagnostic', 'nvim_workspace_diagnostic', 'coc', 'ale', 'vim_lsp'.
    -- or a function that returns a table as such:
    --   { error=error_cnt, warn=warn_cnt, info=info_cnt, hint=hint_cnt }
    sources = { 'nvim_lsp', 'nvim_diagnostic' },

    -- Displays diagnostics for the defined severity types
    sections = { 'error', 'warn', 'info', 'hint' },

    symbols = { error = 'E ', warn = 'W ', info = 'I ', hint = 'H ' },
    colored = true, -- Displays diagnostics status in color if set to true.
    diagnostics_color = {
        color_error = { fg = colors.red },
        color_warn = { fg = colors.yellow },
        color_info = { fg = colors.cyan },
    },

    update_in_insert = false, -- Update diagnostics in insert mode.
    always_visible = false,   -- Show diagnostics even if there are none.

    -- color = { bg = colors.bg4 }
}

local file_format =
{
    'fileformat',
    symbols = {
        unix = 'unix',
        dos = 'windows',
        mac = 'macos',
    }
}

local file_name =
{
    'filename',
    file_status = true,     -- Displays file status (readonly status, modified status)
    newfile_status = false, -- Display new file status (new file means no write after created)
    path = 0,               -- 0: Just the filename
    -- 1: Relative path
    -- 2: Absolute path
    -- 3: Absolute path, with tilde as the home directory
    -- 4: Filename and parent dir, with tilde as the home directory

    shorting_target = 40, -- Shortens path to leave 40 spaces in the window
    -- for other components. (terrible name, any suggestions?)
    symbols = {
        modified = '[+]',      -- Text to show when the file is modified.
        readonly = '[-]',      -- Text to show when the file is non-modifiable or readonly.
        unnamed = '[No Name]', -- Text to show for unnamed buffers.
        newfile = '[New]',     -- Text to show for newly created file before first write
    }
}

local lsp = {
    function()
        local msg = 'No Active Lsp'
        local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
        local clients = vim.lsp.get_active_clients()
        if next(clients) == nil then
            return msg
        end
        for _, client in ipairs(clients) do
            local filetypes = client.config.filetypes
            if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                return client.name
            end
        end
        return msg
    end,
}

local encoding =
{
    'o:encoding',
}

local buffers =
{
    'buffers',
    show_filename_only = true,       -- Shows shortened relative path when set to false.
    hide_filename_extension = false, -- Hide filename extension when set to true.
    show_modified_status = true,     -- Shows indicator when the buffer is modified.

    mode = 0,                        -- 0: Shows buffer name
    -- 1: Shows buffer index
    -- 2: Shows buffer name + buffer index
    -- 3: Shows buffer number
    -- 4: Shows buffer name + buffer number

    max_length = vim.o.columns * 2 / 3, -- Maximum width of buffers component,

    -- Automatically updates active buffer color to match color of other components (will be overidden if buffers_color is set)
    use_mode_colors = false,

    buffers_color = {
        -- Same values as the general color option can be used here.
        active = nil,   -- Color for active buffer.
        inactive = nil, -- Color for inactive buffer.
    },

    symbols = {
        modified = ' [+]',    -- Text to show when the buffer is modified
        alternate_file = '',  -- Text to show to identify the alternate file
        directory = ' [dir]', -- Text to show when the buffer is a directory
    },
}


require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = 'auto',
        -- component_separators = { left = '', right = ''},
        -- section_separators = { left = '', right = ''},
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
            statusline = {},
            winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
        }
    },
    tabline = {
        lualine_a = { buffers },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
    },
    winbar = {},
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff' },
        lualine_c = { file_name },
        lualine_x = { diagnostics, file_format, lsp, encoding },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
    },
    inactive_sections = {},
    inactive_winbar = {},
    extensions = {}
}
