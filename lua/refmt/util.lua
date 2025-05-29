local M = {}

local config = require('refmt.config')

-- Return the indent spaces to use for the provided line, if no line is provided,
-- return the indent string for one `tabstop`.
---@param lnum number?
---@return string
function M.blankspace_indent(lnum)
    local cnt = 1
    if lnum ~= nil then
        cnt = vim.fn.indent(lnum) / vim.o.tabstop
    end

    local indent
    if vim.o.expandtab then
        indent = string.rep(' ', vim.o.tabstop)
    else
        indent = '\t'
    end
    return string.rep(indent, cnt)
end

---@return string[]
function M.get_array_brackets()
    if vim.tbl_contains(config.curly_bracket_filetypes, vim.o.ft) then
        return { '{', '}' }
    else
        return { '[', ']' }
    end
end

-- Finds the first parent of the given type.
---@param node_types string[]
---@param root_node? TSNode
---@return TSNode?
function M.find_parent(node_types, root_node)
    local node
    if root_node ~= nil then
        node = root_node
    else
        node = vim.treesitter.get_node()
        if node == nil then
            return nil
        end
    end

    while not vim.tbl_contains(node_types, node:type()) do
        node = node:parent()
        if node == nil then
            return nil
        end
    end
    return node
end

-- Finds the final parent of the given type.
---@param node_types string[]
---@param root_node? TSNode
---@return TSNode?
function M.find_parent_final(node_types, root_node)
    local node
    if root_node ~= nil then
        node = root_node
    else
        node = vim.treesitter.get_node()
        if node == nil then
            return nil
        end
    end

    local final_parent = node
    while node do
        node = node:parent()
        if node == nil then
            break
        end
        if vim.tbl_contains(node_types, node:type()) then
            final_parent = node
        end
    end
    return final_parent
end

-- Return the values of all direct child nodes of `node` and the rows
-- that the children span over. Exclude nodes within the `filter_out`
-- array from the result.
---@param node TSNode
---@param filter_out string[]
---@return string[], number, number, number, number
function M.get_child_values(node, filter_out)
    local words = {}
    local first = true
    local expr_start_row, expr_start_col, expr_end_row, expr_end_col

    for child in node:iter_children() do
        local start_row, start_col, _, end_row, end_col, _ = child:range(true)
        if first then
            expr_start_row = start_row
            expr_start_col = start_col
            first = false
        end
        expr_end_row = end_row
        expr_end_col = end_col

        if vim.tbl_contains(filter_out, child:type()) then
            goto continue
        end

        local lines =
            vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
        if #lines == 0 then
            break
        end

        local word = vim.trim(lines[1]:sub(start_col, end_col))
        table.insert(words, word)
        ::continue::
    end

    return words, expr_start_row, expr_start_col, expr_end_row, expr_end_col
end

-- Return the values of all direct children of `node`.
-- The `node` should have been loaded from the `line` string.
---@param node TSNode
---@param line string
---@return string[]
function M.get_child_values_from_line(node, line)
    local words = {}

    for child in node:iter_children() do
        local _, start_col, _, _, end_col, _ = child:range(true)
        local word = vim.trim(line:sub(start_col, end_col))
        table.insert(words, word)
    end

    return words
end

---@param message string
function M.trace(message)
    if not config.trace then
        return
    end

    local d = debug.getinfo(2, 'Sl')
    local s = string.format(
        '%s:%d: %s',
        vim.fs.basename(d.short_src),
        d.currentline,
        message
    )
    vim.notify(s, vim.log.levels.INFO)
end

return M
