local M = {}

local function _getOmnisharpClient(buffer)
	local clients = vim.lsp.get_clients({ bufnr = buffer })
	for _, client in ipairs(clients) do
		if client.name == "omnisharp" then
			return client
		end
	end
end

local function _getWorkspaceInformation()
	local buffer = vim.api.nvim_get_current_buf()
	local omnisharpClient = _getOmnisharpClient(buffer)
	if omnisharpClient == nil then
		vim.print("Omnisharp isn't attached to buffer")
		return
	end

	local request_method = "c#/projects"
	local request = {
		ExcludeSourceFiles = true,
	}
	local response = omnisharpClient.request_sync(request_method, request, 1000, buffer)
	if response == nil then
		vim.print("Error: response is null")
		return
	end

	if response.err ~= nil then
		vim.print("Got error response from Omnisharp")
	end

	return response.result
end

local function _selectProject(projects)
	local co = assert(coroutine.running())
	local opts = {
		prompt = "Select project:",
		format_item = function(project)
			return project.AssemblyName
		end,
	}
	vim.schedule(function()
		vim.ui.select(projects, opts, function(selected)
			coroutine.resume(co, selected)
		end)
	end)

	return coroutine.yield()
end

local function _findProject()
	local workspaceInfo = _getWorkspaceInformation()
	if workspaceInfo == nil then
		vim.print("Error: fetch workspace information failed")
		return
	end

	local executableProjects = {}

	for _, project in ipairs(workspaceInfo.MsBuild.Projects) do
		if project.IsExe then
			table.insert(executableProjects, project)
		end
	end

	if #executableProjects == 0 then
		vim.print("Error: no executable project found")
		return
	else
		return _selectProject(executableProjects)
		-- elseif #executableProjects == 1 then
		-- 	return executableProjects[1]
		-- else
		-- 	return _selectProject(executableProjects)
	end
end

local function _buildProject()
	local default_path = vim.fn.getcwd() .. "/"
	if vim.g["dotnet_last_proj_path"] ~= nil then
		default_path = vim.g["dotnet_last_proj_path"]
	end

	local path = vim.fn.input("Path to your *proj file", default_path, "file")
	vim.g["dotnet_last_proj_path"] = path
	local cmd = "dotnet build -c Debug " .. path .. " > /dev/null"
	print("")
	print("Cmd to execute: " .. cmd)
	local f = os.execute(cmd)
	if f == 0 then
		print("\nBuild: ✔️ ")
	else
		print("\nBuild: ❌ (code: " .. f .. ")")
	end
end

local function _getDllPath()
	local request = function()
		return vim.fn.input("Path to dll", vim.fn.getcwd() .. "/bin/Debug/", "file")
	end

	if vim.g["dotnet_last_dll_path"] == nil then
		vim.g["dotnet_last_dll_path"] = request()
	else
		if
			vim.fn.confirm("Do you want to change the path to dll?\n" .. vim.g["dotnet_last_dll_path"], "&yes\n&no", 2)
			== 1
		then
			vim.g["dotnet_last_dll_path"] = request()
		end
	end

	return vim.g["dotnet_last_dll_path"]
end

function M.setupDebug(dap)
	vim.g.dotnet_build_project = _buildProject
	vim.g.dotnet_get_dll_path = _getDllPath

	local config = {
		{
			type = "coreclr",
			name = "launch - netcoredbg",
			request = "launch",
			program = function()
				local project = _findProject()
				vim.print(project)

				vim.g.dotnet_build_project()
				return vim.g.dotnet_get_dll_path()
			end,
		},
	}

	dap.configurations.cs = config
	dap.configurations.fsharp = config
end

return M
