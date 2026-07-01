Utils = {}

function Utils.PrintTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t) do
        if type(value) == "table" then
            env.info(indent .. tostring(key) .. ":")
            Utils.PrintTable(value, indent .. "  ")
        else
            env.info(indent .. tostring(key) .. ": " .. tostring(value))
        end
    end
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
        local startingPosition = {
            x = startX,
            y = startY + currentYOffset
        }
        local checkX, checkY = SpatialSolver.findSafeGroundCoordinates(startingPosition, placementConfig)

        local attempts = 0
        while attempts < 20 do
            attempts = attempts + 1
            local surf = land.getSurfaceType({
                x = checkX,
                y = checkY
            })
            if SpatialSolver.VALID_LAND_TYPES[surf] and
                not SpatialSolver.findStaticObstructions(checkX, checkY, SpatialSolver.DEFAULT_CLEARANCE_RADIUS) then
                break
            end
            checkY = checkY - 20
        end

        table.insert(unitPayload, {
            ["type"] = unitType,
            ["name"] = config.groupName .. "_Unit_" .. idx,
            ["x"] = checkX,
            ["y"] = checkY,
            ["heading"] = config.placement.heading * (math.pi / 180)
        })
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
        ["route"] = {
            ["points"] = {{
                ["x"] = x,
                ["y"] = y,
                ["type"] = "Turning Point",
                ["action"] = "From Ground Area",
                ["speed"] = 0
            }}
        },
        ["units"] = {}
    }

    for idx, unitType in ipairs(config.units) do
        local randomAngle = math.random() * 2 * math.pi
        local randomDist = config.minR + (math.random() * (config.maxR - config.minR))

        local adX = x + (math.cos(randomAngle) * randomDist)
        local adY = y + (math.sin(randomAngle) * randomDist)
        if land.getSurfaceType({
            x = adX,
            y = adY
        }) ~= 3 then
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

    for _, wp in ipairs(waypoints or {}) do
        local wpX = startX + (wp.offsetX or 0)
        local wpY = startY + (wp.offsetY or 0)

        -- mist.ground.buildWP creates a complete DCS ground route point automatically.
        -- Arguments: ( vec2/vec3 point, formStr, speedMps )
        local node = mist.ground.buildWP({
            x = wpX,
            y = wpY
        }, wp.type or "Off Road", (wp.speed or 30) / 3.6)

        -- Handle ROE/Threat tasks exactly as before
        node.task = {
            ["id"] = "ComboTask",
            ["params"] = {
                ["tasks"] = {}
            }
        }
        local optionDefinitions = {{
            name = "ROE",
            val = wp.roe,
            map = AssetFactories.ROE
        }, {
            name = "THREAT_REACTION",
            val = wp.threat,
            map = AssetFactories.THREAT_REACTION
        }}

        for _, opt in ipairs(optionDefinitions) do
            if opt.val and opt.map[opt.val] then
                table.insert(node.task.params.tasks, {
                    ["id"] = "Option",
                    ["params"] = {
                        ["name"] = AssetFactories.OPTION_IDS[opt.name],
                        ["value"] = opt.map[opt.val]
                    }
                })
            end
        end

        table.insert(points, node)
    end

    return points
end

AssetFactories = {}

-- ==============================================================================
-- AIR UNIT PRODUCTION EXTENSIONS
-- ==============================================================================

