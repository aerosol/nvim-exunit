.PHONY: test test-quiet setup clean

test: plenary.nvim
	@echo "Running tests with plenary.nvim..."
	@nvim --headless --noplugin -u scripts/minimal_init.vim \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'scripts/minimal_init.vim' }" 2>&1 \
		| grep -E "(Testing:|Success:|Failed :|Errors :|FAIL|We had an unexpected error)" || true

test-verbose: plenary.nvim
	@echo "Running tests with plenary.nvim..."
	@nvim --headless --noplugin -u scripts/minimal_init.vim \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'scripts/minimal_init.vim' }"


plenary.nvim:
	@echo "Cloning plenary.nvim..."
	@git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git plenary.nvim

setup: plenary.nvim
	@echo "Setup complete!"

clean:
	@echo "Removing plenary.nvim..."
	@rm -rf plenary.nvim
