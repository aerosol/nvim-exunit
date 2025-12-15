local M = {}

function M.parse_locations(output)
	if not output or output == "" then
		return {}
	end

	local locations = {}
	local seen = {}

	for line in output:gmatch("[^\r\n]+") do
		local path, line_num = line:match("^%s*([%w_/.%-]+%.exs?):(%d+)")

		if path and line_num then
			local key = path .. ":" .. line_num
			if not seen[key] then
				local full_path = vim.fn.getcwd() .. "/" .. path
				if vim.fn.filereadable(full_path) == 1 then
					table.insert(locations, {
						file = path,
						line = tonumber(line_num),
					})
					seen[key] = true
				end
			end
		end
	end

	return locations
end

function M.populate_loclist(locations)
	if not locations or #locations == 0 then
		vim.fn.setloclist(0, {})
		return
	end

	local items = {}
	for _, loc in ipairs(locations) do
		table.insert(items, {
			filename = loc.file,
			lnum = loc.line,
			col = 1,
			text = string.format("%s:%d", loc.file, loc.line),
		})
	end

	vim.fn.setloclist(0, items, "r")
	vim.fn.setloclist(0, {}, "a", { title = "ExUnit Test Failures" })
end

return M
