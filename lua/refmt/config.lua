local M = {}

---@type RefmtOptions
M.default_opts = {
    default_bindings = true,
    -- How much to indent arguments to a bash command when expanded into a
    -- multiline call.
    bash_command_argument_indent = 4,
    -- Filetypes to insert trailing commas for when expanding argument lists
    -- onto multiple lines
    trailing_comma_filetypes = {
        'zig',
        'rust'
    },
    -- Filetypes to use {...} instead of [...] in when translating commands into
    -- exec(...) arrays
    curly_bracket_filetypes = {
        'c',
        'cpp',
        'zig',
        'lua',
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
        vim.keymap.set("n", "tf", require('refmt').convert_between_single_and_multiline_bash_command,
                      {desc = "Convert between a singleline and multiline bash command"})

        vim.keymap.set("n", "ta", require('refmt').convert_to_exec_array,
                      {desc = "Convert from a bash command to an exec(...) array"})

        vim.keymap.set("n", "tu", require('refmt').convert_to_bash_command,
                      {desc = "Convert from an exec(...) array into a bash command"})

        vim.keymap.set("n", "tc", require('refmt').convert_comment_slash_to_asterisk,
                       {desc = "Convert '// ... ' comments into '/** ... */'"})

        vim.keymap.set("n", "tl", require('refmt').convert_between_single_and_multiline_argument_lists,
                       {desc = "Toggle between a single line argument list and a multiline argument list"})
    end
    -- stylua: ignore end
end

return M
