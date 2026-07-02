
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

--- Builds waypoints for any unit type by delegating to appropriate MIST builder.
-- @param startX number Starting X coordinate
-- @param startY number Starting Y coordinate
-- @param waypoints table Array of waypoint configurations
-- @param unitType string Unit type: "GROUND", "AIRPLANE", or "HELICOPTER"
-- @param defaultAirbaseObj table Optional airbase object for landing waypoints
-- @return table Array of waypoint nodes with tasks
function UnitFormationBuilder.BuildWaypoints(startX, startY, waypoints, unitType, defaultAirbaseObj)
    -- Determine which MIST builder to use
    local wpBuilder
    if unitType == "GROUND" then
        wpBuilder = mist.ground.buildWP
    elseif unitType == "HELICOPTER" then
        wpBuilder = mist.heli.buildWP
    else -- AIRPLANE
        wpBuilder = mist.fixedWing.buildWP
    end

    local points = {}
    local currentX = startX
    local currentY = startY

    for _, wp in ipairs(waypoints or {}) do
        local wpX, wpY, aeroId, wpType, wpAction, wpSpeed, wpAlt, wpAltType

        -- Handle landing waypoints for air units
        if wp.type == "landing" or wp.type == "Land" then
            local landBase = Airbase.getByName(wp.airbaseName) or defaultAirbaseObj
            if landBase then
                local landPos = landBase:getPosition().p
                wpX, wpY = landPos.x, landPos.z
                aeroId = landBase:getID()
            else
                wpX = currentX
                wpY = currentY
            end
            wpType = "Land"
            wpAction = "Landing"
            wpSpeed = wp.speed or 0
            wpAlt = 0
            wpAltType = "AGL"
        else
            -- Standard waypoint with relative offsets
            wpX = currentX + (wp.offsetX or 0)
            wpY = currentY + (wp.offsetY or 0)
            wpType = wp.type or "Turning Point"
            wpAction = wp.action or "Turning Point"
            wpSpeed = wp.speed or 150
            wpAlt = wp.alt or 3000
            wpAltType = wp.alt_type or "BARO"
        end

        -- Build waypoint using appropriate MIST function
        local node = wpBuilder({
            x = wpX,
            y = wpY
        }, wpAction, wpSpeed, wpAlt, wpAltType)

        node.type = wpType
        if aeroId then
            node.aerodromeId = aeroId
        end

        -- Add task options (ROE and optionally THREAT_REACTION for ground units)
        node.task = {
            ["id"] = "ComboTask",
            ["params"] = {
                ["tasks"] = {}
            }
        }

        -- ROE is common to all unit types
        if wp.roe and AssetFactories.ROE[wp.roe] then
            table.insert(node.task.params.tasks, {
                ["id"] = "Option",
                ["params"] = {
                    ["name"] = AssetFactories.OPTION_IDS.ROE,
                    ["value"] = AssetFactories.ROE[wp.roe]
                }
            })
        end

        -- THREAT_REACTION only for ground units (air units use different logic)
        if unitType == "GROUND" and wp.threat and AssetFactories.THREAT_REACTION[wp.threat] then
            table.insert(node.task.params.tasks, {
                ["id"] = "Option",
                ["params"] = {
                    ["name"] = AssetFactories.OPTION_IDS.THREAT_REACTION,
                    ["value"] = AssetFactories.THREAT_REACTION[wp.threat]
                }
            })
        end

        table.insert(points, node)
        currentX = wpX
        currentY = wpY
    end

    return points
end

--- Builds waypoints for ground units (delegates to BuildWaypoints).
-- @param startX number Starting X coordinate
-- @param startY number Starting Y coordinate
-- @param waypoints table Array of waypoint configurations
-- @return table Array of waypoint nodes with tasks
function UnitFormationBuilder.BuildRoute(startX, startY, waypoints)
    return UnitFormationBuilder.BuildWaypoints(startX, startY, waypoints, "GROUND")
end

AssetFactories = {}

-- ==============================================================================
-- AIR UNIT PRODUCTION EXTENSIONS
-- ==============================================================================

--- Builds waypoints for air units (delegates to BuildWaypoints).
-- @param startX number Starting X coordinate
-- @param startY number Starting Y coordinate
-- @param waypoints table Array of waypoint configurations
-- @param defaultAirbaseObj table Optional airbase object for landing waypoints
-- @param isHelo boolean True if building for helicopter
-- @return table Array of waypoint nodes with tasks
function UnitFormationBuilder.BuildAirRoute(startX, startY, waypoints, defaultAirbaseObj, isHelo)
    local unitType = isHelo and "HELICOPTER" or "AIRPLANE"
    return UnitFormationBuilder.BuildWaypoints(startX, startY, waypoints, unitType, defaultAirbaseObj)
