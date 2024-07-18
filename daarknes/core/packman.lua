local argparse = require("daarknes.core.argparse")

-- repository url
local baseUrl = "https://raw.githubusercontent.com/Daarknes/computercraft/main/"


local function update()
    print("Updating the package manager ...")
	
	-- get the name of this program (maybe it was renamed)
	local progName = shell.getRunningProgram()
	-- if not progName:find(".*%.lua") then
	-- 	progName = progName .. ".lua"
	-- end

    local request = http.get(baseUrl .. "daarknes/core/packman.lua")
    if request == nil then
        print("fatal error, could not download the required files.")
    else
        -- create temporary helper file to download new version
        local f = io.open("_packman_temp.lua", "w")
        f:write(request.readAll())
        f:close()
        request.close()

        shell.execute("move _packman_temp.lua " .. progName)
    end
end

local function checkVersion()
    local request, errormsg, failResponse = http.get({url = baseUrl .. "daarknes/core/packman.lua", method = "HEAD"})
    if request == nil then
        print(errormsg)
        print(failResponse)
    else
        print(request.readAll())
        request.close()
    end
end

local packman = {}

function packman:Main(...)
    local parser = argparse:Parser("packman", "Package Manager for Computercraft Programs")
    local parserUpdate = parser:AddSubParser("update", "Download the newest version of the package manager.")

    checkVersion()
end

return packman