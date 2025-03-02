local M = {}

-- Refactor single line argument list into multiline argument list
function M.convert_arglist()
    for i=1,100 do -- Do not loop forever in weird scenarios
    end
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

---@param single_line_content boolean
---@param node TSNode|nil
---@return table|nil, integer, integer
local function _bash_words(node, single_line_content)
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

-- Revert a list back to a bash statement
---@param lines string[]
local function _bash_unargify(lines)
    if #lines == 0 then
        return
    end

    local lnum = vim.fn.line('.')
    local out = ""

    -- Remove everything before/after the array markers in the first line
    lines[1]        = lines[1]:gsub("^[^%(%[%{]*[%(%[%{]", '')
    lines[#lines]   = lines[#lines]:gsub("[%)%}%]][^%)%]%}]*$", '')

    for _,line in pairs(lines) do
        local words = vim.split(line, ',')
        for _,word in pairs(words) do
            -- Remove quotes around each argument
            out = out .. " " .. vim.trim(word):gsub("^['\"]", '')
                                              :gsub("['\"]$", '')
        end
    end

    local start_row = lnum - 1
    local end_row = start_row + #lines
    -- Remove duplicate spacing
    local indent = string.rep(' ', vim.fn.indent(lnum))
    out =  indent ..  out:gsub('%s+', ' ')
    vim.api.nvim_buf_set_lines(0, start_row, end_row, true, {out})
end

-- Create an argument array from a bash command line
---@param single_line_content boolean
---@param node TSNode|nil
local function _bash_argify(node, single_line_content)
    local lnum = vim.fn.line('.')
    local words, _, _ = _bash_words(node, single_line_content)

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
local function _bash_fold_toggle(node, single_line_content)
    local lnum = vim.fn.line('.')
    local indent = string.rep(' ', vim.fn.indent(lnum))
    local extra_indent = string.rep(" ", 4)
    local words, start_row, end_row = _bash_words(node, single_line_content)

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
local function _bash_reformat(formatfn)
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

function M.bash_fold_toggle()
    _bash_reformat(_bash_fold_toggle)
end

function M.bash_argify()
    _bash_reformat(_bash_argify)
end

---@param content string[]
function M.bash_unargify(content)
   _bash_unargify(content)
end

return M
