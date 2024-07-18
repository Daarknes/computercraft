local reader = peripheral.find("blockReader")

-- config
local singleSide = "back"
local bulkSide = "left"
local bulkNum = 7
local generatorSU = 2112
--

local bulkStress = 15 * generatorSU

local function GetStress()
    local data = reader.getBlockData()
    return data and data.Network and data.Network.Stress or 0
end

--
local lastSU = -1
local function UpdateGenerators()
    local stress = GetStress()
    local bulkOutput = math.floor(stress / bulkStress)
    local singleOutput = math.ceil((stress % bulkStress) / generatorSU)
    
    local provided = bulkOutput * bulkStress + singleOutput * generatorSU
    if provided ~= lastSU then
        lastSU = provided
        print("SU needed: "..stress .. " - will provide "..provided.." SU.")
    
        -- output is reversed since an active signal turns the generator off
        rs.setAnalogOutput(singleSide, 15 - singleOutput)
        rs.setAnalogOutput(bulkSide, bulkNum - bulkOutput)
    end
end


while true do
    UpdateGenerators()
    sleep(1)
end
