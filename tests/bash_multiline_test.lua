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
    desc = 'Unfold and refold single line command',
    fn = function()
        vim.cmd [[edit tests/files/bash_multiline_input.sh]]
        local initial_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        -- Fold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        require('refmt').convert_between_single_and_multiline_bash_command()

        -- XXX: `nvim_buf_get_lines()` truncates long lines...
        vim.cmd [[silent write!]]
        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        tsst.assert_eql_file("tests/files/bash_multiline_output.sh", lines)

        -- Revert: TODO timing issue
        -- vim.api.nvim_win_set_cursor(0, { 1, 0 })
        -- require('refmt').convert_between_single_and_multiline_bash_command()

        -- vim.cmd [[silent write!]]
        -- local reverted_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        -- tsst.assert_eql_tables(initial_lines, reverted_lines)
    end,
})

return M
