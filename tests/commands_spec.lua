local commands = require("exunit.commands")

describe("commands", function()
	local runner_mock

	before_each(function()
		package.loaded["exunit.runner"] = nil
		package.loaded["exunit.commands"] = nil
		
		runner_mock = {
			run = function() end,
			run_last = function() end,
			calls = {}
		}
		
		package.preload["exunit.runner"] = function()
			return runner_mock
		end
		
		commands = require("exunit.commands")
	end)

	after_each(function()
		package.preload["exunit.runner"] = nil
	end)

	describe("test_all", function()
		it("should call runner.run with correct arguments", function()
			local called = false
			local captured_args
			runner_mock.run = function(args)
				called = true
				captured_args = args
			end

			commands.test_all()

			assert.is_true(called)
			assert.equals("mix test", captured_args.id)
			assert.equals("mix test --max-failures=1 --warnings-as-errors", captured_args.cmd)
			assert.equals("test all", captured_args.label)
		end)
	end)

	describe("test_last", function()
		it("should call runner.run_last with correct id", function()
			local called = false
			local captured_id
			runner_mock.run_last = function(id)
				called = true
				captured_id = id
			end

			commands.test_last()

			assert.is_true(called)
			assert.equals("mix test", captured_id)
		end)
	end)
end)
