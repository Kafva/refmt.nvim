require('refmt').setup({})

local M = {}

local tsst = require('tsst')
local fixture = require('tests.fixture')

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in c',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/func_call_input.c',
            'tests/files/func_call_output.c',
            { 4, 25 },
            { 6, 10 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in typescript',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/func_call_input.ts',
            'tests/files/func_call_output.ts',
            { 1, 14 },
            { 3, 15 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in typescript with object argument',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/func_call_input_2.ts',
            'tests/files/func_call_output_2.ts',
            { 1, 29 },
            { 2, 1 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in lua',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/func_call_input.lua',
            'tests/files/func_call_output.lua',
            { 5, 66 },
            { 6, 12 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in bash',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/func_call_input.sh',
            'tests/files/func_call_output.sh',
            { 1, 0 },
            { 1, 0 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold subshell function call in bash',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/func_call_input_1.sh',
            'tests/files/func_call_output_1.sh',
            { 2, 21 },
            { 3, 15 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in swift',
    fn = function()
        if vim.fn.has('mac') == 0 then
            return tsst.skip()
        end
        fixture.check_apply_and_revert(
            'tests/files/func_call_input.swift',
            'tests/files/func_call_output.swift',
            { 1, 92 },
            { 3, 7 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in zig',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/func_call_input.zig',
            'tests/files/func_call_output.zig',
            { 2, 52 },
            { 4, 2 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold and refold function call in go',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/func_call_input.go',
            'tests/files/func_call_output.go',
            { 9, 34 },
            { 10, 13 },
            require('refmt').convert_between_single_and_multiline_parameter_lists
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Fold function with first argument on same line in typescript',
    fn = function()
        vim.cmd('edit tests/files/func_call_input_1.ts')

        vim.api.nvim_win_set_cursor(0, { 1, 19 })
        require('refmt').convert_between_single_and_multiline_parameter_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file('tests/files/func_call_output_1.ts', lines)
    end,
})

table.insert(M.testcases, {
    desc = 'Fold function call in typescript with multiline object',
    fn = function()
        vim.cmd('edit tests/files/func_call_input_bad_line_break.ts')

        vim.api.nvim_win_set_cursor(0, { 1, 29 })
        require('refmt').convert_between_single_and_multiline_parameter_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        -- XXX: 'input' version is on one-line
        tsst.assert_eql_file('tests/files/func_call_input_2.ts', lines)
    end,
})

table.insert(M.testcases, {
    desc = 'Fold function call in typescript with multiline object and curly bracket on newline',
    fn = function()
        vim.cmd('edit tests/files/func_call_input_bad_line_break_2.ts')

        vim.api.nvim_win_set_cursor(0, { 1, 29 })
        require('refmt').convert_between_single_and_multiline_parameter_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        -- XXX: 'input' version is on one-line
        tsst.assert_eql_file('tests/files/func_call_input_2.ts', lines)
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold function call with bad spacing in c',
    fn = function()
        vim.cmd('edit tests/files/func_call_spaced_input.c')

        vim.api.nvim_win_set_cursor(0, { 4, 23 })
        require('refmt').convert_between_single_and_multiline_parameter_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file('tests/files/func_call_output.c', lines)
    end,
})

table.insert(M.testcases, {
    desc = 'Unfold single line command with spaces in [No name] buffer',
    fn = function()
        local initial_lines = {
            '/Applications/Firefox\\ Nightly.app/Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container -isForBrowser -prefsHandle 0 -prefsLen 38346 -prefMapHandle 1 -prefMapSize 266618 -jsInitHandle 2 -jsInitLen 258888 -sbStartup -sbAppPath /Applications/Firefox\\ Nightly.app -sbLevel 3 -parentBuildID 20250106175544 -ipcHandle 0 -initialChannelId {31effb08-7cdb-4edc-8978-fc9016400b3b} -parentPid 15911 -greomni /Applications/Firefox\\ Nightly.app/Contents/Resources/omni.ja -appomni /Applications/Firefox\\ Nightly.app/Contents/Resources/browser/omni.ja -appDir /Applications/Firefox\\ Nightly.app/Contents/Resources/browser -profile /Users/user/Library/Application Support/Firefox/Profiles/a8hixo3o.default-nightly org.mozilla.machname.1767937313 6 tab',
        }
        vim.api.nvim_buf_set_lines(0, 0, 0, false, initial_lines)

        -- Unfold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        require('refmt').convert_between_single_and_multiline_parameter_lists()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file('tests/files/func_call_noname_output.txt', lines)
    end,
})

return M
