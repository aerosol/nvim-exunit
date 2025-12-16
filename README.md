# nvim-exunit

Opinionated ExUnit test runner for NeoVim

## Features

- Quick keymaps to run tests at cursor, module, project and jump to output (maintains a dedicated tab for it)
- Populates location list
  - automatically opens it on failure, unless the current buffer is on the list already
  - automatically closes it on success
- Places signs on stacktrace items
- Displays statusline progress + notifications

### Demo

https://github.com/user-attachments/assets/beabc682-c060-4605-8374-b6cc1508a110

## Default keymaps

<kbd>tt</kbd> - test under cursor

<kbd>tf</kbd> - test current module

<kbd>tF</kbd> - test current module with `--trace`

<kbd>ta</kbd> - test all, but stop at first failure

<kbd>tA</kbd> - test all, no failure limit

<kbd>tl</kbd> - repeat last test run

<kbd>gto</kbd> - go to test output tab

## Install

```lua
	{
		"aerosol/nvim-exunit",
		config = true
	}
```

Setup options:

```lua
{
	-- https://github.com/aerosol/nvim-exunit/blob/main/lua/exunit/keymaps.lua
	own_keymaps = false,
	-- opens location list, if current buffer isn't under test
	-- available options: 
	--  "focus" - automatically switch to location list window
	--  "manual" - populates the list but doesn't invoke anything
	location_list_mode = "open_no_focus",
	-- customize icons
	running_icons = { "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" },
	success_icon = "✅",
	failure_icon = "❌",
}
end
```

### Statusline integration

```lua
vim.o.statusline = "%{%v:lua.require'exunit'.statusline()%}"
```
