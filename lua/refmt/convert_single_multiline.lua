local M = {}

local config = require('refmt.config')
local util = require('refmt.util')

-- stylua: ignore start
local node_types = {
    [ExprType.FUNC_DEF] = {
        'parameters',
        'method_declaration',           -- Java
        'parameter_list',               -- C, Rust, Zig
        'formal_parameters',            -- Typescript
        'formal_parameter_list',        -- Dart
        'function_value_parameters',    -- Kotlin
        'function_declaration',         -- Swift
    },
    [ExprType.FUNC_CALL] = {
        'arguments',
        'argument_list',                -- C, Rust, Zig
        'value_arguments',              -- Swift
    },
    [ExprType.LIST] = {
        'array',                         -- Typescript
        'list',                          -- Python
        'table_constructor',             -- Lua
        'array_literal',                 -- Swift
        'array_expression',              -- Rust
        'initializer_list',              -- C, Zig
        -- This match might be too greedy...
        'literal_value',                 -- Go
    }
}
local all_node_types = {
    node_types[ExprType.FUNC_DEF],
    node_types[ExprType.FUNC_CALL],
    node_types[ExprType.LIST],
}
-- stylua: ignore end

---@param words string[]
---@param indent string
---@return string[]
local function build_multiline_bash_command(words, indent)
    local extra_indent = string.rep(' ', vim.o.sw)
    local new_lines = {}

    for i, word in ipairs(words) do
        -- A flag is expected to start with '-' or '+'
        local isflag = word:match('^[-+]') ~= nil
        local prev_isflag = #new_lines > 0
            and new_lines[#new_lines]:match('^[-+]') ~= nil
        local prev_has_arg = #new_lines > 0
            and new_lines[#new_lines]:match(' ') ~= nil

        if not isflag and prev_isflag and not prev_has_arg then
            -- Previous word was a flag and current word is not, add as an argument
            -- unless an argument has already been provided
            new_lines[#new_lines] = new_lines[#new_lines] .. ' ' .. word
        else
            -- Otherwise, finish up the previous row and add the current
            -- word on a new row
            if #new_lines == 1 then
                new_lines[#new_lines] = indent .. new_lines[#new_lines] .. ' \\'
            elseif #new_lines > 1 then
                new_lines[#new_lines] = indent
                    .. extra_indent
                    .. new_lines[#new_lines]
                    .. ' \\'
            end
            -- For subshells, strip leading bracket
            if i == 1 and vim.startswith(word, '(') then
                word = word:sub(2, #word)
            end
            table.insert(new_lines, vim.trim(word))
        end
    end

    -- Indent last row
    new_lines[#new_lines] = indent .. extra_indent .. new_lines[#new_lines]
    return new_lines
end

---@param words string[]
---@param indent string
---@param start_row integer
---@return string[]
local function build_multiline_bash_array(words, indent, start_row)
    local new_lines = {}
    local indent_params =
        string.rep(' ', vim.fn.indent(start_row + 1) + vim.o.sw)

    new_lines[1] = '(' -- initial newline
    for i, param in ipairs(words) do
        local value
        if i == 1 and vim.startswith(param, '(') then
            -- Strip leading bracket from first parameter
            value = indent_params .. param:sub(2, #param)
        else
            value = indent_params .. param
        end
        table.insert(new_lines, value)
    end
    table.insert(new_lines, indent .. ')') -- closing bracket on newline

    return new_lines
end

function M.convert_between_single_and_multiline_bash()
    if vim.tbl_contains({ '', 'text' }, vim.o.ft) then
        -- Parse entire file as bash for '[No Name]' and plaintext buffers
        vim.o.ft = 'bash'
    end

    local lnum = vim.fn.line('.')
    local indent = string.rep(' ', vim.fn.indent(lnum))

    local expr_type
    local node = util.find_parent({ 'command', 'array' })
    if node == nil then
        vim.notify('No valid match under cursor')
        return
    elseif node:type() == 'command' then
        expr_type = ExprType.FUNC_CALL
    elseif node:type() == 'array' then
        expr_type = ExprType.LIST
    else
        vim.notify('Unexpected node type: ' .. node:type())
        return
    end

    local words, start_row, start_col, end_row, end_col =
        util.get_child_values(node, { '(', ')' })

    if #words == 0 then
        return
    end

    local new_lines = {}
    if start_row == end_row then
        -- If the command spans a single line, unfold it with each argument on
        -- a seperate line
        if expr_type == ExprType.FUNC_CALL then
            new_lines = build_multiline_bash_command(words, indent)
        elseif expr_type == ExprType.LIST then
            new_lines = build_multiline_bash_array(words, indent, start_row)
        end
    else
        -- If the command spans more than one row, re-format it to one line
        if #words <= 2 then
            vim.notify('Nothing to fold')
            return
        end

        if expr_type == ExprType.FUNC_CALL then
            new_lines = { indent .. vim.fn.join(words, ' ') }
        elseif expr_type == ExprType.LIST then
            new_lines = { '(' .. vim.fn.join(words, ' ') .. ')' }
        end
    end

    if #new_lines == 0 then
        vim.notify(
            '[refmt.nvim] Internal error: no replacement lines generated',
            vim.log.levels.ERROR
        )
        return
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

function M.convert_between_single_and_multiline()
    local all_node_types_flat = vim.iter(all_node_types):flatten():totable()

    -- Find the first parent that matches any of the parent types, i.e.
    -- if there is a list inside of a function call, match the list,
    -- if there is a function call inside of a list, metch the function call.
    local parent = util.find_parent(all_node_types_flat)
    if parent == nil then
        vim.notify('No valid match under cursor')
        return
    end

    local expr_type
    local enclosing_brackets

    if vim.tbl_contains(node_types[ExprType.LIST], parent:type()) then
        expr_type = ExprType.LIST
        enclosing_brackets = util.get_array_brackets()
    elseif vim.tbl_contains(node_types[ExprType.FUNC_CALL], parent:type()) then
        expr_type = ExprType.FUNC_CALL
        enclosing_brackets = { '(', ')' }
    else
        expr_type = ExprType.FUNC_DEF
        enclosing_brackets = { '(', ')' }
    end

    -- Child nodes to skip over, 'function_body' needs to be skipped for
    -- 'function_declaration'
    local skipable_tables = { enclosing_brackets, { ',', 'function_body' } }
    local skipable_nodes = vim.iter(skipable_tables):flatten():totable()

    -- Parse out each parameter
    local words = {}
    local start_col_expr, start_row_expr, end_col_expr, end_row_expr
    local first = true
    local is_multiline = false
    local combine_with_previous = false
    for child in parent:iter_children() do
        local start_row, start_col, _, end_row, end_col, _ = child:range(true)

        if first then
            if parent:type() == 'function_declaration' then
                -- All literals of the function like 'func' are part of a
                -- 'function_declaration', skip over all child nodes until we
                -- reach the first '('
                if child:type() == enclosing_brackets[1] then
                    start_row_expr = start_row
                    start_col_expr = start_col
                    first = false
                else
                    goto continue
                end
            end

            -- Save the position of the first character to replace
            start_row_expr = start_row
            start_col_expr = start_col
            first = false
        end

        -- Skip over child nodes that are not relevant
        if vim.tbl_contains(skipable_nodes, child:type()) then
            -- Save the position of the last character to replace
            if child:type() == enclosing_brackets[2] then
                end_row_expr = end_row
                end_col_expr = end_col
            end
            goto continue
        end

        local lines =
            vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
        if #lines == 0 then
            break
        end

        if start_row > start_row_expr then
            is_multiline = true
        end

        local word = vim.trim(lines[1]:sub(start_col, end_col))

        if combine_with_previous then
            local previous_word = table.remove(words)
            word = previous_word .. ' ' .. word
            combine_with_previous = false
        end
        table.insert(words, word)

        -- XXX: Kotlin can have parameters with leading 'parameter_modifiers'
        -- these should be placed on the same line as the next parameter
        if child:type() == 'parameter_modifiers' then
            combine_with_previous = true
        end

        ::continue::
    end

    local new_lines = {}

    if is_multiline then
        -- Convert to single line
        new_lines[1] = ''
        if not vim.startswith(words[1], enclosing_brackets[1]) then
            new_lines[1] = enclosing_brackets[1]
        end

        new_lines[1] = new_lines[1] .. table.concat(words, ', ')

        if not vim.endswith(words[#words], enclosing_brackets[2]) then
            new_lines[1] = new_lines[1] .. enclosing_brackets[2]
        end
    else
        -- Convert to multiline
        local indent = string.rep(' ', vim.fn.indent(start_row_expr + 1))
        local indent_params =
            string.rep(' ', vim.fn.indent(start_row_expr + 1) + vim.o.sw)

        -- Initial newline with bracket
        new_lines[1] = enclosing_brackets[1]
        for i, param in ipairs(words) do
            local value
            if i == 1 and vim.startswith(param, enclosing_brackets[1]) then
                -- Strip leading bracket from first parameter
                value = indent_params .. param:sub(2, #param)
            elseif vim.startswith(param, ',') then
                -- ',' can be part of the parameter in some cases
                value = indent_params .. param:sub(2, #param)
            else
                value = indent_params .. param
            end

            if
                i < #words
                or vim.tbl_contains(
                    config.trailing_comma_filetypes[expr_type],
                    vim.o.ft
                )
            then
                value = value .. ','
            end
            table.insert(new_lines, value)
        end
        -- Closing bracket on newline
        table.insert(new_lines, indent .. enclosing_brackets[2])
    end

    if
        start_row_expr == nil
        or start_col_expr == nil
        or end_row_expr == nil
        or end_col_expr == nil
    then
        vim.notify(
            '[refmt.nvim] Internal error: trying to replace line with:',
            vim.log.levels.ERROR
        )
        vim.notify(vim.inspect(new_lines))
        return
    end

    vim.api.nvim_buf_set_text(
        0,
        start_row_expr,
        start_col_expr,
        end_row_expr,
        end_col_expr,
        new_lines
    )
end

return M
