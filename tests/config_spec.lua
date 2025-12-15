local config = require("exunit.config")

describe("config", function()
	before_each(function()
		package.loaded["exunit.config"] = nil
		config = require("exunit.config")
	end)

	describe("defaults", function()
		it("should have own_keymaps set to false", function()
			assert.is_false(config.defaults.own_keymaps)
		end)
	end)

	describe("setup", function()
		it("should return defaults when no options provided", function()
			local result = config.setup()
			assert.is_false(result.own_keymaps)
		end)

		it("should return defaults when empty table provided", function()
			local result = config.setup({})
			assert.is_false(result.own_keymaps)
		end)

		it("should merge user options with defaults", function()
			local result = config.setup({ own_keymaps = true })
			assert.is_true(result.own_keymaps)
		end)

		it("should preserve custom options", function()
			local result = config.setup({ custom_option = "value" })
			assert.equals("value", result.custom_option)
		end)
	end)
end)
