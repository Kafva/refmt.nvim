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

return M