end

function AssetFactories.buildAirGroup(config, startX, startY, airbaseObj)
    -- Isolate the placement sub-table configuration
    local placement = config.placement or {}

    -- Simplified mode detection logic for unified placement system
    local mode = "unknown"
    local resolvedX, resolvedY = startX, startY

    -- Determine placement mode based on config fields:
    -- Mode 1: Airbase ramp slot anchoring (airbaseName present)
    if placement.airbaseName then
        mode = "mode1"  -- Airbase ramp slot anchoring
    -- Mode 2: Bearing + distance offset from origin (offsetHeading and offsetDistance present)
    elseif placement.offsetHeading and placement.offsetDistance then
        mode = "mode2"  -- Bearing + distance positioning
    -- Mode 3: Direct coordinate positioning (offsetX and offsetY both present)
    elseif placement.offsetX and placement.offsetY then
        mode = "mode3"  -- Direct coordinate positioning
    else
        -- Default fallback to Mode 3 for direct coordinate addition
        mode = "mode3"
    end

    -- Resolve coordinates based on detected mode
    if mode == "mode1" then
        -- Mode 1: Airbase ramp slot anchoring - coordinates already resolved by Sector system
        resolvedX, resolvedY = startX, startY
    elseif mode == "mode2" then
        -- Mode 2: Bearing + distance offset from origin
        resolvedX, resolvedY = SpatialSolver.getCoordinates({x = startX, y = startY}, placement)
    elseif mode == "mode3" then
        -- Mode 3: Direct coordinate addition
        resolvedX = startX + (placement.offsetX or 0)
        resolvedY = startY + (placement.offsetY or 0)
    end

    -- Extract numerical Airbase ID required for engine anchorage mapping
    local airbaseName = placement.airbaseName or config.airbaseName
    local startType = placement.startType or config.startType or "air_start"
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
        local spawnX = resolvedX
        local spawnY = resolvedY

        -- 2. DYNAMIC COORDINATE LOOKUP
        -- Extract the actual physical coordinates for this specific spot via MIST
        if isRampStart and mist.DBs.spawnsByBase and mist.DBs.spawnsByBase[airbaseName] then
            local baseData = mist.DBs.spawnsByBase[airbaseName]
            if baseData[spotStr] then
                spawnX = baseData[spotStr].x or resolvedX
                spawnY = baseData[spotStr].y or resolvedY
            end
        end

        local alt = isRampStart and 0 or mist.utils.feetToMeters(placement.altitude or config.altitude or 2000)
        local speed = isRampStart and 0 or mist.utils.knotsToMps(placement.speed or config.speed or 150)
        local headingRad = (placement.heading or config.heading or 0) * (math.pi / 180)

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
        ["x"] = unitPool[1] and unitPool[1].x or resolvedX, -- Aligns perfectly with Unit 1
        ["y"] = unitPool[1] and unitPool[1].y or resolvedY, -- Aligns perfectly with Unit 1
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
        local routePoints = UnitFormationBuilder.BuildAirRoute(resolvedX, resolvedY, config.route, airbaseObj, isHelo)
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



-- AWACS/Tanker specific task builders

--- Builds frequency setup task for AWACS/Tanker
function AssetFactories.buildFrequencyTask(frequency, modulation)
    return {
        ["id"] = "SetFrequency",
        ["params"] = {
            ["frequency"] = frequency * 1000000,
            ["modulation"] = (modulation == "FM") and 1 or 0 -- 0 = AM, 1 = FM
        }
    }
end

--- Builds callsign setup task for AWACS/Tanker
function AssetFactories.buildCallsignTask(callsign, number)
    return {
        ["id"] = "SetCallsign",
        ["params"] = {
            ["callsign"] = callsign,
            ["number"] = number or 1
        }
    }
end

