return {
	"iabdelkareem/csharp.nvim",
	dependencies = {
		"williamboman/mason.nvim", -- Required, automatically installs omnisharp
		"mfussenegger/nvim-dap",
		"Tastyep/structlog.nvim", -- Optional, but highly recommended for debugging
	},
	config = function()
		require("mason").setup() -- Mason setup must run before csharp
		require("csharp").setup()

		-- vim.keymap.set("n", "<F5>", function()
		-- 	require("csharp").debug_project()
		-- end, { desc = "Debug project" })

		vim.keymap.set("n", "<leader>fu", function()
			require("csharp").fix_usings()
		end, { desc = "[F]ix [U]sings" })

		vim.keymap.set("n", "<leader>fa", function()
			require("csharp").fix_all()
		end, { desc = "[F]ix [A]ll" })
	end,
}
