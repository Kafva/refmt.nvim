local M = {}

---@type RefmtOptions
M.default_opts = {
    default_bindings = true,
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

        vim.keymap.set("n", "ta", require('refmt').convert_between_exec_array_and_bash_command,
                      {desc = "Convert between an exec(...) array and a bash command"})

        vim.keymap.set("n", "tc", require('refmt').convert_comment_slash_to_asterisk,
                       {desc = "Convert '// ... ' comments into '/** ... */'"})

        vim.keymap.set("n", "tl", require('refmt').convert_between_single_and_multiline_argument_lists,
                       {desc = "Toggle between a single line argument list and a multiline argument list"})
    end
    -- stylua: ignore end
end

return M
