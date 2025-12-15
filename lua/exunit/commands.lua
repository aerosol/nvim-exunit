local runner = require("exunit.runner")
local ui = require("exunit.ui")

local RUNNER_ID = "mix test"

local M = {}

function M.test_all()
	runner.run({
		id = RUNNER_ID,
		cmd = "mix test --max-failures=1 --warnings-as-errors",
		label = "test all",
	})
end

function M.test_all_no_limit()
	runner.run({
		id = RUNNER_ID,
		cmd = "mix test --warnings-as-errors",
		label = "test all (no limit)",
	})
end

function M.test_current()
	local current_file = vim.fn.expand("%:.")
	local label = vim.fn.expand("%:t")
	runner.run({
		id = RUNNER_ID,
		cmd = "mix test " .. current_file,
		label = "test " .. label,
	})
end

function M.test_current_trace()
	local current_file = vim.fn.expand("%:.")
	local label = vim.fn.expand("%:t")
	runner.run({
		id = RUNNER_ID,
		cmd = "mix test " .. current_file .. " --trace",
		label = "trace " .. label,
	})
end

function M.test_under_cursor()
	local current_file = vim.fn.expand("%:.")
	local current_line = vim.fn.line(".")
	local label = vim.fn.expand("%:t")
	local file_line = string.format("%s:%d", current_file, current_line)
	runner.run({
		id = RUNNER_ID,
		cmd = "mix test " .. file_line,
		label = "test " .. label .. ":" .. current_line,
	})
end

function M.test_last()
	runner.run_last(RUNNER_ID)
end

function M.goto_output()
	ui.switch_to_output_tab()
end

return M
