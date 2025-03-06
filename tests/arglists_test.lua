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
    desc = 'Unfold and refold function call in c',
    fn = function()
        fixture.check_apply_and_revert(
            "tests/files/func_call_input.c",
            "tests/files/func_call_output.c",
            {4, 25},
            {6, 10},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in lua',
    fn = function()
        fixture.check_apply_and_revert(
            "tests/files/func_call_input.lua",
            "tests/files/func_call_output.lua",
            {5, 66},
            {6, 12},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in bash',
    fn = function()
        fixture.check_apply_and_revert(
            "tests/files/arglists_input.sh",
            "tests/files/arglists_output.sh",
            {1, 0},
            {1, 0},
            require('refmt').convert_between_single_and_multiline_argument_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in python',
    fn = function()
        fixture.check_apply_and_revert(
            "tests/files/arglists_input.py",
            "tests/files/arglists_output.py",
            {1, 39},
            {2, 7},
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

table.insert(M.testcases, {
    desc = 'Unfold single line command with spaces in [No name] buffer',
    fn = function()
        local initial_lines = {
            "/Applications/Firefox\\ Nightly.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container -isForBrowser -prefsHandle 0 -prefsLen 38346 -prefMapHandle 1 -prefMapSize 266618 -jsInitHandle 2 -jsInitLen 258888 -sbStartup -sbAppPath /Applications/Firefox\\ Nightly.app -sbLevel 3 -parentBuildID 20250106175544 -ipcHandle 0 -initialChannelId {31effb08-7cdb-4edc-8978-fc9016400b3b} -parentPid 15911 -greomni /Applications/Firefox\\ Nightly.app/Contents/Resources/omni.ja -appomni /Applications/Firefox\\ Nightly.app/Contents/Resources/browser/omni.ja -appDir /Applications/Firefox\\ Nightly.app/Contents/Resources/browser -profile /Users/user/Library/Application Support/Firefox/Profiles/a8hixo3o.default-nightly org.mozilla.machname.1767937313 6 tab"
        }
        vim.api.nvim_buf_set_lines(0, 0, 0, false, initial_lines)

        -- Unfold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/func_call_noname_output.txt", lines)
    end,
})

return M
