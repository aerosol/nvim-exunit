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

		it("should have running_icons set to moon phases", function()
			assert.are.same({ "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" }, config.defaults.running_icons)
		end)

		it("should have failure_icon set to ❌", function()
			assert.equals("❌", config.defaults.failure_icon)
		end)

		it("should have success_icon set to ✅", function()
			assert.equals("✅", config.defaults.success_icon)
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

		it("should allow overriding running_icons", function()
			local custom_icons = { "a", "b", "c" }
			local result = config.setup({ running_icons = custom_icons })
			assert.are.same(custom_icons, result.running_icons)
		end)

		it("should allow overriding failure_icon", function()
			local result = config.setup({ failure_icon = "X" })
			assert.equals("X", result.failure_icon)
		end)

		it("should allow overriding success_icon", function()
			local result = config.setup({ success_icon = "+" })
			assert.equals("+", result.success_icon)
		end)
	end)
end)
