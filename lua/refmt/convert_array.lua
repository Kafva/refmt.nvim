local M = {}

local util = require('refmt.util')

-- Convert from a bash command to an exec(...) array
function M.convert_to_exec_array()
    local line = vim.api.nvim_get_current_line()
    local lnum = vim.fn.line('.')

    local parser = vim.treesitter.get_string_parser(line, 'bash', nil)
    local tree = parser:parse({ 0, 1 })[1]
    -- The root node is a "program", we want to pass the first "command"
    local node = tree:root():child(0)

    if node == nil then
        vim.notify('No node under cursor')
        return
    end
    local words = util.get_child_values_from_line(node, line)

    if #words == 0 then
        return
    end

    -- Quote every word
    for i, word in ipairs(words) do
        if not vim.startswith(word, '"') then
            words[i] = '"' .. word .. '"'
        end
    end

    local indent = util.blankspace_indent(lnum)
    local brackets = util.get_array_brackets()
    local new_line = indent
        .. brackets[1]
        .. vim.fn.join(words, ', ')
        .. brackets[2]

    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, true, { new_line })
end

-- Convert an exec(...) array on the *current line* to a bash command
-- Note: we do not rely on treesitter here, any "array" format will do.
function M.convert_to_bash_command()
    local line = vim.api.nvim_get_current_line()
    local lnum = vim.fn.line('.')

    if #line < 3 then
        return
    end

    -- Remove everything before the first array marker and everything after the
    -- final array marker in the first line
    local start_index, _, _ = line:find('[%[%{]')
    local end_index
    for i = #line, 0, -1 do
        end_index, _, _ = line:find('[%]%}]', i)
        if end_index then
            break
        end
    end

    line = line:sub(start_index + 1, end_index - 1)

    local words = vim.split(line, ',')
    for i, word in pairs(words) do
        -- Remove quotes around each argument and all extra spacing
        words[i] = vim.trim(word)
            :gsub('^[\'"]', '')
            :gsub('[\'"]$', '')
            :gsub('%s+', ' ')
    end

    local start_row = lnum - 1
    local end_row = start_row + 1
    local indent = util.blankspace_indent(lnum)

    local outline = indent .. vim.fn.join(words, ' ')
    vim.api.nvim_buf_set_lines(0, start_row, end_row, true, { outline })
end

return M
