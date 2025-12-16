local config = require("exunit.config")
local commands = require("exunit.commands")
local runner = require("exunit.runner")
local ui = require("exunit.ui")
local keymaps = require("exunit.keymaps")

local M = {}

M.config = nil
M.test_all = commands.test_all
M.test_current = commands.test_current
M.test_current_trace = commands.test_current_trace
M.test_under_cursor = commands.test_under_cursor
M.test_last = commands.test_last
M.goto_output = commands.goto_output
M.status = runner.status

function M.setup(opts)
	M.config = config.setup(opts)
	keymaps.setup_keymaps(commands, M.config)
end

function M.statusline()
	return ui.statusline(M.status(), M.config)
end

return M
