local M = {}

---@enum ExprType
ExprType = {
    FUNC_DEF = 'func_def',
    FUNC_CALL = 'func_call',
    LIST = 'list',
}

---@type RefmtOptions
M.default_opts = {
    -- Enable default keybindings?
    default_bindings = true,
    -- Filetypes to insert trailing commas for when expanding expressions
    -- onto multiple lines
    trailing_comma_filetypes = {
        [ExprType.FUNC_DEF] = {
            'zig',
            'rust',
            'go',
        },
        [ExprType.FUNC_CALL] = {},
        [ExprType.LIST] = {
            'lua',
            'python',
        },
    },
    -- Filetypes that use {...} instead of [...] for arrays
    curly_bracket_filetypes = {
        'c',
        'cpp',
        'zig',
        'lua',
    },
    -- Shell script filetypes
    shell_filetypes = {
        'sh',
        'bash',
        'zsh',
    },
}

---@param user_opts RefmtOptions?
function M.setup(user_opts)
    local opts = vim.tbl_deep_extend('force', M.default_opts, user_opts or {})

    -- Expose configuration variables
    for k, v in pairs(opts) do
        M[k] = v
    end

    -- stylua: ignore start
    if opts and opts.default_bindings then
        vim.keymap.set("n", "tl", require('refmt').convert_between_single_and_multiline_parameter_lists,
                       {desc = "Toggle between a single line and multiline list of parameters"})

        vim.keymap.set("n", "ta", require('refmt').convert_between_command_and_exec_array,
                      {desc = "Convert between a bash command and an exec(...) array"})

        vim.keymap.set("n", "tc", require('refmt').convert_comment_slash_to_asterisk,
                       {desc = "Convert '// ... ' comments into '/** ... */'"})

    end
    -- stylua: ignore end
end

return M
