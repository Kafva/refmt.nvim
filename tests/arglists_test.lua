require('refmt').setup {}

local M = {}

local tsst = require 'tsst'
local fixture = require 'tests.fixture'

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Unfold and refold function parameters in zig',
    fn = function()
        vim.cmd "edit tests/files/arglists_input.zig"
        local initial_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        vim.api.nvim_win_set_cursor(0, { 3, 17 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/arglists_output.zig", lines)

        fixture.check_reverted(
            "tests/files/arglists_input.zig",
            initial_lines,
            {4, 12},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in rust',
    fn = function()
        vim.cmd "edit tests/files/arglists_input.rs"
        local initial_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        vim.api.nvim_win_set_cursor(0, { 2, 17 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/arglists_output.rs", lines)

        fixture.check_reverted(
            "tests/files/arglists_input.rs",
            initial_lines,
            {3, 12},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in c',
    fn = function()
        vim.cmd "edit tests/files/func_call_input.c"
        local initial_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        vim.api.nvim_win_set_cursor(0, { 4, 25 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/func_call_output.c", lines)

        fixture.check_reverted(
            "tests/files/func_call_input.c",
            initial_lines,
            {6, 10},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in lua',
    fn = function()
        vim.cmd "edit tests/files/func_call_input.lua"
        local initial_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        -- Unfold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 5, 66 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/func_call_output.lua", lines)

        fixture.check_reverted(
            "tests/files/func_call_input.lua",
            initial_lines,
            {6, 12},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold function call with bad spacing in c',
    fn = function()
        vim.cmd "edit tests/files/func_call_bad_spacing_input.c"

        vim.api.nvim_win_set_cursor(0, { 4, 23 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/func_call_output.c", lines)
    end,
})

return M
