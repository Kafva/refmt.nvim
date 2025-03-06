M = {}

local tsst = require 'tsst'

function M.load_parsers()
    -- Load all required parsers
    vim.treesitter.language.add('c', { path = "./tests/parser/c.so" })
    vim.treesitter.language.add('lua', { path = "./tests/parser/lua.so" })
    vim.treesitter.language.add('rust', { path = "./tests/parser/rust.so" })
    vim.treesitter.language.add('zig', { path = "./tests/parser/zig.so" })
    vim.treesitter.language.add('python', { path = "./tests/parser/python.so" })
    vim.treesitter.language.add('typescript', { path = "./tests/parser/typescript.so" })
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
---@param fn function
---@param revert_fn? function
function M.check_apply_and_revert(inputfile, outputfile, before_pos, after_pos, fn, revert_fn)
    vim.cmd("edit " .. inputfile)
    local initial_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

    -- Apply function
    vim.api.nvim_win_set_cursor(0, before_pos)
    fn()

    -- XXX: `nvim_buf_get_lines()` truncates long lines...
    local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
    tsst.assert_eql_file(outputfile, lines)

    -- Revert and check against original content
    M.check_reverted(
        inputfile,
        initial_lines,
        after_pos,
        revert_fn or fn
    )
end


return M
