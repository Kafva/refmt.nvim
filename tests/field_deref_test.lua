require('refmt').setup({})

local M = {}

local tsst = require('tsst')
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
    desc = 'Unfold and refold field dereferencing in c',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input.c',
            'tests/files/field_multiline_deref_output.c',
            { 2, 15 },
            { 2, 15 },
            require('refmt').convert_between_single_and_multiline_deref
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold field dereferencing in c++',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input.cc',
            'tests/files/field_multiline_deref_output.cc',
            { 2, 14 },
            { 2, 14 },
            require('refmt').convert_between_single_and_multiline_deref
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold field dereferencing in zig',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input.zig',
            'tests/files/field_multiline_deref_output.zig',
            { 1, 26 },
            { 1, 26 },
            require('refmt').convert_between_single_and_multiline_deref
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold field dereferencing in swift',
    fn = function()
        if vim.fn.has('mac') == 0 then
            return tsst.skip()
        end
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input.swift',
            'tests/files/field_multiline_deref_output.swift',
            { 2, 13 },
            { 2, 13 },
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
    desc = 'Unfold and refold embedded field dereferencing in javascript',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input_1.js',
            'tests/files/field_multiline_deref_output_1.js',
            { 2, 20 },
            { 2, 20 },
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
    desc = 'Unfold and refold field dereferencing in kotlin',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/field_multiline_deref_input.kt',
            'tests/files/field_multiline_deref_output.kt',
            { 1, 21 },
            { 1, 21 },
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

table.insert(M.testcases, {
    desc = 'Fold field dereferencing over multiple lines in rust',
    fn = function()
        fixture.check_apply(
            'tests/files/field_multiline_deref_input_1.rs',
            'tests/files/field_multiline_deref_output_1.rs',
            { 1, 1 },
            require('refmt').convert_between_single_and_multiline_deref
        )
    end,
})

return M