function UnitFormationBuilder.BuildAirRoute(startX, startY, waypoints, defaultAirbaseObj, isHelo)
    local points = {}
    local wpBuilder = isHelo and mist.heli.buildWP or mist.fixedWing.buildWP

    for _, wp in ipairs(waypoints or {}) do
        local wpX, wpY, aeroId, wpType, wpAction

        if wp.type == "landing" or wp.type == "Land" then
            local landBase = Airbase.getByName(wp.airbaseName) or defaultAirbaseObj
            if landBase then
                local landPos = landBase:getPosition().p
                wpX, wpY = landPos.x, landPos.z
                aeroId = landBase:getID()
            else
                wpX, wpY = startX, startY
            end
            wpType = "Land"
            wpAction = "Landing"
        else
            wpX = startX + (wp.offsetX or 0)
            wpY = startY + (wp.offsetY or 0)
            wpType = wp.type or "Turning Point"
            wpAction = wp.action or "Turning Point"
        end

        -- Create baseline waypoint using MIST
        local node = wpBuilder({
            x = wpX,
            y = wpY
        }, wpAction, wp.speed or 150, wp.alt or 3000, wp.alt_type or "BARO")

        node.type = wpType
        if aeroId then
            node.aerodromeId = aeroId
        end

        -- FIX: Safely initialize the DCS Task table structure so MIST or native systems can parse it
        node.task = {
            ["id"] = "ComboTask",
            ["params"] = {
                ["tasks"] = {}
            }
        }

        -- Now table.insert will safely find the target array without throwing a nil error
        if wp.roe and AssetFactories.ROE[wp.roe] then
            table.insert(node.task.params.tasks, {
                ["id"] = "Option",
                ["params"] = {
                    ["name"] = AssetFactories.OPTION_IDS.ROE,
                    ["value"] = AssetFactories.ROE[wp.roe]
                }
            })
        end

        table.insert(points, node)
    end

    return points
end

function AssetFactories.buildAirGroup(config, startX, startY, airbaseObj)
    -- Isolate the placement sub-table configuration
    local placement = config.placement or {}

    -- Explicitly pull from the placement sub-table first
    local airbaseName = placement.airbaseName or config.airbaseName
    local startType = placement.startType or config.startType
    local headingDeg = placement.heading or config.heading or 0

    -- Extract numerical Airbase ID required for engine anchorage mapping
    local airbaseId = airbaseObj and airbaseObj:getID() or nil

    -- Ground start state flags evaluated from placement metrics
    local isRampStart = (airbaseName ~= nil and startType ~= "air_start")

    local startTypeStr = "TakeOffParkingHot"
    local actionStr = "From Parking Area Hot"

    if startType == "takeoff_cold" then
        startTypeStr = "TakeOffParking"
        actionStr = "From Parking Area"
    elseif startType == "takeoff_ramp" then
        startTypeStr = "TakeOff"
        actionStr = "From Runway"
    end

    local unitPool = {}
    local isHelo = (config.category == "HELICOPTER")

    -- 1. Assemble Unit Definitions
    for idx, uData in ipairs(config.units) do
        local unitType = type(uData) == "table" and uData.unitType or uData
        local unitName = type(uData) == "table" and uData.name or (config.groupName .. "_Unit_" .. idx)

        -- Pull groundSpot from config object; default to sequential numbering string
        local groundSpot = 1
        if type(uData) == "table" and uData.groundSpot then
            groundSpot = tonumber(uData.groundSpot) or idx
        else
            groundSpot = idx
        end

        -- Ensure standard DCS string formatting
        local spotStr = tostring(groundSpot)

        -- 1. FALLBACK COORDINATES (Airfield Center)
        local spawnX = startX
        local spawnY = startY

        -- 2. DYNAMIC COORDINATE LOOKUP
        -- Extract the actual physical coordinates for this specific spot via MIST
        if isRampStart and mist.DBs.spawnsByBase and mist.DBs.spawnsByBase[airbaseName] then
            local baseData = mist.DBs.spawnsByBase[airbaseName]
            if baseData[spotStr] then
                spawnX = baseData[spotStr].x or startX
                spawnY = baseData[spotStr].y or startY
            end
        end

        local alt = isRampStart and 0 or (placement.altitude or config.altitude or 2000)
        local speed = isRampStart and 0 or (placement.speed or config.speed or 150)
        local headingRad = headingDeg * (math.pi / 180)

        local unitEntry = {
            ["type"] = unitType,
            ["name"] = unitName,
            ["x"] = spawnX, -- Now assigned to the exact physical stall coordinate
            ["y"] = spawnY, -- Now assigned to the exact physical stall coordinate
            ["alt"] = alt,
            ["speed"] = speed,
            ["skill"] = "Excellent",
            ["heading"] = headingRad,
            ["onboard_num"] = 100 + idx
        }

        if isRampStart then
            unitEntry["parking_id"] = spotStr
            unitEntry["parking"] = spotStr
            unitEntry["action"] = actionStr
        end

        table.insert(unitPool, unitEntry)
    end

    local points = {}

    -- 2. MANDATORY WAYPOINT 1: Overwrite x/y coordinates to force-link to parking spots
    local firstWaypoint = {
        ["type"] = isRampStart and startTypeStr or "Turning Point",
        ["action"] = isRampStart and actionStr or "Turning Point",
        ["x"] = unitPool[1] and unitPool[1].x or startX, -- Aligns perfectly with Unit 1
        ["y"] = unitPool[1] and unitPool[1].y or startY, -- Aligns perfectly with Unit 1
        ["alt"] = isRampStart and 0 or (placement.altitude or config.altitude or 2000),
        ["alt_type"] = isRampStart and "AGL" or "MSL",
        ["speed"] = isRampStart and 0 or (placement.speed or config.speed or 150),
        ["task"] = {
            ["id"] = "ComboTask",
            ["params"] = {
                ["tasks"] = {}
            }
        }
    }

    -- Inject ground spot anchoring parameters directly into the internal params target
    if isRampStart then
        firstWaypoint["airdromeId"] = airbaseId
    end

    table.insert(points, firstWaypoint)

    -- 3. Assemble flight routes (WP 2+)
    if config.route then
        local routePoints = UnitFormationBuilder.BuildAirRoute(startX, startY, config.route, airbaseObj, isHelo)
        for _, p in ipairs(routePoints) do
            table.insert(points, p)
        end
    end

    local groupPayload = {
        ["visible"] = true,
        ["category"] = (config.category == "AIRPLANE") and "plane" or "helicopter",
        ["country"] = config.country or "USA",
        ["name"] = config.groupName,
        ["task"] = config.task or "CAP",
        ["route"] = {
            ["points"] = points
        },
        ["units"] = unitPool
    }

    if isRampStart then
        groupPayload["airdromeId"] = airbaseId
    end

    return groupPayload
