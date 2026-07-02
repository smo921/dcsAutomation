-- ==============================================================================
-- UNIT MANAGEMENT MODULE
-- ==============================================================================
-- Provides core logic for unit management, spatial calculations, trigger
-- evaluation, and sector handling for DCS World mission scripting.
-- Units in config: altitude in feet, distance in nautical miles, speed in knots.
-- Conversions to meters/m/s handled by constructors/factories.
-- ==============================================================================

-- ============================================================================
-- SECTION 1: CONFIGURATION STANDARDS
-- ============================================================================

--- Standardized configuration structures and utilities for DCS mission scripting.
-- @module config_standards

ConfigStandards = {}

-- Configuration Templates - All use feet, nautical miles, knots for user clarity
ConfigStandards.SECTOR_TEMPLATE = {
    enabled = true,
    category = "GROUND", -- "GROUND", "AIRPLANE", "HELICOPTER"
    triggerType = "IMMEDIATE", -- "IMMEDIATE", "TRIGGER_ZONE", "RADAR", "OBJECTIVE_COMPLETE"
    zoneName = nil,
    groupName = "",
    unitType = nil,
    parentGroupName = nil,
    country = "Russia",
    units = {},
    placement = {
        heading = 0,
        offsetX = 0,
        offsetY = 0,
        spawnRadius = 0,
        offsetHeading = nil,
        offsetDistance = nil,
        altitude = nil, -- FEET
        speed = nil, -- KNOTS
        strategy = "",
        zoneName = nil,
        groupName = nil,
        waypoint = nil,
        startType = nil,
        airbaseName = nil
    },
    route = {},
    task = nil,
    drone = nil
}

ConfigStandards.ROUTE_WAYPOINT_TEMPLATE = {
    type = "Turning Point",
    speed = 200, -- KNOTS
    alt = 3000, -- FEET
    offsetX = 0,
    offsetY = 0,
    roe = nil,
    threat = nil,
    airbaseName = nil,
    action = nil,
    alt_type = "BARO"
}

ConfigStandards.AIR_UNIT_TEMPLATE = {
    unitType = "",
    name = "",
    groundSpot = nil
}

ConfigStandards.DRONE_TEMPLATE = {
    enabled = true,
    groupName = "",
    unitType = "MQ-9 Reaper",
    country = "USA",
    heading = 0,
    altitude = 15000, -- FEET
    speed = 200, -- KNOTS
    targetX = nil,
    targetY = nil
}

ConfigStandards.RADAR_SECTOR_TEMPLATE = {
    radarFilterEnabled = false,
    pointDefense = nil,
    maxDetectRange = 200000.0, -- METERS (DCS internal)
    triggeredUnits = nil
}

ConfigStandards.POINT_DEFENSE_TEMPLATE = {
    minRadius = 100, -- METERS
    maxRadius = 300, -- METERS
    units = {}
}

-- Deep copy a table structure
function ConfigStandards.deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = ConfigStandards.deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Merge two configuration tables, with the second taking precedence
function ConfigStandards.mergeConfig(defaults, overrides)
    if not defaults then return {} end
    if not overrides then return ConfigStandards.deepCopy(defaults) end

    local result = ConfigStandards.deepCopy(defaults)

    for key, value in pairs(overrides) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = ConfigStandards.mergeConfig(result[key], value)
        else
            result[key] = value
        end
    end

    return result
end

-- Create a new sector configuration based on the template
function ConfigStandards.createSector(config)
    return ConfigStandards.mergeConfig(ConfigStandards.SECTOR_TEMPLATE, config or {})
end

-- Create a new route waypoint based on the template.
-- Handles unit conversion: feet->meters, knots->m/s, NM->meters
function ConfigStandards.createWaypoint(config)
    local wp = ConfigStandards.mergeConfig(ConfigStandards.ROUTE_WAYPOINT_TEMPLATE, config or {})

    -- Convert to internal metric units
    wp.speed = mist.utils.knotsToMps(wp.speed)
    wp.alt = mist.utils.feetToMeters(wp.alt)
    wp.offsetX = mist.utils.NMToMeters(wp.offsetX)
    wp.offsetY = mist.utils.NMToMeters(wp.offsetY)

    return wp
end

-- Create a new air unit based on the template
function ConfigStandards.createAirUnit(config)
    return ConfigStandards.mergeConfig(ConfigStandards.AIR_UNIT_TEMPLATE, config or {})
end

-- Create a new drone configuration based on the template.
-- Handles unit conversion: feet->meters, knots->m/s
function ConfigStandards.createDrone(config)
    local drone = ConfigStandards.mergeConfig(ConfigStandards.DRONE_TEMPLATE, config or {})

    -- Convert to internal metric units
    drone.altitude = mist.utils.feetToMeters(drone.altitude)
    drone.speed = mist.utils.knotsToMps(drone.speed)

    return drone
end

-- Create a new radar sector configuration based on the template
function ConfigStandards.createRadarSector(config)
    local sector = ConfigStandards.createSector(config)
    local radarConfig = ConfigStandards.mergeConfig(ConfigStandards.RADAR_SECTOR_TEMPLATE, config or {})

    for key, value in pairs(radarConfig) do
        if key ~= "triggeredUnits" then
            sector[key] = value
        end
    end

    if config and config.triggeredUnits then
        sector.triggeredUnits = ConfigStandards.createSector(config.triggeredUnits)
    end

    return sector
end

-- Create a new point defense configuration based on the template.
-- Handles unit conversion: NM to meters for radius values
function ConfigStandards.createPointDefense(config)
    local pd = ConfigStandards.mergeConfig(ConfigStandards.POINT_DEFENSE_TEMPLATE, config or {})

    -- Convert NM to meters for radius values if they were specified as NM
    if pd.minRadius and pd.minRadius < 10 then
        pd.minRadius = mist.utils.NMToMeters(pd.minRadius)
    end
    if pd.maxRadius and pd.maxRadius < 10 then
        pd.maxRadius = mist.utils.NMToMeters(pd.maxRadius)
    end

    return pd
end

-- Validate a configuration against a template
function ConfigStandards.validateConfig(config, template, path)
    path = path or "root"

    if type(config) ~= "table" then
        return false, string.format("Expected table at %s, got %s", path, type(config))
    end

    for key, expectedValue in pairs(template) do
        local value = config[key]
        local currentPath = path .. "." .. key

        if type(expectedValue) == "table" and type(value) == "table" then
            local valid, error = ConfigStandards.validateConfig(value, expectedValue, currentPath)
            if not valid then
                return false, error
            end
        elseif value ~= nil and type(value) ~= type(expectedValue) then
            return false, string.format("Type mismatch at %s: expected %s, got %s",
                currentPath, type(expectedValue), type(value))
        end
    end

    return true
