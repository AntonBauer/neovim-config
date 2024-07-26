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
		print("Omnisharp isn't attached to buffer")
		return
	end

	local request_method = "o#/projects"
	local request = {
		ExcludeSourceFiles = true,
	}
	local response = omnisharpClient.request_sync(request_method, request, 10000, buffer)
	if response == nil then
		print("Error: response is null")
		return
	end

	if response.err ~= nil then
		print("Got error response from Omnisharp", response.err)
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
		print("Error: fetch workspace information failed")
		return
	end

	local executableProjects = {}

	for _, project in ipairs(workspaceInfo.MsBuild.Projects) do
		if project.IsExe then
			table.insert(executableProjects, project)
		end
	end

	if #executableProjects == 0 then
		print("Error: no executable project found")
		return
	elseif #executableProjects == 1 then
		return executableProjects[1]
	else
		return _selectProject(executableProjects)
	end
end

local function _buildProject(projectPath)
	local cmd = "dotnet build -c Debug " .. projectPath .. " > /dev/null"
	print("")
	print("Cmd to execute: " .. cmd)
	local f = os.execute(cmd)
	if f == 0 then
		print("\nBuild: ✔️ ")
	else
		print("\nBuild: ❌ (code: " .. f .. ")")
	end
end

function M.setup(dap)
	vim.g.dotnet_build_project = _buildProject

	local config = {
		{
			type = "coreclr",
			name = "launch - netcoredbg",
			request = "launch",
			program = function()
				local project = _findProject()

				if project == nil then
					print("Error: Executable project not fount")
					return
				end

				_buildProject(project.Path)
				return project.TargetPath
			end,
		},
	}

	dap.configurations.cs = config
	dap.configurations.fsharp = config
end

return M
