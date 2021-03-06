-- Pl/Sql Developer Lua Plug-In Addon: Scripts


-- Variables

local AddMenu, root, addonDir = ...

local plsql = plsql
local SYS, IDE, SQL = plsql.sys, plsql.ide, plsql.sql

local ShowMessage = plsql.ShowMessage


-- Execute script
do
	local menuItems = {}

	local function ExecuteScript(menuItem)
		local filename = menuItems[menuItem]
		if filename then
			filename = root .. '\\' .. addonDir
				.. '\\' .. filename
		else
			filename = plsql.GetOpenFileName("",
				"Lua Scripts (*.lua)\0*.lua\0All files\0*.*\0\0\0")
			if not filename then return end
		end

		IDE.CreateWindow(plsql.WindowType.Command,
			'plugin lua -f "' .. filename .. '"', true)
	end

	AddMenu(ExecuteScript, "Lua / Scripts / Execute File")

	-- Traverse scripts directory
	for name, is_dir in sys.dir(root .. '\\' .. addonDir) do
		if not is_dir and name ~= "main.lua" then
			local menuItem = AddMenu(ExecuteScript,
				"Lua / Scripts / Files / " .. name)
			menuItems[menuItem] = name
		end
	end
end


-- Addon description
local function About()
	return "Scripts"
end


-- Command Line Handler
--	commands are entered like SQL> plugin lua command params
--	eg., SQL> plugin lua -e "print('Hello, World!')"
local CommandLine
do
	local Concat, CommandFeedback = table.concat, IDE.CommandFeedback
	local feedbackHandle

	local env = setmetatable({
		print = function(...)
			local message
			if select('#', ...) == 1 then
				message = ...
			else
				message = Concat({...}, '\t')
			end
			CommandFeedback(feedbackHandle, message)
		end
	}, {__index = _G})

	local function exec(chunk, err)
		if chunk then
			if setfenv then
				setfenv(chunk, env)
			end
			chunk, err = pcall(chunk)
			if chunk then
				if err then IDE.CloseFile(plsql.WindowClose.Quiet) end
				return
			end
		end
		CommandFeedback(feedbackHandle, err)
	end

	CommandLine = function(handle, command, params)
		feedbackHandle = handle

		if command == '-E' then
			if setfenv then
				return exec(loadstring(params))
			else
				return exec(load(params, "=(loadstring)", "bt", env))
			end
		elseif command == '-F' then
			if setfenv then
				return exec(loadfile(params))
			else
				return exec(loadfile(params, "bt", env))
			end
		end
		CommandFeedback(feedbackHandle, "Unknown command: " .. command)
	end
end


return {
	OnActivate,
	OnDeactivate,
	CanClose,
	AfterStart,
	AfterReload,
	OnBrowserChange,
	OnWindowChange,
	OnWindowCreate,
	OnWindowCreated,
	OnWindowClose,
	BeforeExecuteWindow,
	AfterExecuteWindow,
	OnConnectionChange,
	OnWindowConnectionChange,
	OnPopup,
	OnMainMenu,
	OnTemplate,
	OnFileLoaded,
	OnFileSaved,
	About,
	CommandLine,
	RegisterExport,
	ExportInit,
	ExportFinished,
	ExportPrepare,
	ExportData
}

