require('refmt').setup {}

local M = {}

local tsst = require 'tsst'
local fixture = require 'tests.fixture'

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Unfold and refold single line command',
    fn = function()
        vim.cmd "edit tests/files/bash_multiline_input.sh"
        local initial_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        -- Unfold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        require('refmt').convert_between_single_and_multiline_bash_command()

        -- XXX: `nvim_buf_get_lines()` truncates long lines...
        vim.cmd "silent write!"
        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        tsst.assert_eql_file("tests/files/bash_multiline_output.sh", lines)

        -- Reopen the file to avoid timing issues
        vim.cmd "bd"
        vim.cmd "edit tests/files/bash_multiline_input.sh"

        -- Revert
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        require('refmt').convert_between_single_and_multiline_bash_command()

        vim.cmd "silent write!"
        local reverted_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        tsst.assert_eql_tables(initial_lines, reverted_lines)
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
        require('refmt').convert_between_single_and_multiline_bash_command()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file("tests/files/noname_multiline_output.txt", lines)
    end,
})

return M
