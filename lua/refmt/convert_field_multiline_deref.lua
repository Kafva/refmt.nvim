local M = {}

local config = require('refmt.config')
local util = require('refmt.util')

-- Languages that need a '\' at EOL for dereferencing on multiple lines
local escaped_languages = { 'python' }

---@param node TSNode
---@param level number
---@param dots number[]
---@return number[]
local function walk(node, level, dots)
    local args_node_types = config.deref_node_types[DerefType.ARGS][vim.o.ft]
        or config.deref_node_types[DerefType.ARGS]['default']

    for child in node:iter_children() do
        local _, start_col, _, _, end_col, _ = child:range(true)
        util.trace(
            string.format(
                "Child@%d: '%s' [%d, %d]",
                level,
                child:type(),
                start_col,
                end_col
            )
        )

        if child:type() == '.' then
            table.insert(dots, #dots + 1, end_col)
        end

        if not vim.tbl_contains(args_node_types, child:type()) then
            dots = walk(child, level + 1, dots)
        end
    end

    return dots
end

function M.convert_between_single_and_multiline_deref()
    local lnum = vim.fn.line('.')
    local indent = util.blankspace_indent(lnum)
    local single_indent = util.blankspace_indent()
    local stmt_node_types = config.deref_node_types[DerefType.STMT][vim.o.ft]
        or config.deref_node_types[DerefType.STMT]['default']

    local parent = util.find_parent_final(stmt_node_types)
    if parent == nil then
        vim.notify('No valid match under cursor')
        return
    end
    util.trace('Parent node: ' .. parent:type())

    local start_row, start_col, _, end_row, end_col, _ = parent:range(true)

    local new_lines = {}
    local lines =
        vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})

    local dots = walk(parent, 1, {})
    util.trace('Dot indices: ' .. vim.inspect(dots))

    if #dots == 0 then
        vim.notify('No dereferencing found under cursor', vim.log.levels.WARN)
        return
    end

    if #lines == 1 then
        -- Expand to multiline
        -- First dereference should be on a new line
        if vim.tbl_contains(escaped_languages, vim.o.ft) then
            new_lines = { ' \\' }
        else
            new_lines = { '' }
        end
        for i, _ in ipairs(dots) do
            -- .update(**********).update2().update3(foo.bar())
            -- ~~~~~~~~~~~~~~~~~~>
            --                    ~~~~~~~~~~>
            --                               ~~~~~~~~~~~~~~~~~>
            -- The `lines[1]` does not include indentation but the indices
            -- inside `dots` do.
            local start_index = dots[i] - #indent

            local end_index
            if i < #dots then
                end_index = dots[i + 1] - 1 - #indent
            else
                end_index = #lines[1]
            end

            local item = lines[1]:sub(start_index, end_index)
            local new_line = indent .. single_indent .. item
            if vim.tbl_contains(escaped_languages, vim.o.ft) and i < #dots then
                new_line = new_line .. ' \\'
            end
            table.insert(new_lines, #new_lines + 1, new_line)
        end
        -- Skip over the trailing dot on the first line
        start_col = dots[1] - 1
    else
        -- Convert to single line, strip trailing '\' if present
        for i, line in ipairs(lines) do
            if i == 1 then
                new_lines[1] = line:gsub(' \\$', '')
            else
                local item = line:sub(dots[i - 1]):gsub(' \\$', '')
                new_lines[1] = new_lines[1] .. item
            end
        end
    end

    vim.api.nvim_buf_set_text(
        0,
        start_row,
        start_col,
        end_row,
        end_col,
        new_lines
    )
end

return M
