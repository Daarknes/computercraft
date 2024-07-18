local argparse = {}

-- the program arguments specified by the user
local posArgs = {}
local kwArgs = {help = {name = "help", description = "Show this help.", default = false}}


--[[
    Creates a (sub-)parser for command line arguments.
--]]
function argparse:Parser(progName, description)
    local parser = {
        progName = progName,
        description = description,
        posArgs = {},
        subParsers = {},
        kwArgs = {help = {name = "help", description = "Show this help.", default = false}},
    }

    function parser:AddSubParser(name, description)
        self.subParsers[name] = argparse:Parser(name, description, self)
        self.subParsers[name].parent = self
        return self.subParsers[name]
    end

    --[[
    Add a positional argument to the parser.
    `name` will be lowercased.
    --]]
    function parser:AddArgument(name, description, argType)
        name = name:lower()

        -- the default type is string
        argType = argType or "string"

        table.insert(self.posArgs, {
            name = name,
            desciption = description,
            type = argType
        })
    end

    --[[
    Add a keyword arguments or a flag to the parser.
    Those are arguments starting with `--`, for example something like `--nogui` or `--n 5`.

    The argument type will be derived from the default value.
    For boolean arguments, the second parameter will be omitted, meaning the user has to pass `--a` instead of `--a true`
    --]]
    function parser:AddKeywordArgument(name, description, default)
        if default == nil then
            error(string.format("The default value for the keyword argument `%s` is not set", name), 2)
        end

        name = name:lower()
        if self.kwArgs[name] then
            error(string.format("Argument `%s` is already defined as a keyword argument", name), 2)
        end

        self.kwArgs[name] = {
            name = name,
            desciption = desciption,
            default = default
        }
    end

    function parser:Parse(callArgs, args)
        local i = 1
        local nArgs = #callArgs
        local iPos = 0
        local hasSubparsers = next(self.subParsers) ~= nil
        local nRequired = #self.posArgs + (hasSubparsers and 1 or 0)
        
        -- output table
        local args = args or {}
        -- fill the output table with the default values
        for kwname, entry in pairs(self.kwArgs) do
            args[kwname] = entry.default
        end
    
        while i <= nArgs do
            local arg = callArgs[i]
    
            -- argument starts with `--` -> keyword argument
            local _, _, kwname = string.find(arg, "%-%-(.*)")
            if kwname then
                if self.kwArgs[kwname] == nil then
                    error(string.format("Supplied argument `--%s` is not valid.", kwname), 2)
                end
                -- a boolean argument has no further parameter
                if type(self.kwArgs[kwname].default) == "boolean" then
                    args[kwname] = true
                else
                    if i + 1 > n then
                        error(string.format("Missing parameter for argument `%s`", kwname), 2)
                    end
    
                    local value = callArgs[i + 1]
                    if type(self.kwArgs[kwname].default) == "number" then
                        value = tonumber(value)
                    end
                    args[kwname] = value
    
                    i = i + 1
                end
            -- this is a positional argument
            else
                iPos = iPos + 1
                if iPos > #self.posArgs then
                    -- pass remaining arguments to subparser
                    if hasSubparsers then
                        if self.subParsers[arg] then
                            args[self.progName .. ".subParser"] = arg
                            self.subParsers[arg]:Parse({select(i+1, table.unpack(callArgs))}, args)
                            break
                        else
                            error(string.format("No subparser with name `%s`.", arg), 2)
                        end
                    else
                        error("Too many positional arguments were provided.", 2)
                    end
                else
                    local posArg = self.posArgs[iPos]
                    if posArg.type == "number" then
                        args[posArg.name] = tonumber(arg)
                    elseif posArg.type == "boolean" then
                        args[posArg.name] = arg == "true" and true or false
                    else
                        args[posArg.name] = arg
                    end
                end
            end
            i = i + 1
        end
    
        if iPos < nRequired then
            error("Missing required argument(s)", 2)
        end
    
        return args
    end

	return parser
end


function argparse:Help()
    local msg = [[Daarknes' OpenComputers library and program manager.
Usage:
]]
    for _, entry in ipairs(posArgs) do
        if entry.default == nil then
            msg = msg .. " <" .. entry.name .. ">"
        else
            msg = msg .. " [" .. entry.name .. "]"
        end
    end

    for _, entry in pairs(kwArgs) do
        if type(entry.default) == "boolean" then
            msg = msg .. " --" .. entry.name
        else
            msg = msg .. " --" .. entry.name .. " ."
        end
    end
end

return argparse