end

-- ============================================================================
-- SECTION 2: UTILITIES
-- ============================================================================

--- Check if a table is nil or empty.
-- @param t table The table to check
-- @return boolean true if table is nil or empty
local function isNilOrEmpty(t)
    return not t or next(t) == nil
end

--- Get waypoint data from a flight's route.
-- @param flightName string The group name
-- @param waypoint number The waypoint index (1-based)
-- @return table|nil The waypoint data or nil
local function getWaypointFromFlight(flightName, waypoint)
    local flightPlan = mist.getGroupRoute(flightName)
    if flightPlan and flightPlan[waypoint] then
        return flightPlan[waypoint]
    end
end

--- Print flight path waypoints to log.
-- @param flightName string The group name
local function printFlightPath(flightName)
    local flightPlan = mist.getGroupRoute(flightName)
    if flightPlan then
        for i, waypoint in ipairs(flightPlan) do
            env.info(string.format("Waypoint %d - X: %.2f Y: %.2f", i, waypoint.x, waypoint.y))
        end
    end
end

--- Print surface type name to log for debugging.
-- @param surfaceType number The surface type index
local function printSurfaceType(surfaceType)
    for str, ind in pairs(land.SurfaceType) do
        if ind == surfaceType then
            env.info(string.format("point is type %d String: %s", surfaceType, str))
        end
    end
end

--- Determines whether a group is eligible to be spawned.
-- Prevents duplicate spawning of active assets and unwanted re-spawning of destroyed ones.
-- @param groupName string The tracking name of the group.
-- @return boolean true if it is safe and valid to spawn the group; false otherwise.
local function shouldGroupSpawn(groupName)
    if not groupName then return false end

    local gp = Group.getByName(groupName)

    -- STATE 1: Group object does not exist anywhere in the active simulation database.
    -- This means it has never been spawned yet. Safe to deploy!
    if gp == nil or gp:isExist() == false then
        return true
    end

    -- STATE 2: The group container exists. Check if any units are still breathing.
    for i = 1, gp:getSize() do
        local unit = gp:getUnit(i)
        if unit and unit:isExist() and unit:isActive() and unit:getLife() > 1 then
            -- Found alive units. The asset is active in the world right now.
            env.info(string.format("[SpawnGuard] Blocked spawn for '%s': Group is already active in theater.", groupName))
            return false
        end
    end

    -- STATE 3: The group container exists, but every single unit has been destroyed.
    -- This prevents dead units from popping back into existence.
    env.info(string.format("[SpawnGuard] Blocked spawn for '%s': Group was already deployed and neutralized.", groupName))
    return false
end

-- ============================================================================
-- SECTION 3: MAP MARKER REGISTRY
-- ============================================================================

MapMarkerRegistry = {
    activeMarkers = {}, -- Keys: sector/group name, Value: { id = Int, lastPos = vec3, text = String }
    activeRadios = {} -- Key: groupName, Value: menuRef
}

--- Generate a unique marker ID or update an existing one safely.
-- @param trackingKey string The tracking key (sector/group name)
-- @param textMessage string The text message to display
-- @param positionVector table The position {x, y, z}
-- @return number newMarkerId The marker ID that was created
function MapMarkerRegistry.drawTacticalMark(trackingKey, textMessage, positionVector)
    -- Clean up old marker if one already exists for this track
    MapMarkerRegistry.clearMark(trackingKey)

    -- Generate a unique marker ID
    local newMarkerId = math.random(100000, 999999)

    -- Draw to all players in the coalition
    trigger.action.markToAll(newMarkerId, textMessage, positionVector, true)

    -- Store state internally
    MapMarkerRegistry.activeMarkers[trackingKey] = {
        id = newMarkerId,
        pos = positionVector,
        text = textMessage,
        updatedAt = timer.getTime()
    }

    env.info(string.format("[MarkerRegistry] Rendered tactical mark ID %d for track '%s'", newMarkerId, trackingKey))
    return newMarkerId
end

--- Safely remove a marker from the F10 map layout.
-- @param trackingKey string The tracking key (sector/group name)
function MapMarkerRegistry.clearMark(trackingKey)
    local markerData = MapMarkerRegistry.activeMarkers[trackingKey]
    if markerData then
        -- Native DCS World API hook to yank it from everyone's map screens
        trigger.action.removeMark(markerData.id)
        MapMarkerRegistry.activeMarkers[trackingKey] = nil
    end
end

-- ============================================================================
-- SECTION 4: SPATIAL SOLVER
-- ============================================================================

SpatialSolver = {}
SpatialSolver.VALID_LAND_TYPES = {
    [1] = true, -- Land / Fields
    [4] = true, -- Runway / Pavement
    [5] = true  -- Grass / Shorelines
}
SpatialSolver.DEFAULT_CLEARANCE_RADIUS = 12 -- meters

--- Get the bullseye coordinates for a given coalition.
-- @param coalition string "blue" or "red"
-- @return table|nil bullseye coordinates {x, y} or nil
function SpatialSolver.getBullseye(coalition)
    return mist.DBs.missionData["bullseye"][coalition]
end

--- Check if terrain at coordinates is clear for spawning.
-- @param x number X coordinate
-- @param y number Y coordinate
-- @param radius number Radius to check around the point
-- @return boolean true if terrain is clear, false otherwise
function SpatialSolver.terrainIsClear(x, y, radius)
    -- Check surface type (not water)
    if land.getSurfaceType({x = x, y = y}) == 3 then
        return false -- surface type is water
    elseif SpatialSolver.findStaticObstructions(x, y, radius) == true then
        return false
    elseif SpatialSolver.countSceneryObstructions(x, y, radius) > 0 then
        -- 2. CRITICAL: Use your scenery scanner to check for trees!
        -- A radius of 15-20 meters ensures enough physical space for a tank/vehicle.
        return false
    end
    return true
end

