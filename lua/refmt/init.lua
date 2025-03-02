local M = {}

local config = require 'refmt.config'

---@param single_line_content boolean
---@param node TSNode|nil
---@return table|nil, integer, integer
local function bash_words(node, single_line_content)
    local parent, start_row, end_row, lines, start_col, end_col, words

    -- Unless a node was passed, find the first parent 'command' node for the
    -- word under the cursor
    if node == nil then
        node = vim.treesitter.get_node()
    end
    if node == nil then
        vim.notify("No command under cursor")
        return nil, -1, -1
    end
    parent = node

    while parent:type() ~= 'command' do
        parent = parent:parent()
        if parent == nil then
            vim.notify("No command under cursor")
            return nil, -1, -1
        end
    end

    -- Parse out each word
    words = {}
    for child in parent:iter_children() do
        start_row, start_col, _, end_row, end_col, _ = child:range(true)
        if single_line_content ~= nil then
            lines = { single_line_content }
        else
            lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
        end
        if #lines == 0 then
            break
        end
        local word = vim.trim(lines[1]:sub(start_col, end_col))
        table.insert(words, word)
    end

    start_row, start_col, _, end_row, end_col, _ = parent:range(true)

    return words, start_row, end_row
end

-- Create an argument array from a bash command line
---@param single_line_content boolean
---@param node TSNode|nil
local function bash_argify_fn(node, single_line_content)
    local lnum = vim.fn.line('.')
    local words, _, _ = bash_words(node, single_line_content)

    if words == nil then
        return
    end

    -- Qoute every word
    for i,word in ipairs(words) do
        if not vim.startswith(word, '"') then
            words[i] = '"' .. word .. '"'
        end
    end

    local indent = string.rep(' ', vim.fn.indent(lnum))
    local content = indent .. "{" .. vim.fn.join(words, ', ') .. "}"

    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, true, {content})
end

