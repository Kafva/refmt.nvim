require('refmt').setup({})

local M = {}

local tsst = require('tsst')
local fixture = require('tests.fixture')

fixture.load_parsers()

M.before_each = fixture.before_each

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Convert between bash commands and exec(...) arrays in a shell script',
    fn = function()
        fixture.check_apply_and_revert(
            'tests/files/exec_array_input.sh',
            'tests/files/exec_array_output.sh',
            { 1, 0 },
            { 1, 0 },
            require('refmt').convert_between_command_and_exec_array
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Convert between bash commands and exec(...) arrays in a python script',
    fn = function()
        vim.cmd([[edit tests/files/exec_array_input.py]])

        -- Convert first line to bash statement
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        require('refmt').convert_between_command_and_exec_array()

        -- Convert same line with indentation to bash statement
        vim.api.nvim_win_set_cursor(0, { 4, 0 })
        require('refmt').convert_between_command_and_exec_array()

        -- Convert bash statement into exec(...) array
        vim.api.nvim_win_set_cursor(0, { 7, 0 })
        require('refmt').convert_between_command_and_exec_array()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file('tests/files/exec_array_output.py', lines)
    end,
})

table.insert(M.testcases, {
    desc = 'Convert to exec(...) array in a [No name] buffer',
    fn = function()
        local initial_lines = {
            '/System/Library/Frameworks/CoreServices.framework/Frameworks/Metadata.framework/Versions/A/Support/mdbulkimport -s mdworker-bundle -c MDSImporterBundleFinder -m com.apple.metadata.mdbulkimport',
        }
        vim.api.nvim_buf_set_lines(0, 0, 0, false, initial_lines)

        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        require('refmt').convert_between_command_and_exec_array()

        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)
        tsst.assert_eql_file('tests/files/exec_array_noname_output.txt', lines)
    end,
})

return M