--- Get coordinates based on placement configuration.
-- Supports three modes:
-- 1. Bearing + distance (offsetHeading + offsetDistance) - both in NM
-- 2. Direct coordinates (offsetX + offsetY) - in NM
-- 3. Group waypoint positioning (groupName + waypoint)
-- @param origin table Origin coordinates {x, y}
-- @param placementConfig table Placement configuration (NM for distances)
-- @return number x, number y Resolved coordinates
function SpatialSolver.getCoordinates(origin, placementConfig)
    local x, y = origin.x, origin.y

    -- Check for bearing/distance positioning first (both in NM)
    if placementConfig.offsetHeading and placementConfig.offsetDistance then
        return SpatialSolver.getVector(origin, placementConfig.offsetHeading, placementConfig.offsetDistance)
    -- Then check for direct coordinate positioning (in NM)
    elseif placementConfig.offsetX and placementConfig.offsetY then
        -- Convert NM to meters for coordinate offset
        local offsetX = mist.utils.NMToMeters(placementConfig.offsetX)
        local offsetY = mist.utils.NMToMeters(placementConfig.offsetY)
        return x + offsetX, y + offsetY
    -- Then check for group waypoint positioning
    elseif placementConfig.groupName and placementConfig.waypoint then
        env.info(string.format("[SpatialSolver] Placing unit near group: %s waypoint: %s",
                    placementConfig.groupName, placementConfig.waypoint))
        local wp = getWaypointFromFlight(placementConfig.groupName, placementConfig.waypoint)
        return wp.x, wp.y
    else
        return x, y
    end
end

--- Calculate vector coordinates from origin using heading and distance.
-- Distance is in nautical miles (NM), heading in degrees.
-- Uses aviation convention: 0° = North, 90° = East
-- @param origin table Origin coordinates {x, y}
-- @param heading number Heading in degrees (0 = North)
-- @param distance number Distance in nautical miles
-- @return number x, number y Target coordinates in meters
function SpatialSolver.getVector(origin, heading, distance)
    local x, y
    local headingDeg = heading or 180
    local distanceNm = distance or 60

    -- Convert to mathematical convention where 0° = East
    local headingRad = math.rad(90 - headingDeg)
    local distanceMeters = mist.utils.NMToMeters(distanceNm)

    -- Vector Projection away from Bullseye center
    x = origin.x + (math.cos(headingRad) * distanceMeters)
    y = origin.y + (math.sin(headingRad) * distanceMeters)
    return x, y
end

--- Attempts to find a safe spawn location by searching outward from origin.
-- @param x number Starting X coordinate
-- @param y number Starting Y coordinate
-- @param radius number Radius to search within (optional, default: 25 meters)
-- @param groupName string Optional group name for logging context
-- @return number finalX, number finalY Safe coordinates or fallback
function SpatialSolver.searchArea(x, y, radius, groupName)
    local safeFound = false
    local attempts = 0
    local maxAttempts = 20
    local finalX, finalY

    -- Keep trying to find a clear spot
    while not safeFound and attempts < maxAttempts do
        attempts = attempts + 1

        local randomAngle = math.random() * 2 * math.pi
        local randomDist = math.random() * (radius or 25)

        local checkX = x + (math.cos(randomAngle) * randomDist)
        local checkY = y + (math.sin(randomAngle) * randomDist)

        if SpatialSolver.terrainIsClear(checkX, checkY, 50) == true then
            finalX = checkX
            finalY = checkY
            safeFound = true
        end
    end

    -- Fallback: If 20 attempts all hit dense forest, fall back to random offset
    if not safeFound then
        finalX = x + (math.random(-50, 50))
        finalY = y + (math.random(-50, 50))
        -- Note: This fallback is acceptable for non-critical spawn locations
        -- Critical spawn points (radar, airbases) should have explicit coordinate validation
        if groupName then
            env.info(string.format(
                "[SpatialSolver] Could not find clear spot for '%s' after %d attempts. Using fallback near center.",
                groupName, maxAttempts))
        end
    end

    return finalX, finalY
end

--- Finds a safe place inside a trigger zone, or based on coordinates and placement config.
-- Placement config distances are in nautical miles (NM).
-- @param startingPosition table Starting position {x, y}
-- @param placementConfig table Placement configuration (NM for distances)
-- @param groupName string Optional group name for logging
-- @return number x, number y Safe coordinates
function SpatialSolver.findSafeGroundCoordinates(startingPosition, placementConfig, groupName)
    local startX, startY

    -- Strategy 1: Zone Randomization
    if placementConfig.strategy == "ZONE_RANDOM" then
        local zoneData = trigger.misc.getZone(placementConfig.zoneName)
        if zoneData then
            local point = mist.getRandomPointInZone(placementConfig.zoneName)
            -- Check surface type (not water)
            if SpatialSolver.terrainIsClear(point.x, point.y, 20) then
                return point.x, point.y
            end
            startX = zoneData.point.x
            startY = zoneData.point.z
        end
    else
        startX, startY = SpatialSolver.getCoordinates(startingPosition, placementConfig)
    end

    -- Convert spawnRadius from NM to meters for searchArea
    local searchRadius = SpatialSolver.DEFAULT_CLEARANCE_RADIUS
    if placementConfig.spawnRadius and placementConfig.spawnRadius > 0 then
        searchRadius = mist.utils.NMToMeters(placementConfig.spawnRadius)
    end

    return SpatialSolver.searchArea(startX, startY, searchRadius, groupName)
end

--- Count scenery obstructions in a circular area.
-- @param x number Center X coordinate
-- @param y number Center Y coordinate
-- @param radius number Radius to check
-- @return number Count of obstructions found
function SpatialSolver.countSceneryObstructions(x, y, radius)
    local obstructionCount = 0
    local sphere = {
        id = world.VolumeType.SPHERE,
        params = {
            point = {
                x = x,
                y = land.getHeight({x = x, y = y}),
                z = y
            },
            radius = radius
        }
    }

    -- Layer 1: Scan for standard map scenery (individual trees, small houses)
    world.searchObjects(Object.Category.SCENERY, sphere, function(obj)
        obstructionCount = obstructionCount + 1
        return true
    end)

    -- Layer 2: Scan for base structures (dense urban city blocks, industrial complexes)
    world.searchObjects(Object.Category.BASE, sphere, function(obj)
        obstructionCount = obstructionCount + 1
        return true
    end)

    return obstructionCount
end

--- Check for static obstructions in a circular area.
-- @param x number Center X coordinate
-- @param y number Center Y coordinate
-- @param radius number Radius to check
-- @return boolean true if obstruction found, false otherwise
function SpatialSolver.findStaticObstructions(x, y, radius)
    local hasObstruction = false
    local sphere = {
        id = world.VolumeType.SPHERE,
        params = {
            point = {
                x = x,
                y = land.getHeight({x = x, y = y}),
                z = y
            },
            radius = radius
        }
    }

    world.searchObjects(Object.Category.SCENERY, sphere, function(obj)
        hasObstruction = true
        return false
    end)

    return hasObstruction
