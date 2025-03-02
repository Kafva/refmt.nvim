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
end

return M
