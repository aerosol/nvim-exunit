local runner = require("exunit.runner")

describe("runner", function()
	local ui_mock

	before_each(function()
		package.loaded["exunit.ui"] = nil
		package.loaded["exunit.runner"] = nil

		ui_mock = {
			close_runner_buffer = function() end,
			open_runner_tab = function() end,
			go_back_to_previous_tab = function() end,
		}

		package.preload["exunit.ui"] = function()
			return ui_mock
		end

		runner = require("exunit.runner")
	end)

	after_each(function()
		package.preload["exunit.ui"] = nil
	end)

	describe("status", function()
		it("should return default status when no job has run", function()
			local status = runner.status()
			assert.is_false(status.running)
			assert.is_nil(status.exit_code)
			assert.is_nil(status.cmd)
			assert.is_nil(status.id)
			assert.is_nil(status.output)
		end)
	end)

	describe("run_last", function()
		it("should notify when no last command exists", function()
			local notified = false
			local original_notify = vim.notify
			vim.notify = function(msg, level)
				notified = true
			end

			runner.run_last("nonexistent")

			vim.notify = original_notify
			assert.is_true(notified)
		end)
	end)
end)
