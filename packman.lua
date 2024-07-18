-- repository url
local baseUrl = "https://raw.githubusercontent.com/Daarknes/computercraft/main/"


local function update()
    print("Updating the package manager ...")
	
	-- get the name of this program (maybe it was renamed)
	local progName = shell.getRunningProgram()
	-- if not progName:find(".*%.lua") then
	-- 	progName = progName .. ".lua"
	-- end

    -- create temporary helper file
	local f = io.open("_packman_temp.lua", "w")
    f:write([[
local request = http.get("]] .. baseUrl .. [[packman.lua")
if request == nil then
    print("fatal error, could not download the required files.")
else
    local f = io.open("]] .. progName .. [[", "w")
    f.write(request.readAll())
    f:close()
    request.close()
end

os.execute("]] .. progName ..  [[ _finalizeUpdate")]])
end


local function handleArguments(args, options)
	if args[1] == "_finalizeUpdate" then
		finalizeUpdate()
	elseif args[1] == "update" then
		update()
	elseif args[1] == "list" then
		showList()
	elseif args[1] == "install" and args[2] ~= nil then
		if libraries[args[2]] then
			installLib(args[2], options.f)
		elseif programs[args[2]] then
			installProgram(args[2], options.f)
		else
			print("\"" .. args[2] .. "\" is not a valid library or program. Use 'packman list' for a list of all available libraries and programs.")
		end
	elseif args[1] == "uninstall" and args[2] ~= nil then
		uninstall(args[2])
	else
		showHelp()
	end
end


local args, options = shell.parse(...)
handleArguments(args, options)