end

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



function AssetFactories.buildAWACSorTanker(originPoint, config)
    local x, y = SpatialSolver.getCoordinates(originPoint, config)

    local altitude = mist.utils.feetToMeters(config.altitude) or 8000
    local speed = mist.utils.knotsToMps(config.speed) or 150

    local wp1_x = x
    local wp1_y = y
    local wp2_x = x + mist.utils.NMToMeters(0.5) -- (mist.utils.NMToMeters(config.orbitLength) or 40000)
    local wp2_y = y + mist.utils.NMToMeters(0.5)

    -- 1. Initialize separated task lists for WP1 and WP2
    local wp1TaskList = {}
    local wp2TaskList = {}

    -- Map config task names to exact DCS Engine Task IDs
    local dcsTaskName = config.task

    -- WP1: Main Enroute Task (Must be active from spawn)
    table.insert(wp1TaskList, {
        ["id"] = dcsTaskName,
        ["params"] = {}
    })

    -- WP1: Frequency Setup
    if config.frequency then
        table.insert(wp1TaskList, {
            ["id"] = "SetFrequency",
            ["params"] = {
                ["frequency"] = config.frequency * 1000000,
                ["modulation"] = (config.modulation == "FM") and 1 or 0 -- 0 = AM, 1 = FM
            }
        })
    end

    -- WP1: Callsign Setup
    if config.callsign then
        table.insert(wp1TaskList, {
            ["id"] = "SetCallsign",
            ["params"] = {
                ["callsign"] = config.callsign,
                ["number"] = config.callsignNumber or 1
            }
        })
    end

    -- WP2: Configure the Orbit Command dynamically
    -- Supports config.orbitPattern = "Circle" or "Racetrack" (defaults to Racetrack)
    local patternChoice = config.orbitPattern or "Circle"
    
    local orbitParams = {
        ["pattern"] = patternChoice,
        ["altitude"] = altitude,
        ["speed"] = speed
    }

    if patternChoice == "Anchored" then
        orbitParams["hotLegDir"] = 180
        orbitParams["legLength"] = mist.utils.NMToMeters(config.orbitLength)
        orbitParams["width"] = mist.utils.NMToMeters(config.orbitWidth)
        orbitParams["clockWise"] = config.orbitClockwise or false
    end

    table.insert(wp2TaskList, {
        ["id"] = "Orbit",
        ["params"] = orbitParams
    })

    local payload = {
        ["visible"] = true,
        ["category"] = "AIRPLANE",
        ["country"] = config.country or "USA",
        ["name"] = config.groupName,
        ["task"] = config.task,
        ["units"] = {{
            ["type"] = config.unitType or "E-3A",
            ["name"] = config.groupName .. "_Unit_1",
            ["x"] = wp1_x,
            ["y"] = wp1_y,
            ["alt"] = altitude,
            ["alt_type"] = "BARO",
            ["speed"] = speed,
            ["heading"] = 0,
            ["skill"] = "Excellent"
        }},
        ["route"] = {
            ["points"] = {
                {
                    ["x"] = wp1_x,
                    ["y"] = wp1_y,
                    ["alt"] = altitude,
                    ["alt_type"] = "BARO",
                    ["type"] = "Turning Point",
                    ["action"] = "Turning Point",
                    ["speed"] = speed,
                    ["task"] = {
                        ["id"] = "ComboTask",
                        ["params"] = {
                            ["tasks"] = wp1TaskList -- Initialized on spawn
                        }
                    }
                }, 
                {
                    ["x"] = wp2_x,
                    ["y"] = wp2_y,
                    ["alt"] = altitude,
                    ["alt_type"] = "BARO",
                    ["type"] = "Turning Point",
                    ["action"] = "Turning Point",
                    ["speed"] = speed,
                    ["task"] = {
                        ["id"] = "ComboTask",
                        ["params"] = {
                            ["tasks"] = wp2TaskList -- Triggers the Orbit at WP2
                        }
                    }
                }
            }
        }
    }
    Utils.PrintTable(payload)
    return payload
