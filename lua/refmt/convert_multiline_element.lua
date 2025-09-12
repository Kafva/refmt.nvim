local M = {}

local config = require('refmt.config')
local util = require('refmt.util')

function M.convert_between_single_and_multiline_element()
    local parent
    local curpos = vim.api.nvim_win_get_cursor(0)
    local tag_name_node_types = { 'tag_name', 'Name' }
    local delim_nodes = { '<', '>', '/>' }

    local parent_list_types = config.get_node_types(ExprType.ELEMENT)
    util.trace(
        string.format(
            'Searching for parents under cursor %s: %s',
            vim.inspect(curpos),
            vim.inspect(parent_list_types)
        )
    )
    parent = util.find_parent(parent_list_types)
    if parent == nil then
        vim.notify('No valid match under cursor')
        return
    end

    local attributes = {}
    local start_row_elem, start_col_elem, _, end_row_elem, end_col_elem, _ =
        parent:range(true)

    local is_multiline = false
    local tag
    local delim

    for child in parent:iter_children() do
        util.trace('Child type: ' .. child:type())

        local start_row, start_col, _, end_row, end_col, _ = child:range(true)

        local lines =
            vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)

        local word = ''
        if #lines > 1 then
            -- Flatten the attribute onto one line if needed
            for i, line in ipairs(lines) do
                word = word .. vim.trim(line)
                if i ~= #lines then
                    word = word .. ' '
                end
            end
        else
            word = vim.trim(lines[1]:sub(start_col, end_col))
        end

        if vim.tbl_contains(tag_name_node_types, child:type()) then
            tag = word
        elseif vim.tbl_contains(delim_nodes, child:type()) then
            delim = word:gsub("'", ''):gsub('"', '')
        else
            -- Trailing delimiter can be part of an attribute node
            local attr = word:gsub('/>$', ''):gsub('>$', '')
            table.insert(attributes, attr)
        end

        if start_row > start_row_elem then
            is_multiline = true
        end
    end

    util.trace('tag: ' .. vim.inspect(tag))
    util.trace('attrs: ' .. vim.inspect(attributes))
    util.trace('delim: ' .. vim.inspect(delim))

    local new_lines = {}

    if is_multiline then
        util.trace('Converting to single line')
        new_lines[1] = tag .. ' ' .. table.concat(attributes, ' ') .. delim
    else
        util.trace('Converting to multiline')
        local indent = util.blankspace_indent(start_row_elem + 1)
        local attr_indent = indent .. string.rep(' ', #tag + 1)

        for i, attr in ipairs(attributes) do
            if i == 1 then
                new_lines[1] = tag .. ' ' .. attr
            elseif i == #attributes then
                table.insert(new_lines, attr_indent .. attr .. delim)
            else
                table.insert(new_lines, attr_indent .. attr)
            end
        end
    end

    vim.api.nvim_buf_set_text(
        0,
        start_row_elem,
        start_col_elem,
        end_row_elem,
        end_col_elem,
        new_lines
    )
end

return M
