local config = require("exunit.config")
local commands = require("exunit.commands")
local runner = require("exunit.runner")
local ui = require("exunit.ui")
local keymaps = require("exunit.keymaps")

local M = {}

M.config = nil

function M.setup(opts)
	M.config = config.setup(opts)
	keymaps.setup_keymaps(commands, M.config)
end

function M.test_all()
	commands.test_all()
end

function M.test_current()
	commands.test_current()
end

function M.test_current_trace()
	commands.test_current_trace()
end

function M.test_under_cursor()
	commands.test_under_cursor()
end

function M.test_last()
	commands.test_last()
end

function M.goto_output()
	commands.goto_output()
end

function M.status()
	return runner.status()
end

function M.statusline()
	local status = runner.status()
	return ui.statusline(status, M.config)
end

return M
