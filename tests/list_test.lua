require('refmt').setup({})

local M = {}

local fixture = require('tests.fixture')
local tsst = require('tsst')

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Unfold and refold list declaration in lua',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/list_input.lua',
            'tests/files/list_output.lua',
            { 2, 34 },
            { 3, 11 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold list declaration in python',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/list_input.py',
            'tests/files/list_output.py',
            { 10, 40 },
            { 14, 22 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold list declaration in bash',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/list_input.sh',
            'tests/files/list_output.sh',
            { 2, 25 },
            { 4, 8 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold list declaration in typescript',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/list_input.ts',
            'tests/files/list_output.ts',
            { 2, 48 },
            { 4, 9 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold list declaration in zig',
    fn = function()
        if vim.fn.executable('zig') == 0 then
            -- `zig fmt` runs automatically and affects the format of the output,
            -- the tests only pass if zig is installed.
            -- See neovim/runtime/autoload/zig/fmt.vim
            return tsst.skip()
        end
        fixture.check_apply_and_revert(
            'tests/files/list_input.zig',
            'tests/files/list_output.zig',
            { 1, 22 },
            { 2, 4 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold list declaration in go',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/list_input.go',
            'tests/files/list_output.go',
            { 6, 38 },
            { 9, 7 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

return M
