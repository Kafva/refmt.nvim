local M = {}

local config = require('refmt.config')
local util = require('refmt.util')

---@param words string[]
---@param indent string
---@return string[]
local function build_multiline_bash_command(words, indent)
    local extra_indent = util.blankspace_indent()
    local is_subshell = false
    local new_lines = {}

    for _, word in ipairs(words) do
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

            if
                not is_subshell
                and #new_lines == 0
                and vim.startswith(word, '(')
            then
                -- For subshells, strip leading bracket
                word = word:sub(2, #word)
                is_subshell = true
            end

            if #new_lines == 1 then
                if is_subshell then
                    -- No leading indent for subshells
                    new_lines[#new_lines] = new_lines[#new_lines] .. ' \\'
                else
                    new_lines[#new_lines] = indent
                        .. new_lines[#new_lines]
                        .. ' \\'
                end
            elseif #new_lines > 1 then
                new_lines[#new_lines] = indent
                    .. extra_indent
                    .. new_lines[#new_lines]
                    .. ' \\'
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
---@return string[]
local function build_multiline_bash_array(words, indent)
    local new_lines = {}
    local indent_params = indent .. util.blankspace_indent()

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
    local indent = util.blankspace_indent(lnum)

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
            new_lines = build_multiline_bash_array(words, indent)
        end
    else
        -- If the command spans more than one row, re-format it to one line
        if #words <= 2 then
            vim.notify('Nothing to fold')
            return
        end

        if expr_type == ExprType.FUNC_CALL then
            if vim.startswith(words[1], '(') then
                -- Strip leading subshell bracket
                words[1] = words[1]:sub(2)
                -- Skip indentation
                new_lines = { vim.fn.join(words, ' ') }
            else
                new_lines = { indent .. vim.fn.join(words, ' ') }
            end
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
    local parent
    local expr_type
    local enclosing_brackets

    -- The order of the array matters,
    -- if there is a list inside of a function call, match the list,
    -- if there is a function call inside of a list, metch the function call.
    for _, t in ipairs({ ExprType.LIST, ExprType.FUNC_CALL, ExprType.FUNC_DEF }) do
        local parent_list_types = config.node_types[t][vim.o.ft]
            or config.node_types[t]['default']

        parent = util.find_parent(parent_list_types)
        if parent ~= nil then
            expr_type = t
            if expr_type == ExprType.LIST then
                enclosing_brackets = util.get_array_brackets()
            else
                enclosing_brackets = { '(', ')' }
            end
            break
        end
    end

    if parent == nil then
        vim.notify('No valid match under cursor')
        return
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
            if
                parent:type() == 'function_declaration'
                or parent:type() == 'call_expression'
            then
                -- All literals of the function like 'func' are part of a
                -- 'function_declaration', skip over all child nodes until we
                -- reach the first '('.
                -- The function name is part of 'call_expression' nodes, we skip
                -- this in a similar way.
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

    if
        start_row_expr == nil
        or start_col_expr == nil
        or end_row_expr == nil
        or end_col_expr == nil
    then
        vim.notify(
            string.format(
                'Failed to determine expression range: { start = (%d, %d), end = (%d, %d) }',
                start_row_expr or -1,
                start_col_expr or -1,
                end_row_expr or -1,
                end_col_expr or -1
            ),
            vim.log.levels.ERROR
        )
        return
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
        local indent = util.blankspace_indent(start_row_expr + 1)
        local indent_params = indent .. util.blankspace_indent()

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
