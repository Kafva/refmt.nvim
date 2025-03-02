M = {}

---@return string[]
function M.current_selection()
    local start_pos = vim.api.nvim_buf_get_mark(0, '<')
    local end_pos = vim.api.nvim_buf_get_mark(0, '>')
    local start_row = start_pos[1] - 1
    local end_row = end_pos[1]
    local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
    return lines
end

return M
