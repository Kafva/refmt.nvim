local M = {}

local config = require('refmt.config')

function M.convert_between_command_and_exec_array()
    -- Only parse the current line
    local line = vim.api.nvim_get_current_line()

    -- Convert into a command if the line contains '[' or '{'
    local start_index, _, _ = line:find('[%[%{]')
    if start_index ~= nil then
        require('refmt.convert_array').convert_to_bash_command()
    else
        require('refmt.convert_array').convert_to_exec_array()
    end
end

-- Toggle between a single line argument list and a multiline list of child
-- nodes in an expression.
function M.convert_between_single_and_multiline_parameter_lists()
    if vim.tbl_contains({ '', 'text' }, vim.o.ft) then
        -- Parse entire file as bash for '[No Name]' and plaintext buffers
        vim.o.ft = 'bash'
    end

    if vim.tbl_contains(config.shell_filetypes, vim.o.ft) then
        require('refmt.convert_single_multiline').convert_between_single_and_multiline_bash()
    else
        require('refmt.convert_single_multiline').convert_between_single_and_multiline()
    end
end

function M.convert_comment_slash_to_asterisk()
    require('refmt.convert_comment').convert_comment_slash_to_asterisk()
end

---@param user_opts RefmtOptions?
function M.setup(user_opts)
    config.setup(user_opts)
end

return M
