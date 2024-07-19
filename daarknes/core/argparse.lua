local argparse = {}


--[[
    Creates a (sub-)parser for command line arguments.
--]]
function argparse:Parser(progName, description)
    local parser = {
        progName = progName,
        description = description,
        posArgs = {},
        subParsers = {},
        kwArgs = {},
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
            description = description,
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
            description = description,
            default = default
        }
    end

    function parser:Parse(callArgs, _args)
        local i = 1
        local nArgs = #callArgs
        local iPos = 0
        local hasSubparsers = next(self.subParsers) ~= nil
        local nRequired = #self.posArgs + (hasSubparsers and 1 or 0)
        
        -- output table
        local _args = _args or {}
        -- fill the output table with the default values
        for kwname, entry in pairs(self.kwArgs) do
            _args[kwname] = entry.default
        end
    
        while i <= nArgs do
            local arg = callArgs[i]
    
            -- argument starts with `--` -> keyword argument
            local _, _, kwname = string.find(arg, "%-%-(.*)")
            if kwname then
                if kwname == "help" then
                    self:ShowHelp()
                    return
                end
                if self.kwArgs[kwname] == nil then
                    error(string.format("Supplied argument `--%s` is not valid.", kwname), 2)
                end
                -- a boolean argument has no further parameter
                if type(self.kwArgs[kwname].default) == "boolean" then
                    _args[kwname] = true
                else
                    if i + 1 > n then
                        error(string.format("Missing parameter for argument `%s`", kwname), 2)
                    end
    
                    local value = callArgs[i + 1]
                    if type(self.kwArgs[kwname].default) == "number" then
                        value = tonumber(value)
                    end
                    _args[kwname] = value
    
                    i = i + 1
                end
            -- this is a positional argument
            else
                iPos = iPos + 1
                if iPos > #self.posArgs then
                    -- pass remaining arguments to subparser
                    if hasSubparsers then
                        if self.subParsers[arg] then
                            _args[self.progName .. "_action"] = arg
                            self.subParsers[arg]:Parse({select(i+1, table.unpack(callArgs))}, _args)
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
                        _args[posArg.name] = tonumber(arg)
                    elseif posArg.type == "boolean" then
                        _args[posArg.name] = arg == "true" and true or false
                    else
                        _args[posArg.name] = arg
                    end
                end
            end
            i = i + 1
        end
    
        if iPos < nRequired then
            error("Missing required argument(s)", 2)
        end
    
        return _args
    end

    -- we have to build the help from deepest subparser to highest
    function parser:ShowHelp(info)
        local isLowest = info == nil
        -- the info table is provided to the parent to fill it further. Everything is added in reverse
        info = info or {
            signature = "",
            positional = {},
            optional = {}
        }
        
        local signature = self.progName

        for _, entry in ipairs(self.posArgs) do
            table.insert(info.positional, {name = entry.name, description = entry.description})
            signature = signature .. " <" .. entry.name .. ">"
        end

        for _, entry in pairs(self.kwArgs) do
            if type(entry.default) == "boolean" then
                table.insert(info.optional, {name = "--" .. entry.name, description = entry.description})
                signature = signature .. " [--" .. entry.name .. "]"
            else
                table.insert(info.optional, {name = "--" .. entry.name .. " .", description = entry.description})
                signature = signature .. " [--" .. entry.name .. " .]"
            end
        end

        if isLowest then
            table.insert(info.optional, {name = "--help", description = "Show this help."})
            signature = signature .. " [--help]"
        end

        -- only add subparser parameters when this is the deepest ShowHelp call
        if isLowest and next(self.subParsers) ~= nil then
            local options = {}
            for name, subParser in pairs(self.subParsers) do
                table.insert(options, subParser.progName)
                table.insert(info.positional, {name = subParser.progName, description = subParser.description})
            end

            signature = signature .. " {" .. table.concat(options, ", ") .. "}"
        end

        info.signature = signature .. " " .. info.signature

        -- backtrack to parent parser
        if self.parent ~= nil then
            self.parent:ShowHelp(info)
        -- this is the top-level parser -> build message and print it
        else
            local msg = self.description .. "\nusage: " .. info.signature .. "\n"

            if next(info.positional) ~= nil then
                local maxLen = 1
                for _, entry in ipairs(info.positional) do
                    maxLen = math.max(maxLen, string.len(entry.name))
                end

                msg = msg .. "\npositional arguments:\n"
                for _, entry in ipairs(info.positional) do
                    msg = msg .. "  " .. string.format("%-" .. maxLen .. "s", entry.name) .. "  " .. entry.description .. "\n"
                end
            end

            if next(info.optional) ~= nil then
                local maxLen = 1
                for _, entry in ipairs(info.optional) do
                    maxLen = math.max(maxLen, string.len(entry.name))
                end

                msg = msg .. "\noptional arguments:\n"
                for _, entry in ipairs(info.optional) do
                    msg = msg .. "  " .. string.format("%-" .. maxLen .. "s", entry.name) .. "  " .. entry.description .. "\n"
                end
            end

            print(msg)
        end
    end

	return parser
end


return argparse