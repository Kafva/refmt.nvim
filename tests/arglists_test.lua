require('refmt').setup {}

local M = {}

local tsst = require 'tsst'
local fixture = require 'tests.fixture'

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Unfold and refold function parameters',
    fn = function()
        vim.cmd "edit tests/files/arglists_input.zig"
        local initial_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        -- Unfold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 3, 17 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        tsst.assert_eql_file("tests/files/arglists_output.zig", lines)

        -- -- Reopen the file to avoid timing issues
        -- vim.cmd "silent write! | bd"
        -- vim.cmd "edit tests/files/arglists_input.zig"

        -- -- Revert
        -- vim.api.nvim_win_set_cursor(0, { 4, 15 })
        -- require('refmt').convert_between_single_and_multiline_argument_lists()

        -- local reverted_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        -- tsst.assert_eql_tables(initial_lines, reverted_lines)
    end,
})

return M
