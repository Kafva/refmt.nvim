local M = {}

local config = require 'refmt.config'

---@param node_types string[]
---@param root_node? TSNode
---@return TSNode?
local function find_parent(node_types, root_node)
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
local function get_child_values(node)
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
local function get_child_values_from_line(node, line)
    local words = {}

    for child in node:iter_children() do
        local _, start_col, _, _, end_col, _ = child:range(true)
        local word = vim.trim(line:sub(start_col, end_col))
        table.insert(words, word)
    end

    return words
end

local function convert_between_single_and_multiline_bash()
    if vim.tbl_contains({'', 'text'}, vim.o.ft) then
        -- Parse entire file as bash for '[No Name]' and plaintext buffers
        vim.o.ft = 'bash'
    end

    local lnum = vim.fn.line('.')
    local indent = string.rep(' ', vim.fn.indent(lnum))
    local extra_indent = string.rep(" ", vim.o.sw)

    local node = find_parent({'command'})
    if node == nil then
        vim.notify("No command under cursor")
        return
    end

    local words, start_row, end_row = get_child_values(node)

    if #words == 0 then
        return
    end

    local new_lines = {}
    if start_row == end_row then
        -- If the command spans a single line, unfold it with each argument on
        -- a seperate line

        for _,word in ipairs(words) do
            -- A flag is expected to start with '-' or '+'
            local isflag = word:match("^[-+]") ~= nil
            local prev_isflag = #new_lines > 0 and new_lines[#new_lines]:match("^[-+]") ~= nil
            local prev_has_arg = #new_lines > 0  and new_lines[#new_lines]:match(" ") ~= nil

            if not isflag and prev_isflag and not prev_has_arg then
                -- Previous word was a flag and current word is not, add as an argument
                -- unless an argument has already been provided
                new_lines[#new_lines] = new_lines[#new_lines] .. " " .. word
            else
                -- Otherwise, finish up the previous row and add the current
                -- word on a new row
                if #new_lines == 1 then
                    new_lines[#new_lines] = indent .. new_lines[#new_lines] .. " \\"
                elseif #new_lines > 1 then
                    new_lines[#new_lines] = indent .. extra_indent .. new_lines[#new_lines] .. " \\"
                end
                table.insert(new_lines, vim.trim(word))
            end
        end

        -- Indent last row
        new_lines[#new_lines] = indent .. extra_indent .. new_lines[#new_lines]

        vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, true, new_lines)
    else
        -- If the command spans more than one row, re-format it to one line
        if #words <= 2 then
            vim.notify("Nothing to fold")
            return {}
        end

        new_lines = { indent .. vim.fn.join(words, " ") }
        vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, new_lines)
    end
end

-- Toggle between a single line argument list and a multiline argument list
local function convert_between_single_and_multiline()
    local params_parent_list = {
        'parameters',
        'method_declaration',           -- Java
        'parameter_list',               -- C, Rust, Zig
        'formal_parameters',            -- Typescript
        -- TODO
        --'function_declaration',       -- Swift
        -- TODO
        'function_value_parameters',    -- Kotlin
        'list'                          -- Python lists
    }
    local params_child_names = {
        'parameter',
        'parameter_declaration',        -- C, Rust, Zig
        'required_parameter',           -- Typescript
        'optional_parameter',           -- Typescript
        'formal_parameter',             -- Java
        'typed_parameter',              -- Python
        -- XXX: Python parameters without type annotations
        'identifier',
        -- XXX: Kotlin can have parameters with leading 'parameter_modifiers'
        -- these should be placed on the same line as the next parameter
        'parameter_modifiers'
    }
    local func_call_parent_lists = {
        'arguments',
        'argument_list',                -- C, Rust, Zig
    }

    local is_func_call = false
    local is_multiline = false

    local parent = find_parent(params_parent_list)
    if parent == nil then
        parent = find_parent(func_call_parent_lists)
        if parent == nil then
            vim.notify("No parameter list under cursor")
            return
        end
        is_func_call = true
    end

    -- Parse out each parameter
    local words = {}
    local start_col_func_name, start_row_func_name, end_col_func_name, end_row_func_name
    local first = true
    local combine_with_previous = false
    for child in parent:iter_children() do
        local start_row, start_col, _, end_row, end_col, _ = child:range(true)

        if first then
            -- Save the position of the first character to replace
            start_row_func_name = start_row
            start_col_func_name = start_col
            first = false
        end

        -- Skip over child nodes that are not relevant
        local should_skip
        if is_func_call then
            should_skip = vim.tbl_contains({',', '(', ')'}, child:type())
        else
            should_skip = not vim.tbl_contains(params_child_names, child:type())
        end

        if should_skip then
            -- Save the position of the last character to replace
            if child:type() == ')' then
                end_row_func_name = end_row
                end_col_func_name = end_col
            end
            goto continue
        end

        local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
        if #lines == 0 then
            break
        end

        if start_row > start_row_func_name then
            is_multiline = true
        end

        local word = vim.trim(lines[1]:sub(start_col, end_col))

        if combine_with_previous then
            local previous_word = table.remove(words)
            word = previous_word .. " " .. word
            combine_with_previous = false
        end
        table.insert(words, word)

        if child:type() == 'parameter_modifiers' then
            combine_with_previous = true
        end

        ::continue::
    end

    local new_lines = {}

    if is_multiline then
        -- Convert to single line
        new_lines[1] =  '(' .. table.concat(words, ", ") .. ')'
    else
        -- Convert to multiline
        local indent = string.rep(' ', vim.fn.indent(start_row_func_name + 1))
        local indent_params = string.rep(' ', vim.fn.indent(start_row_func_name + 1) + vim.o.sw)

        new_lines[1] = "(" -- initial newline
        for i, param in ipairs(words) do
            local value
            if i == 1 and vim.startswith(param, "(") then
                -- Strip leading '(' from first parameter
                value = indent_params .. param:sub(2, #param)
            elseif vim.startswith(param, ",") then
                -- ',' can be part of the parameter in some cases
                value = indent_params .. param:sub(2, #param)
            else
                value = indent_params .. param
            end

            if i < #words or vim.tbl_contains(config.trailing_comma_filetypes, vim.o.ft) then
                value = value .. ","
            end
            table.insert(new_lines, value)
        end
        table.insert(new_lines, indent .. ')') -- closing bracket on newline
    end

    vim.api.nvim_buf_set_text(
        0,
        start_row_func_name,
        start_col_func_name,
        end_row_func_name,
        end_col_func_name,
        new_lines
    )
end

-- Convert from a bash command to an exec(...) array
local function convert_to_exec_array()
    local line = vim.api.nvim_get_current_line()
    local lnum = vim.fn.line('.')

    local parser = vim.treesitter.get_string_parser(line, "bash", nil)
    local tree = parser:parse({0, 1})[1]
    -- The root node is a "program", we want to pass the first "command"
    ---@diagnostic disable-next-line: missing-parameter
    local node = tree:root():child()

    local words = get_child_values_from_line(node, line)

    if #words == 0 then
        return
    end

    -- Quote every word
    for i,word in ipairs(words) do
        if not vim.startswith(word, '"') then
            words[i] = '"' .. word .. '"'
        end
    end

    local indent = string.rep(' ', vim.fn.indent(lnum))
    local open_bracket, close_bracket

    if vim.tbl_contains(config.curly_bracket_filetypes, vim.o.ft) then
        open_bracket = '{'
        close_bracket = '}'
    else
        open_bracket = '['
        close_bracket = ']'
    end
    local new_line = indent .. open_bracket .. vim.fn.join(words, ', ') .. close_bracket

    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, true, {new_line})
end

-- Convert an exec(...) array on the *current line* to a bash command
-- Note: we do not rely on treesitter here, any "array" format will do.
local function convert_to_bash_command()
    local line = vim.api.nvim_get_current_line()
    local lnum = vim.fn.line('.')

    if #line < 3 then
        return
    end

    -- Remove everything before/after the array markers in the first line
    local start_index, _, _  = line:find("[%[%{]")
    local end_index, _, _  = line:find("[%]%}]")
    line = line:sub(start_index + 1, end_index - 1)

    local words = vim.split(line, ',')
    for i,word in pairs(words) do
        -- Remove quotes around each argument and all extra spacing
        words[i] = vim.trim(word):gsub("^['\"]", '')
                                 :gsub("['\"]$", '')
                                 :gsub('%s+', ' ')
    end

    local start_row = lnum - 1
    local end_row = start_row + 1
    local indent = string.rep(' ', vim.fn.indent(lnum))

    local outline = indent .. vim.fn.join(words, ' ')
    vim.api.nvim_buf_set_lines(0, start_row, end_row, true, {outline})
end

--------------------------------------------------------------------------------

function M.convert_between_command_and_exec_array()
    -- Only parse the current line
    local line = vim.api.nvim_get_current_line()

    -- Convert into a command if the line contains '[' or '{'
    local start_index, _, _ = line:find('[%[%{]')
    if start_index ~= nil then
        convert_to_bash_command()
    else
        convert_to_exec_array()
    end
end

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

function M.convert_between_single_and_multiline_argument_lists()
    if vim.tbl_contains({'', 'text'}, vim.o.ft) then
        -- Parse entire file as bash for '[No Name]' and plaintext buffers
        vim.o.ft = 'bash'
    end

    if vim.tbl_contains(config.shell_filetypes, vim.o.ft) then
        convert_between_single_and_multiline_bash()
    else
        convert_between_single_and_multiline()
    end
end

---@param user_opts RefmtOptions?
function M.setup(user_opts)
    config.setup(user_opts)
end

return M
