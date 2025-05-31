require('refmt').setup({})

local M = {}

local tsst = require('tsst')
local fixture = require('tests.fixture')

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Unfold and refold function parameters in zig (#0)',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/arglists_input.zig',
            'tests/files/arglists_output.zig',
            { 3, 17 },
            { 4, 12 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function parameters in zig (#1)',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/arglists_input_1.zig',
            'tests/files/arglists_output_1.zig',
            { 2, 5 },
            { 1, 17 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in rust',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/arglists_input.rs',
            'tests/files/arglists_output.rs',
            { 2, 17 },
            { 3, 12 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in java',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/arglists_input.java',
            'tests/files/arglists_output.java',
            { 2, 77 },
            { 3, 9 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in swift',
    fn = function()
        if vim.fn.has('mac') == 0 then
            return tsst.skip()
        end
        fixture.check_apply_and_revert(
            'tests/files/arglists_input.swift',
            'tests/files/arglists_output.swift',
            { 4, 39 },
            { 6, 24 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in kotlin',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/arglists_input.kt',
            'tests/files/arglists_output.kt',
            { 6, 58 },
            { 7, 15 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in c++',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/arglists_input.cpp',
            'tests/files/arglists_output.cpp',
            { 2, 21 },
            { 3, 11 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in typescript',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/arglists_input.ts',
            'tests/files/arglists_output.ts',
            { 2, 18 },
            { 4, 10 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function parameters in go',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/arglists_input.go',
            'tests/files/arglists_output.go',
            { 3, 58 },
            { 5, 22 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function parameters in python (#0)',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/arglists_input.py',
            'tests/files/arglists_output.py',
            { 1, 39 },
            { 2, 7 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function parameters in python (#1)',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/arglists_input_1.py',
            'tests/files/arglists_output_1.py',
            { 1, 22 },
            { 2, 9 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold function parameters with spacing in python',
    fn = function()
        fixture.check_apply(
            'tests/files/arglists_spaced_input.py',
            'tests/files/arglists_output.py',
            { 1, 43 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

return M