end

-- ============================================================================
-- SECTION 5: RADAR HANDLER
-- ============================================================================

RadarHandler = {}

--- Convert kilometers to nautical miles.
-- @param km number Distance in kilometers
-- @return number Distance in nautical miles
function RadarHandler.KmToNm(km)
    return km / 1.852
end

--- Calculate the straight-line distance (nm) between two DCS units.
-- Works even if one of the units has been destroyed.
-- @param unitA table Unit A or nil
-- @param unitB table Unit B or nil
-- @return number|nil Distance in nautical miles, or nil if either unit is missing
function RadarHandler.getDistanceInNM(unitA, unitB)
    if not (unitA and unitB) then
        return nil
    end

    local posA = unitA:getPosition().p
    local posB = unitB:getPosition().p

    if not (posA and posB) then
        return nil
    end

    local dx = posA.x - posB.x
    local dy = posA.y - posB.y
    local dz = posA.z - posB.z

    local distanceKM = math.sqrt(dx * dx + dy * dy + dz * dz) / 1000
    return RadarHandler.KmToNm(distanceKM)
end

--- Pretty-print a single detection.
-- @param radar table Radar unit
-- @param target table Target detection
-- @return string Formatted detection string
function RadarHandler.formatDetection(radar, target)
    local name = target.object:getName() or "Unknown"
    local dist = RadarHandler.getDistanceInNM(radar, target.object) or 0
    local range = string.format("%.1f nm", dist)
    return string.format("%s - %s", name, range)
end

-- Aircraft types to filter out as non-threats
RadarHandler.filterByAircraft = { "KC-135", "E-3A", "MQ-9 Reaper" }

--- Determine if an aircraft is a threat based on type filtering.
-- @param aircraft table Aircraft detection data
-- @return boolean true if it is a threat, false otherwise
function RadarHandler.isThreat(aircraft)
    -- Handle nil or missing aircraft data
    if not aircraft or not aircraft.object or not aircraft.object:isExist() then
        return false
    end

    -- Pull the actual vehicle/aircraft type name (e.g., "F-16C_50" or "AH-64D_BLK_II")
    local typeName = aircraft.object:getTypeName() or "Unknown Type"

    -- Check if aircraft type is in the non-threat filter list
    for _, filterType in ipairs(RadarHandler.filterByAircraft) do
        if string.find(typeName, filterType, 1, true) then
            return false -- Not a threat
        end
    end

    -- If not in the non-threat list, consider it a threat
    return true
end

--- Log a detected threat to the DCS log.
-- @param radarUnit table The radar unit detecting the threat
-- @param det table The detected target
function RadarHandler.logThreat(radarUnit, det)
    if det.object and det.object:isExist() then
        local typeName = det.object:getTypeName() or "Unknown Type"
        local unitName = det.object:getName() or "Unknown Unit"
        local distance = RadarHandler.getDistanceInNM(radarUnit, det.object) or 0

        env.info(string.format("[CheckRadar] Found Target -> Type: %s | Unit Name: %s | Range: %.1f nm",
            typeName, unitName, distance))
    end
end

--- Main routine that queries the radar for detections.
-- @param radarSector table The radar sector configuration
-- @return boolean true if a threat was detected, false otherwise
function RadarHandler.checkRadar(radarSector)
    local groupName = radarSector.groupName
    local radarGroup = Group.getByName(radarSector.groupName)
    if not radarGroup then
        return false
    end

    local radarUnit = radarGroup:getUnit(1)
    if not radarUnit then
        return false
    end

    local controller = radarUnit:getController()
    if not controller then
        local message = string.format(
            "[RadarCheck] ERROR: Radar unit '%s' has no controller. Is it alive and active?", radarUnit:getName())
        trigger.action.outText(message, 10)
        env.error(message)
        return false
    end

    local detections = controller:getDetectedTargets()
    local threatFound = false

    if detections and #detections > 0 then
        for _, det in ipairs(detections) do
            -- Flag to decide whether target is found
            threatFound = true

            if radarSector.radarFilterEnabled then
                threatFound = RadarHandler.isThreat(det)
            end

            -- Optional: ignore very far detections (maxDetectRange is in meters)
            if threatFound and det.distance then
                local distance = RadarHandler.getDistanceInNM(radarUnit, det.object)
                if distance and distance > radarSector.maxDetectRange then
                    threatFound = false
                    env.info(string.format("[RadarCheck] Skipping – beyond max range (%.1f nm).", radarSector.maxDetectRange))
                end
            end

            if threatFound then
                return threatFound
            end
        end
    end

    return threatFound
end

-- ============================================================================
-- SECTION 6: TRIGGER REGISTRY
-- ============================================================================

TriggerRegistry = {
    monitoredSectors = {},
    actionQueue = {},
    isActive = false,
    tickInterval = 15.0 -- Evaluation heartbeat frequency in seconds
}

--- Add a sector to the tracking pool.
-- @param sectorInstance table The sector instance to monitor
function TriggerRegistry.register(sectorInstance)
    table.insert(TriggerRegistry.monitoredSectors, sectorInstance)
    TriggerRegistry._ensureHeartbeat()
end

--- Schedule a delayed action to execute after a delay.
-- @param delaySeconds number Delay in seconds
-- @param callbackFunction function Function to call
-- @param contextArgs table Arguments to pass to the callback
function TriggerRegistry.scheduleAction(delaySeconds, callbackFunction, contextArgs)
    local actionPayload = {
        executeAt = timer.getTime() + delaySeconds,
        callback = callbackFunction,
        args = contextArgs or {}
    }
    table.insert(TriggerRegistry.actionQueue, actionPayload)
    TriggerRegistry._ensureHeartbeat()
end

--- Ensure the heartbeat loop is running.
function TriggerRegistry._ensureHeartbeat()
    if not TriggerRegistry.isActive then
        TriggerRegistry.isActive = true
        timer.scheduleFunction(TriggerRegistry._heartbeat, {}, timer.getTime() + TriggerRegistry.tickInterval)
    end
end

