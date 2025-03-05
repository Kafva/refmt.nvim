M = {}

function M.foo()
    local l = function ()
        vim.api.nvim_buf_set_text(0, start_row_params,"a b c", end_row_params,(glob == (function () return 2 end)()),   new_lines)
    end

    return l()
end

return M
