local M = {}

local config = require 'refmt.config'

---@param user_opts RefmtOptions?
function M.setup(user_opts)
    config.setup(user_opts)
end

return M

