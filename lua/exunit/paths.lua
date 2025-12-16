local M = {}

function M.is_elixir_test_file(path)
	return path and path:match("%.exs?$") ~= nil
end

function M.get_full_path(relative_path)
	return vim.fn.getcwd() .. "/" .. relative_path
end

function M.is_file_readable(path)
	return vim.fn.filereadable(path) == 1
end

return M