--- The private master loop handler.
-- @param args table Arguments (unused)
-- @param time number Current time
-- @return number|nil Next execution time or nil to sleep
function TriggerRegistry._heartbeat(args, time)
    local currentTime = timer.getTime()

    -- --------------------------------------------------------------------------
    -- JOB 1: PROCESS DELAYED FUNCTIONS (ACTION QUEUE)
    -- --------------------------------------------------------------------------
    for i = #TriggerRegistry.actionQueue, 1, -1 do
        local action = TriggerRegistry.actionQueue[i]

        if currentTime >= action.executeAt then
            -- Safely execute the function passing its context arguments
            local success, err = pcall(action.callback, action.args)
            if not success then
                env.info(string.format("[TriggerRegistry Error] Action callback failed: %s", tostring(err)))
            end

            table.remove(TriggerRegistry.actionQueue, i)
        end
    end

    -- --------------------------------------------------------------------------
    -- JOB 2: PROCESS SECTOR MONITORING TRIGGERS
    -- --------------------------------------------------------------------------
    for i = #TriggerRegistry.monitoredSectors, 1, -1 do
        local sector = TriggerRegistry.monitoredSectors[i]
        if TriggerRegistry.evaluate(sector) then
            table.remove(TriggerRegistry.monitoredSectors, i)
        end
    end

    -- Sleep the loop if there's absolutely nothing left to do
    if #TriggerRegistry.monitoredSectors == 0 and #TriggerRegistry.actionQueue == 0 then
        TriggerRegistry.isActive = false
        env.info("[TriggerRegistry] All queues cleared. Sleeping heartbeat loop.")
        return nil
    end

    return time + TriggerRegistry.tickInterval
end

--- Process the sector. Return true to signal that all processing is complete.
-- @param sector table The sector to evaluate
-- @return boolean true if sector processing is complete
function TriggerRegistry.evaluate(sector)
    if sector.drone and sector.drone.enabled then
        -- check if drone is dead and cleanup
        local isDead = sector:checkDroneDead()
        if isDead then
            sector.drone.enabled = false
        end
    end

    if sector.triggerType == "TRIGGER_ZONE" then
        local triggered = TriggerRegistry._checkZone(sector.zoneName)
        local shouldSpawn = shouldGroupSpawn(sector.groupName)
        if triggered and shouldSpawn then
            sector:spawnUnits()
        end
        return triggered

    elseif sector.triggerType == "RADAR" then
        TriggerRegistry._checkRadarDetection(sector)

    elseif sector.triggerType == "OBJECTIVE_COMPLETE" then
        return TriggerRegistry._checkGroupDestroyed(sector.parentGroupName)

    else
        -- Unrecognized or faulty trigger logic drops safe fallback logging
    end

    return false
end

--- Check if blue units are in a trigger zone.
-- @param zoneName string Name of the zone to check
-- @return boolean true if blue units are in the zone
function TriggerRegistry._checkZone(zoneName)
    if not zoneName or not trigger.misc.getZone(zoneName) then
        env.info("[TriggerRegistry] Zone not found.")
        return false
    end

    local blueUnits = mist.makeUnitTable({'[blue]'})
    local playersInZone = mist.getUnitsInZones(blueUnits, {zoneName})
    return playersInZone ~= nil and #playersInZone > 0
end

--- Check for radar detection and spawn triggered units.
-- @param radarSector table The radar sector configuration
function TriggerRegistry._checkRadarDetection(radarSector)
    local threatFound = RadarHandler.checkRadar(radarSector)
    if threatFound and shouldGroupSpawn(radarSector.triggeredUnits.groupName) then
        radarSector:spawnTriggeredUnits()
    end
end

--- Check if a parent group has been destroyed.
-- @param parentGroupName string Name of the parent group
-- @return boolean true if the group is destroyed or doesn't exist
function TriggerRegistry._checkGroupDestroyed(parentGroupName)
    if not parentGroupName then
        return true
    end

    local gp = Group.getByName(parentGroupName)

    -- If the group reference returns nil or contains no active units
    if gp == nil or gp:isExist() == false or gp:getSize() == 0 then
        return true
    end

    -- Double check if units have structural lifepoints remaining
    for i = 1, gp:getSize() do
        local unit = gp:getUnit(i)
        if unit and unit:isActive() and unit:getLife() > 1 then
            return false -- At least one asset is still fighting
        end
    end

    return true
end

-- ============================================================================
-- SECTION 7: UNIT SPAWNER
-- ============================================================================

UnitSpawner = {}

--- Resolve spawn coordinates based on configuration.
-- @param config table The unit configuration with placement details (NM for distances)
-- @param defaultBullseye table Default bullseye coordinates if fallback needed
-- @param groupName string Optional group name for logging
-- @return number x, number y Resolved spawn coordinates
function UnitSpawner.resolveSpawnCoordinates(config, defaultBullseye, groupName)
    local placement = config.placement or {}

    -- Mode 1: Airbase anchoring (for air units)
    if placement.airbaseName then
        local airbaseObj = Airbase.getByName(placement.airbaseName)
        if airbaseObj then
            local basePos = airbaseObj:getPosition().p
            return basePos.x, basePos.z
        else
            env.warn(string.format("[UnitSpawner] Airbase '%s' not found for '%s', using fallback.",
                placement.airbaseName, groupName or "unknown"))
        end
    end

    -- Mode 2: Ground units - find safe coordinates
    if config.category ~= "AIRPLANE" and config.category ~= "HELICOPTER" then
        return SpatialSolver.findSafeGroundCoordinates(defaultBullseye, placement, groupName)
    end

    -- Mode 3: Air fallback to bullseye
    local bullseye = defaultBullseye or SpatialSolver.getBullseye("blue")
    if bullseye then
        return bullseye.x, bullseye.y
    end

    return 0, 0  -- Hard fallback to origin
end

--- Spawns a group from configuration.
-- @param config table Unit configuration
-- @param defaultBullseye table Bullseye coordinates for fallback
-- @param groupName string Optional group name for logging
-- @return table|nil The spawned group payload, or nil on failure
function UnitSpawner.spawnGroup(config, defaultBullseye, groupName)
    if isNilOrEmpty(config) or isNilOrEmpty(config.units) then
        env.warn(string.format("[UnitSpawner] Spawn failed for '%s': empty configuration", groupName))
        return nil
    end

    local x, y = UnitSpawner.resolveSpawnCoordinates(config, defaultBullseye, groupName)

    if config.category == "AIRPLANE" or config.category == "HELICOPTER" then
        local airbaseObj = config.placement.airbaseName and Airbase.getByName(config.placement.airbaseName)
        local units = AssetFactories.buildAirGroup(config, x, y, airbaseObj)
        if units then
            mist.dynAdd(units)
            return units
        end
    else
        local units = AssetFactories.buildPlatoon(config, x, y)
        mist.dynAdd(units)
        return units
    end

    return nil
