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
        vim.keymap.set("n", "tf", require('refmt').bash_fold_toggle,
                      {desc = "Fold/unfold bash command under cursor"})

        vim.keymap.set("n", "ta", require('refmt').bash_argify,
                      {desc = "Create an argument array bash command under cursor"})

        vim.keymap.set("v", "tu", function ()
            -- HACK: The visual selection marks "'<,'>" that we use to determine the
            -- currently selected text are not set until after we simulate opening the
            -- command prompt
            vim.fn.feedkeys(':')
            vim.fn.feedkeys("BashUnargify")
            vim.cmd[[call feedkeys("\<CR>")]]
        end, {desc = "Revert command list under cursor to a bash command"})

        vim.keymap.set("n", "tc", require('refmt').convert_comment,
                       {desc = "Convert '// ... ' comments into '/** ... */'"})

        vim.keymap.set("n", "tl", require('refmt').convert_arglist,
                       {desc = "Split argument list onto seperate lines"})
    end
    -- stylua: ignore end
end

return M
