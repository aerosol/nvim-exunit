local parser = require("exunit.parser")

describe("parser", function()
	before_each(function()
		package.loaded["exunit.parser"] = nil
		parser = require("exunit.parser")
	end)

	describe("parse_locations", function()
		it("should return empty table for nil output", function()
			local result = parser.parse_locations(nil)
			assert.are.same({}, result)
		end)

		it("should return empty table for empty output", function()
			local result = parser.parse_locations("")
			assert.are.same({}, result)
		end)

		it("should extract file path and line number from test failure", function()
			local output = [[
1) test greets the world (FooTest)
test/foo_test.exs:5
Assertion with == failed
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function(path)
					if path:match("test/foo_test%.exs$") then
						return 1
					end
					return 0
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.equals(1, #result)
			assert.equals("test/foo_test.exs", result[1].file)
			assert.equals(5, result[1].line)
		end)

		it("should extract multiple locations from stacktrace", function()
			local output = [[
1) test greets the world (FooTest)
test/foo_test.exs:5
Assertion with == failed
stacktrace:
test/foo_test.exs:6: (test)
lib/foo.ex:11: Foo (module)
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function()
					return 1
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.is_true(#result >= 2)
		end)

		it("should deduplicate same file and line", function()
			local output = [[
test/foo_test.exs:5
test/foo_test.exs:5
test/foo_test.exs:5
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function()
					return 1
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.equals(1, #result)
		end)

		it("should handle .ex and .exs files", function()
			local output = [[
lib/foo.ex:11: Foo (module)
test/foo_test.exs:5: (test)
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function()
					return 1
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.is_true(#result >= 1)
		end)

		it("should handle paths with subdirectories", function()
			local output = [[
lib/plausible_web/controllers/stats_controller.ex:1004: PlausibleWeb.Api.StatsController.exit_pages/2
test/plausible_web/controllers/stats_controller_test.exs:626
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function()
					return 1
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.is_true(#result >= 1)
		end)

		it("should handle indented stacktrace lines", function()
			local output = [[
     stacktrace:
     test/foo_test.exs:6: (test)
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function()
					return 1
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.is_true(#result >= 1)
		end)

		it("should only include files that exist", function()
			local output = [[
test/existing.exs:5
test/nonexistent.exs:10
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function(path)
					if path:match("existing%.exs$") then
						return 1
					end
					return 0
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.equals(1, #result)
			assert.equals("test/existing.exs", result[1].file)
		end)
	end)

	describe("populate_loclist", function()
		it("should clear location list when locations is nil", function()
			local old_fn = vim.fn
			local setloclist_called = false
			vim.fn = setmetatable({
				setloclist = function(nr, items)
					setloclist_called = true
					assert.equals(0, nr)
					assert.are.same({}, items)
				end,
			}, { __index = old_fn })

			parser.populate_loclist(nil)
			vim.fn = old_fn

			assert.is_true(setloclist_called)
		end)

		it("should clear location list when locations is empty", function()
			local old_fn = vim.fn
			local setloclist_called = false
			vim.fn = setmetatable({
				setloclist = function(nr, items)
					setloclist_called = true
					assert.equals(0, nr)
					assert.are.same({}, items)
				end,
			}, { __index = old_fn })

			parser.populate_loclist({})
			vim.fn = old_fn

			assert.is_true(setloclist_called)
		end)

		it("should populate location list with single location", function()
			local old_fn = vim.fn
			local items_captured = nil
			vim.fn = setmetatable({
				setloclist = function(nr, items, action, opts)
					if action == "r" then
						items_captured = items
					end
				end,
			}, { __index = old_fn })

			local locations = {
				{ file = "test/foo_test.exs", line = 5 },
			}
			parser.populate_loclist(locations)
			vim.fn = old_fn

			assert.is_not_nil(items_captured)
			assert.equals(1, #items_captured)
			assert.equals("test/foo_test.exs", items_captured[1].filename)
			assert.equals(5, items_captured[1].lnum)
			assert.equals(1, items_captured[1].col)
		end)

		it("should populate location list with multiple locations", function()
			local old_fn = vim.fn
			local items_captured = nil
			vim.fn = setmetatable({
				setloclist = function(nr, items, action, opts)
					if action == "r" then
						items_captured = items
					end
				end,
			}, { __index = old_fn })

			local locations = {
				{ file = "test/foo_test.exs", line = 5 },
				{ file = "lib/foo.ex", line = 11 },
			}
			parser.populate_loclist(locations)
			vim.fn = old_fn

			assert.is_not_nil(items_captured)
			assert.equals(2, #items_captured)
		end)

		it("should set location list title", function()
			local old_fn = vim.fn
			local title_captured = nil
			vim.fn = setmetatable({
				setloclist = function(nr, items, action, opts)
					if opts and opts.title then
						title_captured = opts.title
					end
				end,
			}, { __index = old_fn })

			local locations = {
				{ file = "test/foo_test.exs", line = 5 },
			}
			parser.populate_loclist(locations)
			vim.fn = old_fn

			assert.equals("ExUnit Test Failures", title_captured)
		end)
	end)
end)