end

--- Spawns radar station with radar-specific logic.
-- @param radarSector table The radar sector configuration
-- @return boolean true if spawned successfully
function UnitSpawner.spawnRadarStation(radarSector)
    if not radarSector.groupName or not radarSector.unitType then
        env.error("[UnitSpawner] Radar spawn failed: missing groupName or unitType")
        return false
    end

    local zoneName = radarSector.placement.zoneName
    local finalX, finalY

    -- Strategy 1: Zone Randomization
    if zoneName then
        local zoneData = trigger.misc.getZone(zoneName)
        if zoneData then
            local point = mist.getRandomPointInZone(zoneName)
            if land.getSurfaceType({x = point.x, y = point.y}) ~= 3 then
                finalX, finalY = point.x, point.y
            else
                finalX, finalY = zoneData.point.x, zoneData.point.z
                env.info(string.format("[UnitSpawner] Zone '%s' random point in water, using center.", zoneName))
            end
        else
            env.warn(string.format("[UnitSpawner] Zone '%s' not found, using fallback coordinates.", zoneName))
        end
    end

    -- Strategy 2: Fallback to coordinates from placement config
    if not finalX or not finalY then
        finalX, finalY = SpatialSolver.findSafeGroundCoordinates(
            SpatialSolver.getBullseye("blue"), radarSector.placement, radarSector.groupName)
    end

    -- Build and spawn radar
    local radarPayload = AssetFactories.buildRadar(radarSector, finalX, finalY)
    mist.dynAdd(radarPayload)

    -- Activate radar (Red/ALARM_STATE)
    TriggerRegistry.scheduleAction(1.0, function(args)
        local g = Group.getByName(args.name)
        if g and g:getController() then
            g:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
        end
    end, { name = radarSector.groupName })

    -- Spawn air defense ring if configured
    if radarSector.pointDefense and type(radarSector.pointDefense.units) == "table" and #radarSector.pointDefense.units > 0 then
        local adPayload = AssetFactories.buildPointDefense(radarSector, finalX, finalY)
        mist.dynAdd(adPayload)
        AssetFactories.activatePointDefense(adPayload)
    end

    -- Spawn drone if configured
    if radarSector.drone then
        radarSector:spawnDynamicDrone(finalX, finalY)
    end

    return true
end

-- ============================================================================
-- SECTION 8: CONFIGURATION CLASSES
-- ============================================================================

UnitPlacementConfig = {}

--- Create a new UnitPlacementConfig from raw configuration.
-- Input values are in feet/NM/knots, converted to meters/m/s here.
-- @param placementConfig table Raw placement configuration (feet, NM, knots)
-- @return table UnitPlacementConfig instance
function UnitPlacementConfig.new(placementConfig)
    local self = setmetatable({}, UnitPlacementConfig)

    self.heading = placementConfig.heading or 0 -- degrees
    self.offsetX = mist.utils.NMToMeters(placementConfig.offsetX or 0) -- NM to meters
    self.offsetY = mist.utils.NMToMeters(placementConfig.offsetY or 0) -- NM to meters
    self.spawnRadius = mist.utils.NMToMeters(placementConfig.spawnRadius or 0) -- NM to meters

    -- Bearing/distance positioning fields (keep in original NM units, convert in SpatialSolver)
    self.offsetHeading = placementConfig.offsetHeading
    self.offsetDistance = placementConfig.offsetDistance

    -- Altitude (feet) and speed (knots) for air unit spawning - convert to metric
    self.altitude = placementConfig.altitude and mist.utils.feetToMeters(placementConfig.altitude)
    self.speed = placementConfig.speed and mist.utils.knotsToMps(placementConfig.speed)

    self.strategy = placementConfig.strategy or ""
    self.zoneName = placementConfig.zoneName

    self.groupName = placementConfig.groupName
    self.waypoint = placementConfig.waypoint

    self.startType = placementConfig.startType
    self.airbaseName = placementConfig.airbaseName
    return self
end

UnitRouteWaypoint = {}

--- Create a new UnitRouteWaypoint from raw configuration.
-- Input values are in feet/knots, converted to meters/m/s here.
-- @param routeConfig table Raw route waypoint configuration (feet, knots)
-- @return table UnitRouteWaypoint instance
function UnitRouteWaypoint.new(routeConfig)
    local self = setmetatable({}, UnitRouteWaypoint)
    self.type = routeConfig.type
    self.speed = mist.utils.knotsToMps(routeConfig.speed or 200) -- knots to m/s
    self.alt = mist.utils.feetToMeters(routeConfig.alt or 3000) -- feet to meters
    self.offsetX = mist.utils.NMToMeters(routeConfig.offsetX or 0) -- NM to meters
    self.offsetY = mist.utils.NMToMeters(routeConfig.offsetY or 0) -- NM to meters
    self.roe = routeConfig.roe or ""
    self.airbaseName = routeConfig.airbaseName
    return self
end

-- ============================================================================
-- SECTION 9: SECTOR CLASS
-- ============================================================================

Sector = {}
Sector.__index = Sector
local GlobalUnitGroupRegistry = {}

--- Create a new Sector instance.
-- @param sectorConfig table Sector configuration (feet, NM, knots)
-- @return table Sector instance
function Sector:new(sectorConfig)
    local self = setmetatable({}, Sector)
    self.__index = self

    if isNilOrEmpty(sectorConfig) then return self end

    -- Validate configuration against standard template
    local valid, error = ConfigStandards.validateConfig(sectorConfig, ConfigStandards.SECTOR_TEMPLATE)
    if not valid then
        env.info(string.format("[Sector] Configuration validation error: %s", error))
    end

    self.enabled = sectorConfig.enabled

    -- Activation Rules Configuration
    self.category = sectorConfig.category or "GROUND"
    self.triggerType = sectorConfig.triggerType or "IMMEDIATE"
    self.zoneName = sectorConfig.zoneName

    -- Conditional Triggers parameters
    self.groupName = sectorConfig.groupName
    self.unitType = sectorConfig.unitType

    self.parentGroupName = sectorConfig.parentGroupName

    -- Spawning Layout Parameters
    self.country = sectorConfig.country or "Russia"
    self.units = sectorConfig.units

    if sectorConfig.placement then
        self.placement = UnitPlacementConfig.new(sectorConfig.placement)
    end

    if sectorConfig.route then
        self.route = {}
        for idx, wpConfig in ipairs(sectorConfig.route) do
            table.insert(self.route, UnitRouteWaypoint.new(wpConfig))
        end
    end

    self.task = sectorConfig.task

    self.drone = sectorConfig.drone -- Stores the nested drone sub-table

    -- State Lifecycles
    self.hasSpawned = false
    self.isCleared = false

    GlobalUnitGroupRegistry[self.groupName] = self
    return self
