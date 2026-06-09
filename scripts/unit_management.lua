-- ==============================================================================
-- MIST Programmatic Spawning Utilities (Semantic Version)
-- ==============================================================================
Spawner = {}

-- SEMANTIC LOOKUP TABLES (Enums)
Spawner.ROE = {
    WEAPON_HOLD   = 0,
    RETURN_FIRE   = 1,
    OPEN_FIRE     = 2,
    WEAPON_FREE   = 3
}

Spawner.THREAT_REACTION = {
    PASSIVE_DEFENSE = 0,
    NO_REACTION     = 1,
    EVADE_FIRE      = 2,
    BYPASS_PASSIVE  = 3
}

-- Mapping names to the underlying DCS internal task option IDs
local OPTION_IDS = {
    ROE             = 0,
    THREAT_REACTION = 1
}

--- Helper: Generates a baseline waypoint table
function Spawner.createWaypoint(x, y, speedKMH, action)
    return {
        ["x"] = x,
        ["y"] = y,
        ["type"] = "Turning Point",
        ["action"] = action or "Off Road",
        ["speed"] = (speedKMH or 30) / 3.6,
    }
end

--- Helper: Generates an option task using explicit semantic names
function Spawner.setOption(optionName, valueName)
    local optionId = OPTION_IDS[optionName]
    local valueId = Spawner[optionName] and Spawner[optionName][valueName]
    
    -- Error checking to catch typos during mission scripting
    if optionId == nil or valueId == nil then
        env.info("[Spawner Error] Invalid option assignment: " .. tostring(optionName) .. " -> " .. tostring(valueName))
        return nil
    end

    return {
        ["id"] = "Option",
        ["params"] = {
            ["name"] = optionId,
            ["value"] = valueId
        }
    }
end

--- Assembly: Attaches a list of programmatically built options to a waypoint
function Spawner.addOptionsToWaypoint(waypoint, optionsList)
    -- Filter out any nil entries caused by typos
    local cleanTasks = {}
    for _, task in ipairs(optionsList) do
        if task ~= nil then table.insert(cleanTasks, task) end
    end

    waypoint["task"] = {
        ["id"] = "ComboTask",
        ["params"] = {
            ["tasks"] = cleanTasks
        }
    }
    return waypoint
end

--- Assembly: Packages a complete unit dictionary entry
function Spawner.createUnit(unitType, name, x, y, headingDeg)
    return {
        ["type"] = unitType,
        ["name"] = name,
        ["x"] = x,
        ["y"] = y,
        ["heading"] = (headingDeg or 0) * (math.pi / 180)
    }
end

-- ==============================================================================
-- Programmatic Safe Spawner Function
-- ==============================================================================

-- Core Dependency: Scenery Search Helper
local function findStaticObstructions(x, y, radius)
    local hasObstruction = false
    local sphere = {
        id = world.VolumeType.SPHERE,
        params = {
            point = {x = x, y = land.getHeight({x=x, y=y}), z = y}, -- Game engine matches y data to z axis
            radius = radius
        }
    }
    local callback = function(obj)
        hasObstruction = true
        return false -- Blocker found, break loop early
    end
    world.searchObjects(Object.Category.SCENERY, sphere, callback)
    return hasObstruction
end

--- Programmatically builds and spawns a column of ground units safely cleared of obstacles
-- @param groupName String: Unique identifier for the group
-- @param composition Table: Array of unit types (e.g., {"T-72B", "BMP-2"})
-- @param spawnOrigin Table: Coordinates containing .x and .y keys where the lead unit wants to start
-- @param waypoints Table: Pre-configured waypoint path array
-- @param headingDeg Number: Starting direction facing angle (Degrees)
-- @param country String: Nation coalition allocator (e.g., "Russia", "USA")
function Spawner.spawnSafeColumn(groupName, composition, spawnOrigin, waypoints, headingDeg, country)
    local unitPool = {}
    local currentYOffset = 0
    
    -- Explicitly localizing surface texture enum maps
    local SURFACE_LAND   = 1
    local SURFACE_ROAD   = 4
    local SURFACE_RUNWAY = 5

    for idx, unitType in ipairs(composition) do
        local validPositionFound = false
        local checkX = spawnOrigin.x
        local checkY = spawnOrigin.y + currentYOffset
        local attempts = 0 

        while not validPositionFound and attempts < 20 do
            attempts = attempts + 1
            local surfaceType = land.getSurfaceType({x = checkX, y = checkY})
            local isSafeSurface = (surfaceType == SURFACE_LAND or surfaceType == SURFACE_ROAD or surfaceType == SURFACE_RUNWAY)

            if not isSafeSurface then
                -- Shift backward down the spacing vector if water is hit
                checkY = checkY - 20 
            else
                -- Check for physical structural objects or forest clusters (12-meter safe zone radius)
                if findStaticObstructions(checkX, checkY, 12) then
                    checkY = checkY - 20 
                else
                    validPositionFound = true
                end
            end
        end

        -- Generate the unit entry
        local unitPayload = Spawner.createUnit(
            unitType,
            groupName .. "_Unit_" .. idx,
            checkX,
            checkY,
            headingDeg or 0
        )
        table.insert(unitPool, unitPayload)

        -- Calculate position layout base for the subsequent vehicle
        currentYOffset = (checkY - spawnOrigin.y) - 25
    end

    -- Compile complete structure package
    local masterGroupData = {
        ["visible"] = true,
        ["task"] = "Ground Nothing",
        ["category"] = "GROUND",
        ["country"] = country or "Russia",
        ["name"] = groupName,
        ["route"] = { ["points"] = waypoints or {} },
        ["units"] = unitPool
    }

    -- Deploy via MIST
    mist.dynAdd(masterGroupData)
    env.info("[Spawner API] Successfully dispatched safe platoon: " .. groupName)
end