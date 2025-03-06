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
        fixture.check_refold(
            "tests/files/arglists_input.zig",
            "tests/files/arglists_output.zig",
            {3, 17},
            {4, 12}
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold method parameters in rust',
    fn = function()
        fixture.check_refold(
            "tests/files/arglists_input.rs",
            "tests/files/arglists_output.rs",
            {2, 17},
            {3, 12}
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in c',
    fn = function()
        fixture.check_refold(
            "tests/files/func_call_input.c",
            "tests/files/func_call_output.c",
            {4, 25},
            {6, 10}
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in lua',
    fn = function()
        fixture.check_refold(
            "tests/files/func_call_input.lua",
            "tests/files/func_call_output.lua",
            {5, 66},
            {6, 12}
        )
    end,
})

-- table.insert(M.testcases, {
--     desc = 'Unfold and refold function call in python',
--     fn = function()
--         fixture.check_refold(
--             "tests/files/arglists_input.py",
--             "tests/files/arglists_output.py",
--             {1, 39},
--             {2, 7}
--         )
--     end,
-- })

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