--- Builds orbit task with various patterns
-- @param config table AWACS/Tanker configuration with orbit parameters
-- @return table Orbit task configuration
function AssetFactories.buildOrbitTask(config)
    local patternChoice = config.orbitPattern or "Circle"

    local orbitParams = {
        ["pattern"] = patternChoice,
        ["altitude"] = config.altitude or 8000,
        ["speed"] = config.speed or 150
    }

    if patternChoice == "Anchored" then
        orbitParams["hotLegDir"] = 180
        orbitParams["legLength"] = mist.utils.NMToMeters(config.orbitLength or 5)
        orbitParams["width"] = mist.utils.NMToMeters(config.orbitWidth or 2)
        orbitParams["clockWise"] = config.orbitClockwise or false
    end

    return {
        ["id"] = "Orbit",
        ["params"] = orbitParams
    }
end

--- Builds AWACS or Tanker group with proper orbit task routing.
-- AWACS/Tankers are air units that orbit at a fixed location to provide services.
-- @param originPoint table Bullseye or reference coordinates {x, y}
-- @param config table AWACS/Tanker configuration
-- @return table DCS group payload ready for mist.dynAdd
function AssetFactories.buildAWACSorTanker(originPoint, config)
    -- Check for airbase anchoring
    local placement = config.placement or {}
    if placement.airbaseName then
        return AssetFactories.buildAirGroup(config, originPoint.x, originPoint.y, nil)
    end

    -- Use existing SpatialSolver to get coordinates (handles bearing/distance, direct coords, fallback)
    local x, y = SpatialSolver.getCoordinates(originPoint, placement)

    -- Build orbit task
    local orbitTask = AssetFactories.buildOrbitTask(config)

    -- Build frequency/callsign tasks if specified
    local firstWaypointTasks = {}
    if config.frequency then
        table.insert(firstWaypointTasks, AssetFactories.buildFrequencyTask(config.frequency, config.modulation))
    end
    if config.callsign then
        table.insert(firstWaypointTasks, AssetFactories.buildCallsignTask(config.callsign, config.callsignNumber))
    end

    -- Build route with orbit task at waypoint 2, optional tasks at waypoint 1
    local waypoints = {
        {
            type = "Turning Point",
            alt = config.altitude,
            speed = config.speed,
            offsetX = 0,
            offsetY = 0,
            task = #firstWaypointTasks > 0 and {
                ["id"] = "ComboTask",
                ["params"] = { ["tasks"] = firstWaypointTasks }
            } or nil
        },
        {
            type = "Turning Point",
            alt = config.altitude,
            speed = config.speed,
            offsetX = mist.utils.NMToMeters(0.5), -- Small offset for orbit entry
            offsetY = 0,
            task = orbitTask
        }
    }

    -- Reuse buildAirGroup's unit assembly logic
    local unitConfig = {
        category = "AIRPLANE",
        groupName = config.groupName,
        country = config.country or "USA",
        units = {{
            unitType = config.unitType or "E-3A",
            name = config.groupName .. "_Unit_1"
        }},
        placement = {
            heading = placement.heading,
            offsetX = x,
            offsetY = y,
            altitude = config.altitude,
            speed = config.speed
        },
        route = waypoints
    }

    return AssetFactories.buildAirGroup(unitConfig, x, y, nil)
end


function AssetFactories.buildDrone(config, x, y)
    -- For drones, we now delegate to buildAirGroup to utilize the unified placement system
    -- This allows drones to benefit from all three placement modes (ramp slot, bearing/distance, direct coordinates)

    -- Create a temporary config that includes the position information
    local droneConfig = {
        groupName = config.groupName,
        country = config.country or "USA",
        category = "AIRPLANE",
        task = "CAP",  -- Default task for drones
        units = {
            {
                unitType = config.unitType or "MQ-9 Reaper",
                name = config.groupName .. "_Unit_1"
            }
        },
        placement = {
            heading = config.heading,
            offsetX = x,
            offsetY = y,
            altitude = config.altitude,
            speed = config.speed
        },
        route = {
            {
                type = "Turning Point",
                alt = config.altitude or 4572,  -- Default to ~15000 feet in meters (already handled by UnitRouteWaypoint.new)
                speed = config.speed or 200,     -- Default to 200 m/s (already handled by UnitRouteWaypoint.new)
                offsetX = 0,
                offsetY = 0
            }
        }
    }

    -- Delegate to buildAirGroup which now handles all placement modes
    local payload = AssetFactories.buildAirGroup(droneConfig, x, y, nil)

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

function AssetFactories.activatePointDefense(adGroup)
    for idx, unit in ipairs(adGroup.units) do
        TriggerRegistry.scheduleAction(1.5, function()
            local g = Group.getByName(adGroup.name)
            if g and g:getController() then
                g:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
            end
        end, {})
    end
end
