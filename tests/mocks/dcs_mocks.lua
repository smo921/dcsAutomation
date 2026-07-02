-- Mock DCS World APIs for testing

-- Mock env functions
env = {
    info = function(message)
        print("[INFO] " .. tostring(message))
    end,
    warning = function(message)
        print("[WARNING] " .. tostring(message))
    end,
    error = function(message)
        print("[ERROR] " .. tostring(message))
    end
}

-- Mock trigger functions
trigger = {
    action = {
        markToAll = function(id, text, position, readOnly)
            print("Mark created: " .. tostring(text))
        end,
        removeMark = function(id)
            print("Mark removed: " .. tostring(id))
        end,
        outText = function(message, time)
            print("Output text: " .. tostring(message))
        end
    },
    misc = {
        getZone = function(zoneName)
            if zoneName == "Test_Zone" then
                return {
                    point = {x = 1000, z = 1000},
                    radius = 1000
                }
            end
            return nil
        end
    }
}

-- Mock Group class
Group = {
    getByName = function(name)
        if name == "NonExistent_Group" then
            return nil
        end
        -- Return mock group object
        return {
            isExist = function() return true end,
            getSize = function() return 2 end,
            getUnit = function(self, index)
                -- Handle both calling conventions
                -- When called as g:getUnit(i), self is the group object and index is the unit number
                -- When called as g.getUnit(i), self is the unit number and index is nil
                local unitIndex = index or self

                local units = {
                    {
                        isExist = function() return true end,
                        isActive = function() return true end,
                        getLife = function() return 100 end,
                        getName = function() return name .. "_Unit_1" end,
                        getTypeName = function() return "T-72B" end,
                        getPosition = function()
                            return {p = {x = 0, y = 0, z = 0}}
                        end,
                        getController = function()
                            return {
                                setOption = function(optionId, optionValue)
                                    print("Setting option " .. tostring(optionId) .. " to " .. tostring(optionValue))
                                end
                            }
                        end
                    },
                    {
                        isExist = function() return true end,
                        isActive = function() return true end,
                        getLife = function() return 100 end,
                        getName = function() return name .. "_Unit_2" end,
                        getTypeName = function() return "BMP-2" end,
                        getPosition = function()
                            return {p = {x = 10, y = 0, z = 10}}
                        end,
                        getController = function()
                            return {
                                setOption = function(optionId, optionValue)
                                    print("Setting option " .. tostring(optionId) .. " to " .. tostring(optionValue))
                                end
                            }
                        end
                    }
                }
                return units[unitIndex]
            end
        }
    end
}

-- Mock Unit class
Unit = {
    getName = function(unit)
        return unit:getName()
    end
}

-- Mock land functions
land = {
    getSurfaceType = function(point)
        return 1 -- Land
    end,
    getHeight = function(point)
        return 100
    end
}

-- Mock timer functions
timer = {
    getTime = function()
        return os.time()
    end,
    scheduleFunction = function(func, args, time)
        print("Scheduled function for time: " .. tostring(time))
        return 1 -- mock timer ID
    end
}

-- Mock world functions
-- Global variable to control mock behavior for testing
_MOCK_WORLD_SETTINGS = {
    shouldFindObstructions = false,
    sceneryObstructionCount = 0
}

world = {
    searchObjects = function(category, volume, callback)
        -- Mock implementation - configurable for testing
        if _MOCK_WORLD_SETTINGS.shouldFindObstructions then
            -- Call callback once for each object found
            for i = 1, _MOCK_WORLD_SETTINGS.sceneryObstructionCount or 1 do
                callback({name = "MockObject" .. i})
            end
        end
        return true
    end,
    VolumeType = {
        SPHERE = 1
    }
}

-- Mock Object categories
Object = {
    Category = {
        SCENERY = 1,
        BASE = 2
    }
}

-- Mock coalition functions
coalition = {
    addStaticObject = function(countryId, payload)
        print("Adding static object: " .. tostring(payload.name))
    end
}

