require('refmt').setup {}

local M = {}

local tsst = require 'tsst'

M.testcases = {}

-- Add required parsers
vim.treesitter.language.add('bash', { path = "./tests/parser/bash.so" })
vim.treesitter.language.register("bash", "sh")

M.before_each = function()
    -- Close all open files
    repeat
        vim.cmd [[bd!]]
    until vim.fn.expand '%' == ''

    -- Restore files
    vim.system({ 'git', 'checkout', 'tests/files' }):wait()
end

table.insert(M.testcases, {
    desc = 'Convert from a bash command to an exec(...) array in a shell script',
    fn = function()
        vim.cmd [[edit tests/files/exec_array_input.sh]]

        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        require('refmt').convert_to_exec_array()

        vim.cmd [[silent write!]]
        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        tsst.assert_eql_file("tests/files/exec_array_output.sh", lines)
    end,
})

table.insert(M.testcases, {
    desc = 'Convert between bash commands and exec(...) arrays in a python script',
    fn = function()
        vim.cmd [[edit tests/files/exec_array_input.py]]

        -- Convert first line to bash statement
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        require('refmt').convert_to_bash_command()

        -- Convert same line with indentation to bash statement
        vim.api.nvim_win_set_cursor(0, { 4, 0 })
        require('refmt').convert_to_bash_command()

        -- Convert bash statement into exec(...) array
        vim.api.nvim_win_set_cursor(0, { 7, 0 })
        require('refmt').convert_to_exec_array()

        vim.cmd [[silent write!]]
        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        tsst.assert_eql_file("tests/files/exec_array_output.py", lines)
    end,
})

-- table.insert(M.testcases, {
--     desc = 'Convert from an exec(...) array to a bash command in a shell script',
--     fn = function()
--         -- XXX: inverse check
--         vim.cmd [[edit tests/files/exec_array_output.sh]]

--         vim.api.nvim_win_set_cursor(0, { 1, 0 })
--         require('refmt').convert_to_bash_command()

--         vim.cmd [[silent write!]]
--         local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

--         tsst.assert_eql_file("tests/files/exec_array_input.sh", lines)
--     end,
-- })


return M
