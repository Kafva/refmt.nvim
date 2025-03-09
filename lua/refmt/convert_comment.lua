local M = {}

-- Refactor '// ... ' comments into '/** ... */'
function M.convert_comment_slash_to_asterisk()
    local window = vim.api.nvim_get_current_win()
    local start_pos = vim.api.nvim_win_get_cursor(window)
    local first = true
    local new_lines = {}
    local indent = ''
    -- Skip over leading whitespace to make sure we land on a TSNode...
    vim.cmd[[silent normal! w]]

    for i=1,100 do -- Do not loop forever in weird scenarios
        ---@type TSNode?
        local node = vim.treesitter.get_node()
        if node == nil or node:type() ~= 'comment' then
            if first then
                vim.notify("No comment under cursor")
                return
            else
                -- No more comment lines
                break
            end
        end

        ---@diagnostic disable-next-line: need-check-nil
        local start_row, _, _ = node:start()
        ---@type string
        local line = vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1]
        indent = string.rep(' ', vim.fn.indent(start_row + 1))

        if not vim.startswith(vim.trim(line), '//') then
            vim.notify("Comment prefix must be '//' for conversion")
            return
        end
        local content, _ = vim.trim(line):gsub('///*%s*', '')

        table.insert(new_lines, indent .. " * " .. content)

        -- Move to next line
        vim.api.nvim_win_set_cursor(window, { start_pos[1] + i, 0 })
        -- Skip over leading whitespace on next line to make sure we land on
        -- the TSNode...
        vim.cmd[[silent normal! w]]
        first = false
    end

    local end_line
    if #new_lines == 1 then
        new_lines[1] = new_lines[1]:gsub(' %* ', '/** ') .. " */"
        end_line = start_pos[1]
    else
        table.insert(new_lines, 1, indent .. '/**')
        table.insert(new_lines, indent .. ' */')
        end_line = start_pos[1] + (#new_lines - 3)
    end

    vim.api.nvim_buf_set_lines(0, start_pos[1] - 1, end_line, true, new_lines)
end

return M
