local M = {}

local config = require 'refmt.config'

---@return string[]
function M.get_array_brackets()
    if vim.tbl_contains(config.curly_bracket_filetypes, vim.o.ft) then
        return {'{', '}'}
    else
        return {'[', ']'}
    end
end

---@param node_types string[]
---@param root_node? TSNode
---@return TSNode?
function M.find_parent(node_types, root_node)
    local node, parent
    if root_node ~= nil then
        node = root_node
    else
        node = vim.treesitter.get_node()
        if node == nil then
            return nil
        end
    end
    parent = node

    while not vim.tbl_contains(node_types, parent:type()) do
        parent = parent:parent()
        if parent == nil then
            return nil
        end
    end
    return parent
end

-- Return the values of all direct child nodes of `node` and the rows
-- that the children span over.
---@param node TSNode
---@return string[], number, number
function M.get_child_values(node)
    local words = {}
    local first = true
    local children_start_row, children_end_row

    for child in node:iter_children() do
        local start_row, start_col, _, end_row, end_col, _ = child:range(true)
        if first then
            children_start_row = start_row
            first = false
        end
        children_end_row = end_row

        local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
        if #lines == 0 then
            break
        end

        local word = vim.trim(lines[1]:sub(start_col, end_col))
        table.insert(words, word)
    end

    return words, children_start_row, children_end_row
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

return M
