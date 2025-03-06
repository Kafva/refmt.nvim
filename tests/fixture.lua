M = {}

local tsst = require 'tsst'

function M.load_parsers()
    -- Load all required parsers
    vim.treesitter.language.add('c', { path = "./tests/parser/c.so" })
    vim.treesitter.language.add('lua', { path = "./tests/parser/lua.so" })
    vim.treesitter.language.add('rust', { path = "./tests/parser/rust.so" })
    vim.treesitter.language.add('zig', { path = "./tests/parser/zig.so" })
    vim.treesitter.language.add('python', { path = "./tests/parser/python.so" })
    vim.treesitter.language.add('bash', { path = "./tests/parser/bash.so" })

    vim.treesitter.language.register("bash", "sh")
end

function M.before_each()
    -- Close all open files
    repeat
        vim.cmd [[bd!]]
    until vim.fn.expand '%' == ''

    -- Restore files
    vim.system({ 'git', 'checkout', 'tests/files' }):wait()

    -- Some translations are based of a preset shiftwidth
    vim.o.sw = 4
end

---@param inputfile string
---@param initial_lines string[]
---@param pos integer[]
---@param revert_fn function
function M.check_reverted(inputfile, initial_lines, pos, revert_fn)
    -- Reopen the inputfile to avoid timing issues
    vim.cmd "silent write"
    vim.cmd "bd"
    vim.cmd("edit " .. inputfile)

    -- Revert with the provided function
    vim.api.nvim_win_set_cursor(0, pos)
    revert_fn()

    -- Check reverted output with original lines
    local reverted_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
    tsst.assert_eql_tables(initial_lines, reverted_lines)
end

---@param inputfile string
---@param outputfile string
---@param before_pos integer[]
---@param after_pos integer[]
function M.check_refold(inputfile, outputfile, before_pos, after_pos)
    vim.cmd("edit " .. inputfile)
    local initial_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

    -- Unfold into multiple lines
    vim.api.nvim_win_set_cursor(0, before_pos)
    require('refmt').convert_between_single_and_multiline_argument_lists()

    -- XXX: `nvim_buf_get_lines()` truncates long lines...
    local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
    tsst.assert_eql_file(outputfile, lines)

    -- Revert and check against original content
    M.check_reverted(
        inputfile,
        initial_lines,
        after_pos,
        require('refmt').convert_between_single_and_multiline_argument_lists
    )
end


return M