---@param single_line_content boolean
---@param node TSNode|nil
---@return table|nil
local function bash_fold_toggle_fn(node, single_line_content)
    local lnum = vim.fn.line('.')
    local indent = string.rep(' ', vim.fn.indent(lnum))
    local extra_indent = string.rep(" ", 4)
    local words, start_row, end_row = bash_words(node, single_line_content)

    if words == nil then
        return
    end

    if start_row == end_row then
        -- If the command spans a single line, unfold it with each argument on
        -- a seperate line
        local arr = {}

        for _,word in ipairs(words) do
            -- A flag is expected to start with '-' or '+'
            local isflag = word:match("^[-+]") ~= nil
            local prev_isflag = #arr > 0 and arr[#arr]:match("^[-+]") ~= nil
            local prev_has_arg = #arr > 0  and arr[#arr]:match(" ") ~= nil

            if not isflag and prev_isflag and not prev_has_arg then
                -- Previous word was a flag and current word is not, add as an argument
                -- unless an argument has already been provided
                arr[#arr] = arr[#arr] .. " " .. word
            else
                -- Otherwise, finish up the previous row and add the current
                -- word on a new row
                if #arr == 1 then
                    arr[#arr] = indent .. arr[#arr] .. " \\"
                elseif #arr > 1 then
                    arr[#arr] = indent .. extra_indent .. arr[#arr] .. " \\"
                end
                table.insert(arr, vim.trim(word))
            end
        end

        -- Indent last row
        arr[#arr] = indent .. extra_indent .. arr[#arr]

        vim.notify("Unfolding line " .. lnum)
        vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, true, arr)
    else
        -- If the command spans more than one row, re-format it to one line
        if #words <= 2 then
            vim.notify("Nothing to fold")
            return
        end

        vim.notify("Folding line " .. lnum)
        local replacement = { indent .. vim.fn.join(words, " ") }
        vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, replacement)
    end
end

---@param formatfn function
local function bash_reformat(formatfn)
    local node, single_line_content

    if vim.o.ft == '' then
        -- Parse entire file as bash for '[No Name]' buffers
        vim.o.ft = 'bash'
    end

    if vim.o.ft ~= 'bash' and vim.o.ft ~= 'sh' then
        -- Parse current line only
        single_line_content = vim.api.nvim_get_current_line()

        local parser = vim.treesitter.get_string_parser(single_line_content,
                                                        "bash", nil)
        local tree = parser:parse({0, 1})[1]

        -- The root node is a "program", we want to pass the first "command"
        ---@diagnostic disable-next-line: missing-parameter
        node = tree:root():child()
    end
    formatfn(node, single_line_content)
end

-- Toggle between a single line argument list and a multiline argument list
function M.convert_arglist()
    local parent_names = {
        -- Function declarations
        'parameter_list',           -- C
        'parameters',               -- Zig, Rust etc.
        -- Function calls
        'argument_list',            -- C
        'arguments',                -- Lua
    }
    local child_names = {
        -- Parameter types
        'parameter_declaration',    -- C
        'parameter',                -- Zig, Rust etc.
        -- Argument types
        'identifier', 'number', 'string'
    }
    local window = vim.api.nvim_get_current_win()
    local start_pos = vim.api.nvim_win_get_cursor(window)
    local is_multiline = false

    local node = vim.treesitter.get_node()
    if node == nil then
        vim.notify("No parameters under cursor")
        return
    end
    local parent = node

    while not vim.tbl_contains(parent_names, parent:type()) do
        ---@diagnostic disable-next-line: cast-local-type
        parent = parent:parent()
        if parent == nil then
            vim.notify("No paramters under cursor")
            return
        end
    end

    -- Parse out each parameter
    local params = {}
    local start_col_params, start_row_params, end_col_params, end_row_params
    local first = true
    for child in parent:iter_children() do
        if vim.tbl_contains(child_names, child:type()) then
            local start_row, start_col, _, end_row, end_col, _ = child:range(true)
            local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
            if #lines == 0 then
                break
            end

            if first then
                start_row_params = start_row
                start_col_params = start_col
                first = false
            end
            end_row_params = end_row
            end_col_params = end_col

            if start_row > start_pos[1] then
                is_multiline = true
            end
            local param = vim.trim(lines[1]:sub(start_col, end_col))
            -- '(' is part of the parameter list but ')' is not(?)
            if vim.startswith(param, "(") then
                param = param:sub(2, #param)
            elseif vim.endswith(param, ")") then
                param = param:sub(1, #param - 1)
            end

            table.insert(params, param)
        end
    end

    local new_lines = {}

    if is_multiline then
        -- Convert to single line
        new_lines[1] = table.concat(params, ",")
    else
        -- Convert to multiline
        local indent = string.rep(' ', vim.fn.indent(start_pos[1]))
        local indent_params = string.rep(' ', vim.fn.indent(start_pos[1] + 1))

        new_lines[1] = "" -- initial newline
        for i, param in ipairs(params) do
            local value = indent_params .. param
            if i < #params then
                value = value .. ","
            end
            table.insert(new_lines, value)
        end
        table.insert(new_lines, indent) -- closing bracket on newline
    end

    vim.api.nvim_buf_set_text(0, start_row_params, start_col_params, end_row_params, end_col_params, new_lines)
end

-- Refactor '// ... ' comments into '/** ... */'
function M.convert_comment()
    local window = vim.api.nvim_get_current_win()
    local start_pos = vim.api.nvim_win_get_cursor(window)
    local first = true
    local arr = {}
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

        table.insert(arr, indent .. " * " .. content)

        -- Move to next line
        vim.api.nvim_win_set_cursor(window, { start_pos[1] + i, 0 })
        -- Skip over leading whitespace on next line to make sure we land on
        -- the TSNode...
        vim.cmd[[silent normal! w]]
        first = false
    end

    local end_line
    if #arr == 1 then
        arr[1] = arr[1]:gsub(' %* ', '/** ') .. " */"
        end_line = start_pos[1]
    else
        table.insert(arr, 1, indent .. '/**')
        table.insert(arr, indent .. ' */')
        end_line = start_pos[1] + (#arr - 3)
    end

    vim.api.nvim_buf_set_lines(0, start_pos[1] - 1, end_line, true, arr)
end

---@param content string[]
function M.bash_unargify(content)
    if #content == 0 then
        return
    end

    local lnum = vim.fn.line('.')
    local out = ""

    -- Remove everything before/after the array markers in the first line
    content[1]        = content[1]:gsub("^[^%(%[%{]*[%(%[%{]", '')
    content[#content]   = content[#content]:gsub("[%)%}%]][^%)%]%}]*$", '')

    for _,line in pairs(content) do
        local words = vim.split(line, ',')
        for _,word in pairs(words) do
            -- Remove quotes around each argument
            out = out .. " " .. vim.trim(word):gsub("^['\"]", '')
                                              :gsub("['\"]$", '')
        end
    end

    local start_row = lnum - 1
    local end_row = start_row + #content
    -- Remove duplicate spacing
    local indent = string.rep(' ', vim.fn.indent(lnum))
    out =  indent ..  out:gsub('%s+', ' ')
    vim.api.nvim_buf_set_lines(0, start_row, end_row, true, {out})
end

function M.bash_fold_toggle()
    bash_reformat(bash_fold_toggle_fn)
end

function M.bash_argify()
    bash_reformat(bash_argify_fn)
end

---@param user_opts RefmtOptions?
function M.setup(user_opts)
    config.setup(user_opts)
end

return M

