local function FeetToMeters(feet)
    return feet * 0.3048
end

local function KnotsPerHourToKmPerHour(knots)
    return knots * 1.852
end


UnitFormationBuilder = {}

function UnitFormationBuilder.Linear(config, x, y)
    local unitPayload = {}
    local currentYOffset = 0
    local startX, startY = x, y
    local placementConfig = UnitPlacementConfig.new({
        heading = config.heading,
        offsetX = 0,
        offsetY = 0,
        spawnRadius = 0
    })
    placementConfig.spawnRadius = config.placement.spawnRadius -- skip nm to meters conversion performed by .new()

    for idx, unitType in ipairs(config.units) do
        local startingPosition = {x = startX, y = startY + currentYOffset}
        local checkX, checkY = SpatialSolver.findSafeGroundCoordinates(startingPosition, placementConfig)

        local attempts = 0
        while attempts < 20 do
            attempts = attempts + 1
            local surf = land.getSurfaceType({x = checkX, y = checkY})
            if (surf == 1 or surf == 4 or surf == 5) and not SpatialSolver.findStaticObstructions(checkX, checkY, 12) then break end
            checkY = checkY - 20
        end

        table.insert(unitPayload, {
            ["type"] = unitType,
            ["name"] = config.groupName .. "_Unit_" .. idx,
            ["x"] = checkX,
            ["y"] = checkY,
            ["heading"] = config.placement.heading * (math.pi / 180) })
        currentYOffset = (checkY - startY) - 25
    end
    return unitPayload
end


function UnitFormationBuilder.RadialScatter(config, x, y)
    local unitPayload = {
        ["visible"] = true,
        ["task"] = "Ground Nothing",
        ["category"] = "GROUND",
        ["country"] = config.country,
        ["name"] = config.groupName,
        ["route"] = { ["points"] = { { ["x"] = x, ["y"] = y, ["type"] = "Turning Point", ["action"] = "From Ground Area", ["speed"] = 0 } } },
        ["units"] = {}
    }

    for idx, unitType in ipairs(config.units) do
        local randomAngle = math.random() * 2 * math.pi
        local randomDist = config.minR + (math.random() * (config.maxR - config.minR))
        
        local adX = x + (math.cos(randomAngle) * randomDist)
        local adY = y + (math.sin(randomAngle) * randomDist)
        if land.getSurfaceType({x = adX, y = adY}) ~= 3 then
            local unitConfig = {
                ["unitType"] = unitType,
                ["name"] = config.groupName .. "_AD_Node_" .. idx
            }
            table.insert(unitPayload["units"], AssetFactories.buildGroundUnit(unitConfig, adX, adY))
        end
    end
    return unitPayload
end

function UnitFormationBuilder.BuildRoute(startX, startY, waypoints)
    local points = {}
    for _, wp in ipairs(waypoints) do
        local node = {
            ["x"]      = startX + wp.offsetX,
            ["y"]      = startY + wp.offsetY,
            ["action"] = "Turning Point",
            ["type"]   = wp.type or "Off Road",
            ["speed"]  = (wp.speed or 30) / 3.6, -- Convert km/h to m/s
            ["task"]   = { ["id"] = "ComboTask", ["params"] = { ["tasks"] = {} } }
        }
        local opts = {}
        if wp.roe and AssetFactories.ROE[wp.roe] then table.insert(opts, { ["id"] = "Option", ["params"] = { ["name"] = AssetFactories.OPTION_IDS["ROE"], ["value"] = AssetFactories.ROE[wp.roe] } }) end
        if wp.threat and AssetFactories.THREAT_REACTION[wp.threat] then table.insert(opts, { ["id"] = "Option", ["params"] = { ["name"] = OPTION_IDS["THREAT_REACTION"], ["value"] = AssetFactories.THREAT_REACTION[wp.threat] } }) end
        if #opts > 0 then node["task"] = { ["id"] = "ComboTask", ["params"] = { ["tasks"] = opts } } end
        table.insert(points, node)
    end
    return points
end


AssetFactories = {}

function AssetFactories.buildRadar(config, x, y)
    env.info("[AssetFactory] Building Radar " .. config.groupName)
    local payload = {
        ["visible"] = true,
        ["category"] = "GROUND",
        ["country"] = config.country,
        ["name"] = config.groupName,
        ["route"] = {
            ["points"] = {}
        },
        ["units"] = {
            [1] = {
                ["type"] = config.unitType,
                ["name"] = config.groupName .. "_Sensor_Unit",
                ["x"] = x,
                ["y"] = y,
                ["speed"] = 0,
                ["heading"] = (config.placement.heading or 0) * (math.pi / 180),
                ["skill"] = "High"
            }
        }
    }
    return payload
end

function AssetFactories.buildStatic(config, x, y)
    local staticPayload = {
        ["country"] = config.country,
        ["category"] = "Fortifications",
        ["type"] = config.unitType,
        ["name"] = config.groupName,
        ["x"] = x,
        ["y"] = y,
        ["heading"] = math.rad(config.heading or 0)
    }
    coalition.addStaticObject(country.id[config.country], staticPayload)
end

function AssetFactories.buildGroundUnit(config, x, y)
    return {
        ["type"] = config.unitType,
        ["name"] = config.name,
        ["x"] = x,
        ["y"] = y,
        ["heading"] = config.heading or math.random(0, 359) * (math.pi / 180),
        ["skill"] = "High"
    }
end

