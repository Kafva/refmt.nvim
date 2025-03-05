require('refmt').setup {}

local M = {}

local tsst = require 'tsst'
local fixture = require 'tests.fixture'

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Unfold function parameters in zig',
    fn = function()
        vim.cmd "edit tests/files/arglists_input.zig"

        -- Unfold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 3, 17 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/arglists_output.zig", lines)
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold method parameters in rust',
    fn = function()
        vim.cmd "edit tests/files/arglists_input.rs"

        -- Unfold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 2, 17 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/arglists_output.rs", lines)
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold function call in C',
    fn = function()
        vim.cmd "edit tests/files/func_call_input.c"

        -- Unfold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 4, 25 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/func_call_output.c", lines)
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold function call in lua',
    fn = function()
        vim.cmd "edit tests/files/func_call_input.lua"

        -- Unfold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 5, 66 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/func_call_output.lua", lines)
    end,
})

return M
