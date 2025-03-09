require('refmt').setup {}

local M = {}

local tsst = require 'tsst'
local fixture = require 'tests.fixture'

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Unfold and refold list declaration in lua',
    fn = function()
        fixture.check_apply_and_revert(
            "tests/files/list_input.lua",
            "tests/files/list_output.lua",
            {2, 34},
            {3, 11},
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

return M
