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
    local args_node_types = config.get_deref_node_types(DerefType.ARGS)

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
    local cur = vim.api.nvim_win_get_cursor(0)
    local indent = util.blankspace_indent(cur[1])
    local single_indent = util.blankspace_indent()
    local call_node_types = config.get_deref_node_types(DerefType.CALL)
    local args_node_types = config.get_deref_node_types(DerefType.ARGS)

    -- Find the final call node type going upwards, if we encounter an
    -- 'arguments' node, break, we have the outer most call we are looking for
    -- already.
    local parent = util.find_parent_final(call_node_types, nil, args_node_types)
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

        -- The `lines[1]` only includes the actual call, we may have more
        -- leading text, the index in `dots` is based on the full line!
        local full_line =
            vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1]

        for i, _ in ipairs(dots) do
            -- .update(**********).update2().update3(foo.bar())
            -- ~~~~~~~~~~~~~~~~~~>
            --                    ~~~~~~~~~~>
            --                               ~~~~~~~~~~~~~~~~~>
            local start_index = dots[i]

            local end_index
            if i < #dots then
                end_index = dots[i + 1] - 1
            else
                -- The end_index needs to take leading text into account
                local shared_prefix_start, _ = full_line:find(lines[1], 0, true)
                if shared_prefix_start == nil then
                    error('Could not find call text in complete line')
                end
                end_index = #lines[1] + shared_prefix_start - 1
            end

            local item = full_line:sub(start_index, end_index)
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