function AssetFactories.buildAWACS(config, x, y)
    local altitude = FeetToMeters(config.altitude) or 8000 
    local speed = KnotsPerHourToKmPerHour(config.speed) or 550
    
    local wp1_x = x
    local wp1_y = y
    local wp2_x = x + (config.orbitLength or 40000)
    local wp2_y = y
    
    local payload = {
        ["visible"] = true,
        ["category"] = "AIRPLANE",
        ["country"] = config.country,
        ["name"] = config.groupName,
        ["units"] = {
            [1] = {
                ["type"] = config.unitType or "E-3A",
                ["name"] = config.groupName .. "_Unit_1",
                ["x"] = wp1_x,
                ["y"] = wp1_y,
                ["alt"] = altitude,
                ["alt_type"] = "BARO",
                ["speed"] = speed,
                ["heading"] = 0,
                ["skill"] = "Excellent"
            }
        },
        ["route"] = {
            ["points"] = {
                [1] = {
                    ["x"] = wp1_x, ["y"] = wp1_y, ["alt"] = altitude, ["alt_type"] = "BARO",
                    ["type"] = "Turning Point", ["action"] = "Turning Point", ["speed"] = speed,
                    ["task"] = {
                        ["id"] = "ComboTask",
                        ["params"] = {
                            ["tasks"] = {
                                [1] = { ["id"] = "AWACS", ["params"] = {} },
                                [2] = {
                                    ["id"] = "Orbit",
                                    ["params"] = { ["pattern"] = "Racetrack", ["altitude"] = altitude, ["speed"] = speed }
                                },
                                [3] = { ["id"] = "SetFrequency", ["params"] = { ["frequency"] = config.frequency, ["modulation"] = config.modulation } },
                                [4] = { ["id"] = "SetCallsign", ["params"] = { ["callsign"] = config.callsign, ["number"] = config.callsignNumber } }
                            }
                        }
                    }
                },
                {
                    ["x"] = wp2_x, ["y"] = wp2_y, ["alt"] = altitude, ["alt_type"] = "BARO",
                    ["type"] = "Turning Point", ["action"] = "Turning Point", ["speed"] = speed,
                    ["task"] = { ["id"] = "ComboTask", ["params"] = { ["tasks"] = {} } }
                }
            }
        }
    }
    return payload
end


function AssetFactories.buildDrone(config, x, y)
    local altitude = FeetToMeters(config.altitude) or 4572 
    local speed = (KnotsPerHourToKmPerHour(config.speed) or 200) / 3.6 

    local payload = {
        ["visible"]  = true,
        ["category"] = "AIRPLANE",
        ["country"]  = config.country or "USA",
        ["name"]     = config.groupName,
        ["units"]    = {
            [1] = {
                ["type"]     = config.unitType or "MQ-9 Reaper",
                ["name"]     = config.groupName .. "_Unit_1",
                ["x"]        = x,
                ["y"]        = y,
                ["alt"]      = altitude,
                ["alt_type"] = "BARO",
                ["speed"]    = speed,
                ["heading"]  = 0,
                ["skill"]    = "Excellent"
            }
        },
        ["route"] = {
            ["points"] = {
                [1] = {
                    ["x"]        = x,
                    ["y"]        = y,
                    ["alt"]      = altitude,
                    ["alt_type"] = "BARO",
                    ["speed"]    = speed,
                    ["action"]   = "Turning Point",
                    ["type"]     = "Turning Point",
                    ["task"]     = {
                        ["id"] = "ComboTask",
                        ["params"] = {
                            ["tasks"] = {
                                [1] = {
                                    ["id"] = "Orbit",
                                    ["params"] = {
                                        ["pattern"] = "Circle",
                                        ["altitude"] = altitude,
                                        ["speed"] = speed
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return payload
end

AssetFactories.ROE = { WEAPON_HOLD = 0, RETURN_FIRE = 1, OPEN_FIRE = 2, WEAPON_FREE = 3 }
AssetFactories.THREAT_REACTION = { PASSIVE_DEFENSE = 0, NO_REACTION = 1, EVADE_FIRE = 2, BYPASS_PASSIVE = 3 }
AssetFactories.OPTION_IDS = { ROE = 0, THREAT_REACTION = 1 }

function AssetFactories.buildPlatoon(config, x, y)
    -- Compile Waypoints
    local points = {}
    if config.route then
        points = UnitFormationBuilder.BuildRoute(x, y, config.route)
    end

    local unitPool = UnitFormationBuilder.Linear(config, x, y)
    return {
        ["visible"] = true,
        ["category"] = "GROUND",
        ["country"] = config.country,
        ["name"] = config.groupName,
        ["route"] = { ["points"] = points },
        ["units"] = unitPool
    }
end

function AssetFactories.buildPointDefense(config, x, y)
    local pdConfig = {
        ["country"] = config.country,
        ["groupName"] = config.groupName .. "_Point_Defense",
        ["minR"] = config.pointDefense.minRadius or 100,
        ["maxR"] = config.pointDefense.maxRadius or 300,
        ["units"] = config.pointDefense.units,
    }
    return UnitFormationBuilder.RadialScatter(pdConfig, x, y)
end

function activatePointDefense(adGroup)
    for idx, unit in ipairs(adGroup.units) do
        TriggerRegistry.scheduleAction(1.5, function()
            local g = Group.getByName(adGroup.name)
            if g and g:getController() then
                g:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
            end
        end, {})
    end
end