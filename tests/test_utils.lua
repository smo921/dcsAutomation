-- Shared test utilities for DCS mission scripting tests

-- Common mock unit types
TestUtils = {}

-- Create a mock radar unit
function TestUtils.createMockRadarUnit(name)
    return {
        getName = function() return name or "Mock_Radar" end,
        getTypeName = function() return "1L13 EWR" end,
        getPosition = function()
            return {p = {x = 0, y = 0, z = 0}}
        end,
        isExist = function() return true end
    }
end

-- Create a mock target unit
function TestUtils.createMockTargetUnit(name, typeName)
    return {
        getName = function() return name or "Mock_Target" end,
        getTypeName = function() return typeName or "F-16C_50" end,
        getPosition = function()
            return {p = {x = 1000, y = 0, z = 1000}}
        end,
        isExist = function() return true end
    }
end

-- Create a mock group with specified units
function TestUtils.createMockGroup(name, units)
    return {
        isExist = function() return true end,
        getSize = function() return #units end,
        getUnit = function(self, index)
            -- Handle both calling conventions
            local unitIndex = index or self
            return units[unitIndex]
        end,
        getName = function() return name end
    }
end

-- Create a mock unit
function TestUtils.createMockUnit(config)
    return {
        isExist = config.isExist or function() return true end,
        isActive = config.isActive or function() return true end,
        getLife = config.getLife or function() return 100 end,
        getName = config.getName or function() return "Mock_Unit" end,
        getTypeName = config.getTypeName or function() return "T-72B" end,
        getPosition = config.getPosition or function()
            return {p = {x = 0, y = 0, z = 0}}
        end,
        getController = config.getController or function()
            return {
                setOption = function(optionId, optionValue)
                    print("Setting option " .. tostring(optionId) .. " to " .. tostring(optionValue))
                end
            }
        end
    }
end

-- Common sector configurations for testing
TestUtils.SectorConfigs = {
    basicGround = {
        groupName = "Test_Ground_Sector",
        category = "GROUND",
        units = {"T-72B", "BMP-2"},
        placement = {
            heading = 90,
            offsetX = 1000,
            offsetY = 1000,
            spawnRadius = 500
        }
    },

    basicAir = {
        groupName = "Test_Air_Sector",
        category = "AIRPLANE",
        units = {"F-16C_50"},
        placement = {
            airbaseName = "Kutaisi",
            startType = "takeoff_hot"
        }
    },

    radarSector = {
        groupName = "Test_Radar_Sector",
        category = "GROUND",
        triggerType = "RADAR",
        unitType = "1L13 EWR",
        placement = {
            heading = 0,
            offsetX = 2000,
            offsetY = 2000,
            spawnRadius = 300
        }
    }
}

-- Common placement configurations
TestUtils.PlacementConfigs = {
    basic = {
        heading = 0,
        offsetX = 0,
        offsetY = 0,
        spawnRadius = 0
    },

    withZone = {
        heading = 45,
        offsetX = 1000,
        offsetY = 1000,
        spawnRadius = 500,
        strategy = "ZONE_RANDOM",
        zoneName = "Test_Zone"
    },

    withBearingDistance = {
        offsetHeading = 90,
        offsetDistance = 10
    }
}

return TestUtils