require('refmt').setup({})

local M = {}

local fixture = require('tests.fixture')

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Unfold and refold element in html',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/element_input.html',
            'tests/files/element_output.html',
            { 5, 10 },
            { 5, 10 },
            require('refmt').convert_between_single_and_multiline_element
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold element in xml',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/element_input.xml',
            'tests/files/element_output.xml',
            { 12, 16 },
            { 12, 16 },
            require('refmt').convert_between_single_and_multiline_element
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold element in svelte',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/element_input.svelte',
            'tests/files/element_output.svelte',
            { 2, 10 },
            { 2, 10 },
            require('refmt').convert_between_single_and_multiline_element
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Fold element with multiline attribute in svelte',
    fn = function()
        fixture.check_apply(
            'tests/files/element_input_1.svelte',
            'tests/files/element_input.svelte', -- XXX
            { 2, 10 },
            require('refmt').convert_between_single_and_multiline_element
        )
    end,
})

return M