end

--- Add drone radio menu to F10 map.
function Sector:addDroneRadioMenu()
    if not self.drone then
        env.info("Not adding radio menu, no drone config found")
        return
    end

    local droneName = self.drone.groupName

    -- Ensure the F10 framework root parent commands exist
    if not MapMarkerRegistry.rootMenu then
        MapMarkerRegistry.rootMenu = missionCommands.addSubMenu("Recon Drone Feeds")
    end

    -- Prevent creating duplicate menus if this function is called multiple times
    if MapMarkerRegistry.activeRadios and MapMarkerRegistry.activeRadios[droneName] then
        missionCommands.removeItem(MapMarkerRegistry.activeRadios[droneName])
    end

    -- Add an action button specific to this sector drone instance
    local cmdPath = missionCommands.addCommand(string.format("Request Update: %s", droneName),
        MapMarkerRegistry.rootMenu, function()
            local liveDrone = Group.getByName(droneName)
            if liveDrone and liveDrone:getSize() > 0 and liveDrone:getUnit(1):getLife() > 1 then
                -- Player clicked the menu item! Notify them over radio text:
                trigger.action.outText(string.format("[Radio] %s acknowledging request. Scanning theater area...",
                    droneName), 5)

                -- Route asynchronously into your heartbeat engine loop to simulate an execution sweep delay
                TriggerRegistry.scheduleAction(2.0, function()
                    local liveDrone = Group.getByName(droneName)
                    if liveDrone and liveDrone:getSize() > 0 and liveDrone:getUnit(1):getLife() > 1 then
                        -- Fetch fresh coordinates of the target asset from the world matrix map
                        local targetGroup = Group.getByName(self.groupName)
                        if targetGroup and targetGroup:getUnit(1) then
                            local currentPos = targetGroup:getUnit(1):getPosition().p

                            -- Fire mark point recalculation & refresh
                            self:createGroundTargetMarkpoint(currentPos.x, currentPos.z)
                            trigger.action.outText(string.format(
                                "[Radio] %s: Data updated. Check F10 tactical marks map.", droneName), 7)
                        else
                            trigger.action.outText(string.format(
                                "[Radio] %s: Scanned target sector area. Target appears completely neutralized.",
                                droneName), 7)
                            MapMarkerRegistry.clearMark(self.groupName)
                        end
                    end
                end)
            else
                -- drone is dead, wait and notify offline
                TriggerRegistry.scheduleAction(2.0, function()
                    trigger.action.outText(string.format(
                        "[Radio] Communication failed. Recon drone '%s' is offline or shot down.", droneName), 10)

                    -- Pull the saved menu path from our registry and delete it from the F10 map
                    local activeMenuPath = MapMarkerRegistry.activeRadios[droneName]
                    if activeMenuPath then
                        missionCommands.removeItem(activeMenuPath)
                        MapMarkerRegistry.activeRadios[droneName] = nil -- clear tracking reference
                    end

                    -- clear map marker after 5 minutes of drone being shot down
                    TriggerRegistry.scheduleAction(300, function()
                        MapMarkerRegistry.clearMark(self.groupName)
                    end)

                end)
            end
        end)

    -- cache the returned menu path token
    MapMarkerRegistry.activeRadios[droneName] = cmdPath
end

--- Assign drone to target zone for searching.
-- @param droneGroupName string Name of the drone group
-- @param targetGroupName string Name of the target group
function Sector:assignDroneToTarget(droneGroupName, targetGroupName)
    local droneGroup = Group.getByName(droneGroupName)

    if droneGroup then
        local droneController = droneGroup:getController()

        -- Pull final coordinates bound during spawn tracking
        local searchX = self.drone.targetX or self.placement.offsetX
        local searchY = self.drone.targetY or self.placement.offsetY

        -- Structured format for EngageTargetsInZone with correct data parameters
        local engageZoneTask = {
            id = 'EngageTargetsInZone',
            params = {
                point = {searchX, searchY},
                zoneRadius = self.placement.spawnRadius or 5000,
                targetTypes = {"Vehicles", "Air Defense"},
                priority = 1
            }
        }

        droneController:pushTask(engageZoneTask)
    else
        env.warn(string.format("[Director Warning] Drone %s missing for zone engagement routing.", droneGroupName))
    end
end

--- Create a tactical ground target markpoint on F10 map.
-- @param targetX number Target X coordinate
-- @param targetY number Target Y coordinate
function Sector:createGroundTargetMarkpoint(targetX, targetY)
    local groundGroup = Group.getByName(self.groupName)
    if groundGroup and groundGroup:getUnit(1) and groundGroup:getUnit(1):isExist() then
        local pos = groundGroup:getUnit(1):getPosition().p
        local lat, lon, alt = coord.LOtoLL(pos)
        local mgrs = coord.LLtoMGRS(lat, lon)

        local targetType = groundGroup:getUnit(1):getTypeName() or "Unknown"

        local x = mgrs.Easting / 100
        local y = mgrs.Northing / 100
        x = x - (math.floor(x / 100) * 100)
        y = y - (math.floor(y / 100) * 100)
        local grid = string.format("%s%-1d%-1d %2d %2d", mgrs.MGRSDigraph, mgrs.Easting / 10000, mgrs.Northing / 10000,
            x, y)
        local report = string.format(
            "== RECON INTEL UPDATE ==\nTRACK KEY: %s\nINTEL TYPE: %s\nMGRS GRID: %s\nALTITUDE: %d ft\nLAST UPDATE: %s\n=============================",
            self.groupName, targetType, grid, math.floor(alt * 3.28084),
            string.format("%02d:%02d", math.floor(timer.getTime() / 3600), math.floor((timer.getTime() % 3600) / 60)))

        -- Hand off drawing and updating rules cleanly to the registry!
        MapMarkerRegistry.drawTacticalMark(self.groupName, report, pos)
    else
        -- If the group is entirely dead, clear out its old operational tracks from the map
        MapMarkerRegistry.clearMark(self.groupName)
    end
end

