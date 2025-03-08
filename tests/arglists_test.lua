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
        fixture.check_apply_and_revert(
            "tests/files/arglists_input.zig",
            "tests/files/arglists_output.zig",
            {3, 17},
            {4, 12},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in rust',
    fn = function()
        fixture.check_apply_and_revert(
            "tests/files/arglists_input.rs",
            "tests/files/arglists_output.rs",
            {2, 17},
            {3, 12},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in java',
    fn = function()
        fixture.check_apply_and_revert(
            "tests/files/arglists_input.java",
            "tests/files/arglists_output.java",
            {2, 77},
            {3, 9},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

-- TODO
-- table.insert(M.testcases, {
--     desc = 'Unfold and refold method parameters in swift',
--     fn = function()
--         fixture.check_apply_and_revert(
--             "tests/files/arglists_input.swift",
--             "tests/files/arglists_output.swift",
--             {3, 23},
--             {3, 11},
--             require('refmt').convert_between_single_and_multiline_argument_lists
--         )
--     end,
-- })

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in kotlin',
    fn = function()
        fixture.check_apply_and_revert(
            "tests/files/arglists_input.kt",
            "tests/files/arglists_output.kt",
            {6, 58},
            {7, 15},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in c++',
    fn = function()
        fixture.check_apply_and_revert(
            "tests/files/arglists_input.cpp",
            "tests/files/arglists_output.cpp",
            {2, 21},
            {3, 11},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in typescript',
    fn = function()
        fixture.check_apply_and_revert(
            "tests/files/arglists_input.ts",
            "tests/files/arglists_output.ts",
            {2, 18},
            {4, 10},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold function parameters with spacing in python',
    fn = function()
        vim.cmd "edit tests/files/arglists_spaced_input.py"

        vim.api.nvim_win_set_cursor(0, { 1, 43 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/arglists_output.py", lines)
    end,
})

return M
