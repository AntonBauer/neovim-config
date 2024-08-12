return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"Issafalcon/neotest-dotnet",
		{
			"andythigpen/nvim-coverage",
			config = function()
				require("coverage").setup({})
			end,
		},
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-dotnet")({
					dap = {
						-- Extra arguments for nvim-dap configuration
						-- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
						args = { justMyCode = false },
						adapter_name = "coreclr",
					},
					-- Let the test-discovery know about your custom attributes (otherwise tests will not be picked up)
					-- Note: Only custom attributes for non-parameterized tests should be added here. See the support note about parameterized tests
					custom_attributes = {
						xunit = { "MyCustomFactAttribute" },
						nunit = { "MyCustomTestAttribute" },
						mstest = { "MyCustomTestMethodAttribute" },
					},
					-- Provide any additional "dotnet test" CLI commands here. These will be applied to ALL test runs performed via neotest. These need to be a table of strings, ideally with one key-value pair per item.
					dotnet_additional_args = {
						"--verbosity detailed",
					},
					-- Tell neotest-dotnet to use either solution (requires .sln file) or project (requires .csproj or .fsproj file) as project root
					-- Note: If neovim is opened from the solution root, using the 'project' setting may sometimes find all nested projects, however,
					--       to locate all test projects in the solution more reliably (if a .sln file is present) then 'solution' is better.
					discovery_root = "solution",
				}),
			},

			-- Keybindings
			vim.keymap.set("n", "<leader>tf", function()
				require("neotest").run.run(vim.fn.expand("%"))
			end, { desc = "[T]est [F]ile" }),

			vim.keymap.set("n", "<leader>tn", function()
				require("neotest").run.run()
			end, { desc = "[T]est [N]earest" }),

			vim.keymap.set("n", "<leader>td", function()
				require("neotest").run.run({ strategy = "dap" })
			end, { desc = "[T]est [D]ebug nearest" }),

			vim.keymap.set("n", "<leader>to", function()
				require("neotest").output_panel.open()
			end, { desc = "[T]est [O]output" }),

			vim.keymap.set("n", "<leader>ts", function()
				require("neotest").summary.toggle()
			end, { desc = "[T]est [S]ummary" }),

			vim.keymap.set("n", "<leader>tw", function()
				require("neotest").watch.toggle()
			end, { desc = "[T]est [W]atch" }),
		})
	end,
}