--- Check if the drone is dead.
-- @return boolean true if drone is dead
function Sector:checkDroneDead()
    local droneName = self.drone.groupName
    local liveDrone = Group.getByName(droneName)

    -- If the sector has spawned, but the drone attached to it is now missing/dead
    if self.hasSpawned and (not liveDrone or liveDrone:getSize() == 0) then
        env.info(string.format("Drone %s is dead", droneName))
        -- clear map marker after 5 minutes of drone being shot down
        TriggerRegistry.scheduleAction(300, function()
            MapMarkerRegistry.clearMark(self.groupName)
        end)

        trigger.action.outText(string.format("[Radio] Communication failed. Recon drone '%s' is offline or shot down.",
            droneName), 10)

        -- Clean up F10 item instantly
        if MapMarkerRegistry.activeRadios[droneName] then
            missionCommands.removeItem(MapMarkerRegistry.activeRadios[droneName])
            MapMarkerRegistry.activeRadios[droneName] = nil
        end
        return true
    end
    return false
end

--- Spawn the dynamic drone asset.
-- @param spawnX number Spawn X coordinate
-- @param spawnY number Spawn Y coordinate
function Sector:spawnDynamicDrone(spawnX, spawnY)
    if self.drone.enabled == false then
        return
    end

    TriggerRegistry.scheduleAction(2.0, function()
        mist.dynAdd(AssetFactories.buildDrone(self.drone, spawnX, spawnY))

        -- Wait 3 seconds for the airframe to register before assigning its search task
        TriggerRegistry.scheduleAction(3.0, function()
            if Group.getByName(self.drone.groupName) then
                -- Paint map tracking markpoint readouts onto the player's F10 layer
                self:createGroundTargetMarkpoint(spawnX, spawnY)
                self:assignDroneToTarget(self.drone.groupName, self.groupName)
                self:addDroneRadioMenu()
            end
        end)
    end)
end

--- Wraps UnitSpawner.spawnRadarStation for backwards compatibility.
-- @return boolean true if spawned successfully
function Sector:spawnRadarStation()
    return UnitSpawner.spawnRadarStation(self)
end

--- Legacy spawn function - kept for backwards compatibility.
-- @param config table Unit configuration
-- @return table|nil Spawning result
local function spawnUnitsFromConfig(config)
    local bullseye = SpatialSolver.getBullseye("blue")
    return UnitSpawner.spawnGroup(config, bullseye, config.groupName)
end

--- Spawn this sector's units.
function Sector:spawnUnits()
    if self.hasSpawned then
        return
    end

    local bullseye = SpatialSolver.getBullseye("blue")
    UnitSpawner.spawnGroup(self, bullseye, self.groupName)

    -- PROCESS THE DATA-DRIVEN DRONE OVERWATCH ASSETS
    if self.drone then
        self:spawnDynamicDrone(SpatialSolver.getCoordinates(bullseye, self.placement))
    end

    self.hasSpawned = true
end

--- Spawn triggered units for this sector.
function Sector:spawnTriggeredUnits()
    if self.triggeredUnits then
        local bullseye = SpatialSolver.getBullseye("blue")
        UnitSpawner.spawnGroup(self.triggeredUnits, bullseye, self.triggeredUnits.groupName)
    end
end

-- ============================================================================
-- SECTION 10: RADAR SECTOR CLASS
-- ============================================================================

RadarSector = {}
RadarSector.__index = RadarSector
setmetatable(RadarSector, { __index = Sector }) -- inherit from Sector

--- Create a new RadarSector instance.
-- @param config table Radar sector configuration (feet, NM, knots)
-- @return table RadarSector instance
function RadarSector:new(config)
    local s = Sector:new(config)
    setmetatable(s, self)

    -- Validate radar-specific configuration
    local valid, error = ConfigStandards.validateConfig(config, ConfigStandards.RADAR_SECTOR_TEMPLATE)
    if not valid then
        env.info(string.format("[RadarSector] Configuration validation error: %s", error))
    end

    s.radarFilterEnabled = config.radarFilterEnabled
    s.pointDefense = config.pointDefense
    s.maxDetectRange = config.maxDetectRange or 200000.0

    if config.triggeredUnits then
        s.triggeredUnits = Sector:new(config.triggeredUnits)
    end

    return s
end

-- ============================================================================
-- SECTION 11: MISSION DIRECTOR
-- ============================================================================

MissionDirector = {}
MissionDirector.__index = MissionDirector

-- Shared lookup tracking cache allowing instances to check if other instances finished
local GlobalDirectorRegistry = {}

--- Create a new MissionDirector instance.
-- @param coalitionConfig table Array of sector configurations (feet, NM, knots)
-- @return table MissionDirector instance
function MissionDirector.new(coalitionConfig)
    local self = setmetatable({}, MissionDirector)
    self.sectors = {}
    for _, sector in ipairs(coalitionConfig) do
        if sector.enabled == true then
            local s
            if sector.triggerType == "RADAR" then
               s = RadarSector:new(sector)
            else
                s = Sector:new(sector)
            end
            table.insert(self.sectors, s)
        end
    end
    return self
end

--- Initialize global assets like AWACS and Tankers.
-- @param globalConfig table Array of global asset configurations (feet, NM, knots)
function MissionDirector:initializeGlobalAssets(globalConfig)
    if not globalConfig then
        return
    end

    local bullseye = SpatialSolver.getBullseye("blue")

    for _, unit in ipairs(globalConfig) do
        if unit.enabled then
            mist.dynAdd(AssetFactories.buildAWACSorTanker(bullseye, unit))
        end
    end
end

--- Check if this sector's units are all dead.
-- @return boolean true if all units are dead
function Sector:_checkOwnUnitsDead()
    local g = Group.getByName(self.groupName)
    if not g or g:getSize() == 0 then
        return true
    end
    for i = 1, g:getSize() do
        local u = g:getUnit(i)
        if u and u:isActive() and u:getLife() > 1 then
            return false
        end
    end
    return true
end

--- Start the engine loop for all sectors.
-- Spawns immediate sectors immediately, registers others with TriggerRegistry.
function MissionDirector:startEngineLoop()
    for _, sector in ipairs(self.sectors) do
        -- IMMEDIATE SECTORS: Fire instantly without scheduling background checks
        if sector.triggerType == "IMMEDIATE" then
            sector:spawnUnits()
        elseif sector.triggerType == "RADAR" then
            sector:spawnRadarStation()
        end
        -- Hand off tracking responsibility directly to the master ticker registry
        TriggerRegistry.register(sector)
    end
end

-- ============================================================================
-- END OF MODULE
-- ============================================================================