end


function AssetFactories.buildDrone(config, x, y)
    local altitude = mist.utils.feetToMeters(config.altitude) or 4572
    local speed = mist.utils.knotsToMps(config.speed or 200)

    local payload = {
        ["visible"] = true,
        ["category"] = "AIRPLANE",
        ["country"] = config.country or "USA",
        ["name"] = config.groupName,
        ["units"] = {
            [1] = {
                ["type"] = config.unitType or "MQ-9 Reaper",
                ["name"] = config.groupName .. "_Unit_1",
                ["x"] = x,
                ["y"] = y,
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
                    ["x"] = x,
                    ["y"] = y,
                    ["alt"] = altitude,
                    ["alt_type"] = "BARO",
                    ["speed"] = speed,
                    ["action"] = "Turning Point",
                    ["type"] = "Turning Point",
                    ["task"] = {
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

-- Consolidate directly into your core tables using the configuration string keys
AssetFactories.ROE = {
    WEAPON_FREE = 0,
    OPEN_FIRE_WEAPON_FREE = 1,
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}

AssetFactories.THREAT_REACTION = {
    NO_REACTION = 0,
    PASSIVE_DEFENCE = 1,
    EVADE_FIRE = 2,
    BYPASS_AND_ESCAPE = 3,
    ALLOW_ABORT_MISSION = 4,
    AAA_EVADE_FIRE = 5 -- Note: Does not actually exist in the enum table
}

AssetFactories.OPTION_IDS = {
    ROE = 0,
    THREAT_REACTION = 1
}

-- Encapsulates task formatting to hide complex nested tables from the router logic
function AssetFactories.buildOptionCommand(optionId, optionValue)
    return {
        ["id"] = "WrappedAction",
        ["params"] = {
            ["action"] = {
                ["id"] = "SetOption",
                ["params"] = {
                    ["value"] = optionValue,
                    ["name"] = optionId
                }
            }
        }
    }
end

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
        ["route"] = {
            ["points"] = points
        },
        ["units"] = unitPool
    }
end

function AssetFactories.buildPointDefense(config, x, y)
    local pdConfig = {
        ["country"] = config.country,
        ["groupName"] = config.groupName .. "_Point_Defense",
        ["minR"] = config.pointDefense.minRadius or 100,
        ["maxR"] = config.pointDefense.maxRadius or 300,
        ["units"] = config.pointDefense.units
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