-- Mock country functions
country = {
    id = {
        USA = 2,
        Russia = 3
    }
}

-- Mock missionCommands
missionCommands = {
    addSubMenu = function(name)
        print("Adding submenu: " .. tostring(name))
        return "mock_submenu"
    end,
    addCommand = function(name, parent, func)
        print("Adding command: " .. tostring(name))
        return "mock_command"
    end,
    removeItem = function(item)
        print("Removing menu item")
    end
}

-- Mock Airbase
Airbase = {
    getByName = function(name)
        if name == "Kutaisi" then
            return {
                getName = function() return "Kutaisi" end,
                getID = function() return 1 end,
                getPosition = function()
                    return {p = {x = 1000, y = 100, z = 1000}}
                end
            }
        end
        return nil
    end
}

-- Mock mist functions that are used
mist = {
    utils = {
        NMToMeters = function(nm) return nm * 1852 end,
        knotsToMps = function(knots) return knots * 0.514444 end,
        feetToMeters = function(feet) return feet * 0.3048 end,
        MetersToNM = function(meters) return meters / 1852 end,
        mpsToKnots = function(mps) return mps / 0.514444 end,
        metersToFeet = function(meters) return meters / 0.3048 end,
        radToDeg = function(rad) return rad * 180 / math.pi end,
        degToRad = function(deg) return deg * math.pi / 180 end
    },
    getRandomPointInZone = function(zoneName)
        return {x = 1000, y = 1000}
    end,
    getGroupRoute = function(groupName)
        return {
            {x = 0, y = 0, alt = 1000, type = "Turning Point"},
            {x = 1000, y = 1000, alt = 1000, type = "Turning Point"}
        }
    end,
    DBs = {
        missionData = {
            bullseye = {
                blue = {x = 0, y = 0},
                red = {x = 5000, y = 5000}
            }
        },
        spawnsByBase = {
            ["Kutaisi"] = {
                ["1"] = {x = 1000, y = 1000},
                ["2"] = {x = 1050, y = 1050}
            }
        }
    },
    groupIsDead = function(groupName)
        return groupName == "Dead_Group"
    end,
    respawnGroup = function(groupName, reset)
        print("Respawning group: " .. tostring(groupName))
    end,
    makeUnitTable = function(filter)
        return {"Unit1", "Unit2"}
    end,
    getUnitsInZones = function(units, zones)
        if zones[1] == "Test_Zone" then
            return {"Unit1"}
        end
        return {}
    end,
    dynAdd = function(payload)
        print("Dynamically adding group: " .. tostring(payload.name))
    end,
    fixedWing = {
        buildWP = function(point, action, speed, alt, alt_type)
            return {
                x = point.x,
                y = point.y,
                alt = alt or 1000,
                alt_type = alt_type or "BARO",
                speed = speed or 150,
                type = "Turning Point",
                action = action or "Turning Point"
            }
        end
    },
    heli = {
        buildWP = function(point, action, speed, alt, alt_type)
            return {
                x = point.x,
                y = point.y,
                alt = alt or 100,
                alt_type = alt_type or "AGL",
                speed = speed or 50,
                type = "Turning Point",
                action = action or "Turning Point"
            }
        end
    },
    ground = {
        buildWP = function(point, form, speed)
            return {
                x = point.x,
                y = point.y,
                speed = speed or 10,
                type = "Turning Point",
                action = form or "Off Road"
            }
        end
    }
}

-- Mock AI options
AI = {
    Option = {
        Ground = {
            id = {
                ALARM_STATE = 1
            },
            val = {
                ALARM_STATE = {
                    RED = 2
                }
            }
        }
    }
}

-- Mock coord functions
coord = {
    LOtoLL = function(pos)
        return 45.0, 45.0, pos.y
    end,
    LLtoMGRS = function(lat, lon)
        return {
            MGRSDigraph = "AB",
            Easting = 12345,
            Northing = 67890
        }
    end
}