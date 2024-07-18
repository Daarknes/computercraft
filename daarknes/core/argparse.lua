local argparse = {}

-- the program arguments specified by the user
local posArgs = {}
local kwArgs = {help = {name = "help", description = "Show this help.", default = false}}


--[[
    Add a positional argument to the parser.
    `name` will be lowercased.
    if `default` is given, this will be an optional argument.
--]]
function argparse:AddArgument(name, description, default, argType)
    name = name:lower()
    -- if not given, use the type of default value. if both are nil, use string
    argType = argType or (default ~= nil and type(default) or "string")

    if default ~= nil and type(default) ~= argType then
        -- the second argument to error() is the stack level
        error(string.format("Default value `%s` doesn't match the argument type `%s` for `%s`", default, argType, name), 2)
    end

    -- a required argument can't follow an optional one
    if default == nil and #posArgs > 0 and posArgs[#posArgs - 1].default ~= nil then
        error(string.format("The required argument `%s` can't follow an optional argument", name), 2)
    end

    table.insert(posArgs, {
        name = name,
        desciption = description,
        type = argType,
        default = default
    })
end

--[[
    Add a keyword arguments or a flag to the parser.
    Those are arguments starting with `--`, for example something like `--nogui` or `--n 5`.

    The argument type will be derived from the default value.
    For boolean arguments, the second parameter will be omitted, meaning the user has to pass `--a` instead of `--a true`
--]]
function argparse:AddKeywordArgument(name, description, default)
    if default == nil then
        error(string.format("The default value for the keyword argument `%s` is not set", name), 2)
    end

    name = name:lower()
    if kwArgs[name] then
        error(string.format("Argument `%s` is already defined as a keyword argument", name), 2)
    end

    kwArgs[name] = {
        name = name,
        desciption = desciption,
        default = default
    }
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

function argparse:Parse(callArgs)
    local i = 1
    local n = #callArgs
    local iPos = 0
    local nRequired = 0
    local args = {}

    -- fill the output table with the default values
    for _, entry in ipairs(posArgs) do
        if entry.default ~= nil then
            args[entry.name] = entry.default
        else
            nRequired = nRequired + 1
        end
    end
    for kwname, entry in pairs(kwArgs) do
        args[kwname] = entry.default
    end

    while i <= n do
        arg = callArgs[i]

        -- argument starts with `--` -> keyword argument
        local _, _, kwname = string.find(arg, "%-%-(.*)")
        if kwname then
            if kwArgs[kwname] == nil then
                error(string.format("Supplied argument `--%s` is not valid.", kwname), 2)
            end
            -- a boolean argument has no further parameter
            if type(kwArgs[kwname].default) == "boolean" then
                args[kwname] = true
            else
                if i + 1 > n then
                    error(string.format("Missing parameter for argument `%s`", kwname))
                end

                local value = callArgs[i + 1]
                if type(kwArgs[kwname].default) == "number" then
                    value = tonumber(value)
                end
                args[kwname] = value

                i = i + 1
            end
        -- this is a positional argument
        else
            iPos = iPos + 1
            if iPos > #posArgs then
                error("To many positional arguments were provided.")
            end

            if posArgs[iPos].type == "number" then
                args[posArgs[iPos].name] = tonumber(arg)
            elseif posArgs[iPos].type == "boolean" then
                args[posArgs[iPos].name] = arg or false
            else
                args[posArgs[iPos].name] = arg
            end
        end
        i = i + 1
    end

    if iPos < nRequired then
        error("Missing required argument(s)", 2)
    end

    return args
end

-- argparse:AddArgument("testvalue", "A test value", nil, "number")
-- argparse:AddArgument("optionalarg", "optional argument", 5)
-- argparse:AddKeywordArgument("kwarg", "keyword argument", 1.2)
-- local args = argparse:Parse({"21 --kwarg 1.5"})
for k, v in pairs(args) do
    print(k, v)
end

return argparse