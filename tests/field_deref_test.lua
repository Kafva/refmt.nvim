require('refmt').setup({})

local M = {}

local fixture = require('tests.fixture')

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Unfold and refold field dereferencing in rust',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input.rs',
            'tests/files/field_multiline_deref_output.rs',
            { 1, 1 },
            { 1, 1 },
            require('refmt').convert_between_single_and_multiline_deref
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold field dereferencing in python',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input.py',
            'tests/files/field_multiline_deref_output.py',
            { 1, 1 },
            { 1, 1 },
            require('refmt').convert_between_single_and_multiline_deref
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold field dereferencing in javascript',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input.js',
            'tests/files/field_multiline_deref_output.js',
            { 3, 9 },
            { 3, 9 },
            require('refmt').convert_between_single_and_multiline_deref
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold embedded field dereferencing in tsx',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input.tsx',
            'tests/files/field_multiline_deref_output.tsx',
            { 2, 23 },
            { 2, 23 },
            require('refmt').convert_between_single_and_multiline_deref
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold field dereferencing in lua',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input.lua',
            'tests/files/field_multiline_deref_output.lua',
            { 2, 15 },
            { 2, 15 },
            require('refmt').convert_between_single_and_multiline_deref
        )
    end,
})

return M
