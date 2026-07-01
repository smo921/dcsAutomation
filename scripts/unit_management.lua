local function is_nil_or_empty(t)
    return not t or next(t) == nil
end

local function printGroup(groupName)
    local group = Group.getByName(groupName)

    if group then
        local units = group:getUnits()
        for i, unit in pairs(units) do
            env.info("Unit #" .. i)
            env.info("  Name: " .. Unit.getName(unit))
            env.info("  Type: " .. unit:getTypeName()) -- e.g., "F-16C" or "T-72"

            -- Pull raw descriptor table (mass, speed, category, etc.)
            local desc = unit:getDesc()
        end
    end
end

local function getWaypointFromFlight(flightName, waypoint)
    -- Returns a sub-table containing coordinate positions, speed, and altitude for each waypoint
    local flightPlan = mist.getGroupRoute(flightName)
    if flightPlan and flightPlan[waypoint] then
        return flightPlan[waypoint]
    end
end

local function printFlightPath(flightName)
    -- Returns a sub-table containing coordinate positions, speed, and altitude for each waypoint
    local flightPlan = mist.getGroupRoute(flightName)

    if flightPlan then
        -- Iterate through the waypoints
        for i, waypoint in ipairs(flightPlan) do
            -- Extract properties for each waypoint
            local wpIndex = i
            local latitude = waypoint.x
            local longitude = waypoint.y
            local altitude = waypoint.alt
            local wpType = waypoint.type

            -- Do something with the waypoint data (e.g., print to dcs.log)
            env.info("Waypoint " .. wpIndex .. " - X: " .. latitude .. " Y: " .. longitude)
        end
    end
end

local function printSurfaceType(surfaceType)
    for str, ind in pairs(land.SurfaceType) do
        if ind == surfaceType then
            env.info('point is type ' .. surfaceType .. ' String: ' .. str)
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

MapMarkerRegistry = {
    activeMarkers = {}, -- Keys: sector/group name, Value: { id = Int, lastPos = vec3, text = String }
    activeRadios = {} -- Key: groupName, Value: menuRef
}

-- Generate a unique marker ID or update an existing one safely
function MapMarkerRegistry.drawTacticalMark(trackingKey, textMessage, positionVector)
    -- 1. Clean up old marker if one already exists for this track
    MapMarkerRegistry.clearMark(trackingKey)

    -- 2. Generate a random ID that won't collide with other systems
    local newMarkerId = math.random(100000, 999999)

    -- 3. Draw to all players in the coalition
    trigger.action.markToAll(newMarkerId, textMessage, positionVector, true)

    -- 4. Store state internally
    MapMarkerRegistry.activeMarkers[trackingKey] = {
        id = newMarkerId,
        pos = positionVector,
        text = textMessage,
        updatedAt = timer.getTime()
    }

    env.info(string.format("[MarkerRegistry] Rendered tactical mark ID %d for track '%s'", newMarkerId, trackingKey))
    return newMarkerId
end

-- Safely remove a marker from the F10 map layout
function MapMarkerRegistry.clearMark(trackingKey)
    local markerData = MapMarkerRegistry.activeMarkers[trackingKey]
    if markerData then
        -- Native DCS World API hook to yank it from everyone's map screens
        trigger.action.removeMark(markerData.id)
        MapMarkerRegistry.activeMarkers[trackingKey] = nil
        -- env.info("[MarkerRegistry] Successfully purged marker for track: " .. trackingKey)
    end
end

SpatialSolver = {}
SpatialSolver.VALID_LAND_TYPES = {
    [1] = true, -- Land / Fields
    [4] = true, -- Runway / Pavement
    [5] = true  -- Grass / Shorelines
}
SpatialSolver.DEFAULT_CLEARANCE_RADIUS = 12 -- meters

function SpatialSolver.getBullseye(coalition)
    return mist.DBs.missionData["bullseye"][coalition]
end

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

function SpatialSolver.getCoordinates(origin, placementConfig)
    local x, y = origin.x, origin.y

    -- Check for bearing/distance positioning first (Mode 2)
    if placementConfig.offsetHeading and placementConfig.offsetDistance then
        return SpatialSolver.getVector(origin, placementConfig.offsetHeading, placementConfig.offsetDistance)
    -- Then check for direct coordinate positioning (Mode 1)
    elseif placementConfig.offsetX and placementConfig.offsetY then
        return x + placementConfig.offsetX, y + placementConfig.offsetY
    -- Then check for group waypoint positioning (Mode 3)
    elseif placementConfig.groupName and placementConfig.waypoint then
        env.info("[SpatialSolver] Placing unit near group: " .. placementConfig.groupName .. " waypoint: " ..
                     placementConfig.waypoint)
        local wp = getWaypointFromFlight(placementConfig.groupName, placementConfig.waypoint)
        return wp.x, wp.y
    else
        return x, y
    end
end

function SpatialSolver.getVector(origin, heading, distance)
    local x, y
    local headingDeg = heading or 180
    local distanceNm = distance or 60

    local headingRad = math.rad(headingDeg)
    local distanceMeters = mist.utils.NMToMeters(distanceNm)

    -- Vector Projection away from Bullseye center
    x = origin.x + (math.cos(headingRad) * distanceMeters)
    y = origin.y + (math.sin(headingRad) * distanceMeters)
    return x, y
end

function SpatialSolver.searchArea(x, y, radius)
    local safeFound = false
    local attempts = 0
    local finalX, finalY
    -- Keep trying to find a clear spot up to 20 times per unit
    while not safeFound and attempts < 20 do
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
        env.info(string.format(
            "[Director Warning] Could not find clear clearing for %s Unit %d after 20 attempts. Defaulting near center.",
            self.groupName, i))
    end

    return finalX, finalY
end

-- finds a safe place inside a trigger zone, or based on startingPosition.x,y and placementConfig
function SpatialSolver.findSafeGroundCoordinates(startingPosition, placementConfig)
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

    return SpatialSolver.searchArea(startX, startY, placementConfig.spawnRadius)
end

function SpatialSolver.countSceneryObstructions(x, y, radius)
    local obstructionCount = 0
    local sphere = {
        id = world.VolumeType.SPHERE,
        params = {
            point = {
                x = x,
                y = land.getHeight({
                    x = x,
                    y = y
                }),
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

    -- Layer 2: Scan for base structures (dense urban city blocks, industrial complexes, map forests)
    world.searchObjects(Object.Category.BASE, sphere, function(obj)
        obstructionCount = obstructionCount + 1
        return true
    end)

    return obstructionCount
end

-- findStaticObstructions searche cirular area for obstructions, returning false if none found
function SpatialSolver.findStaticObstructions(x, y, radius)
    local hasObstruction = false
    local sphere = {
        id = world.VolumeType.SPHERE,
        params = {
            point = {
                x = x,
                y = land.getHeight({
                    x = x,
                    y = y
                }),
                z = y
            },
            radius = radius
        }
    }
    world.searchObjects(Object.Category.SCENERY, sphere, function(obj)
        hasObstruction = true;
        return false
    end)
    return hasObstruction
end

RadarHandler = {}

function RadarHandler.KmToNm(km)
    return km / 1.852
end

-- Calculate the straight‑line distance (nm) between two DCS units.
-- Works even if one of the units has been destroyed – the function will
-- simply return nil in that case.
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

    distanceKM = math.sqrt(dx * dx + dy * dy + dz * dz) / 1000
    return RadarHandler.KmToNm(distanceKM)
end

-- Helper: Pretty‑print a single detection ------------------------------------
function RadarHandler.formatDetection(radar, target)
    local name = target.object:getName() or "Unknown"
    local dist = RadarHandler.getDistanceInNM(radar, target.object) or 0
    local range = string.format("%.1f nm", dist)
    return string.format("%s - %s", name, range)
end


RadarHandler.filterByAircraft = { "KC-135", "E-3A", "MQ-9 Reaper" }

function RadarHandler.isThreat(aircraft)
    -- Optional: filter by aircraft type
    local threat = false
    if aircraft and aircraft.object:isExist() then
        -- Pull the actual vehicle/aircraft type name (e.g., "F-16C_50" or "AH-64D_BLK_II")
        local typeName = aircraft.object:getTypeName() or "Unknown Type"
        for _, filterType in ipairs(RadarHandler.filterByAircraft) do
            if string.find(typeName, filterType, 1, true) then
                local message = "[RadarCheck] Skipping " .. typeName .. " not a threat."
                -- env.info(message)
                return false -- return not threat immediately
            else
                threat = true        
            end
        end
    end
    return threat
end

function RadarHandler.logThreat(radarUnit, det)
    if det.object and det.object:isExist() then
        -- Pull the actual vehicle/aircraft type name (e.g., "F-16C_50" or "AH-64D_BLK_II")
        local typeName = det.object:getTypeName() or "Unknown Type"
        
        -- Pull the specific unit designation name assigned in the Mission Editor
        local unitName = det.object:getName() or "Unknown Unit"
        
        -- Calculate distance for a highly descriptive telemetry printout
        local distance = RadarHandler.getDistanceInNM(radarUnit, det.object) or 0
        
        env.info(string.format("[CheckRadar] Found Target -> Type: %s | Unit Name: %s | Range: %.1f nm", typeName, unitName, distance))
    end
end

-- Main routine that queries the radar ---------------------------------------
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
        local message = "[RadarCheck] ERROR: Radar unit '" .. radarUnit:getName() ..
                            "' has no controller. Is it alive and active?"
        trigger.action.outText(message, 10)
        env.error(message)
        return false
    end

    local detections = controller:getDetectedTargets()
    local threatFound = false

    if detections and #detections > 0 then
        -- env.info("[RadarCheck] Radar '" .. groupName .. "' detected " .. #detections .. " target(s).")

        for _, det in ipairs(detections) do
            -- Flag to decide whether target is found
            threatFound = true

            if radarSector.radarFilterEnabled then
                threatFound = RadarHandler.isThreat(det)
            end

            -- Optional: ignore very far detections
            -- det.distance is a boolean not a number
            if threatFound and det.distance then
                local distance = RadarHandler.getDistanceInNM(radarUnit, det.object)
                if distance and distance > radarSector.maxDetectRange then
                    threatFound = false
                    local message = "[RadarCheck]  Skipping – beyond max range (" .. radarSector.maxDetectRange ..
                                        " nm)."
                    trigger.action.outText(message, 10)
                    env.info(message)
                end
            end

            if threatFound then
                -- RadarHandler.logThreat(radarUnit, det)
                return threatFound
            end
        end
        -- Your custom logic here – e.g. trigger a client message, change AI state, etc.
        -- For example: env.mission.setWaypoint(1, "DetectedEnemy")
    else
        -- local message = "[RadarCheck] Radar '" .. groupName .. "' found NO targets."
        -- trigger.action.outText(message, 10)
        -- env.info(message)
    end

    return threatFound
end

-- ==============================================================================
-- CENTRALIZED TRIGGER REGISTRY ENGINE
-- ==============================================================================
TriggerRegistry = {
    monitoredSectors = {},
    actionQueue = {},
    isActive = false,
    tickInterval = 15.0 -- Evaluation heartbeat frequency in seconds
}

-- Add a sector to the tracking pool
function TriggerRegistry.register(sectorInstance)
    table.insert(TriggerRegistry.monitoredSectors, sectorInstance)
    env.info(string.format("[TriggerRegistry] Registered sector '%s' for monitoring.", sectorInstance.groupName))
    TriggerRegistry._ensureHeartbeat()
end

function TriggerRegistry.scheduleAction(delaySeconds, callbackFunction, contextArgs)
    local actionPayload = {
        executeAt = timer.getTime() + delaySeconds,
        callback = callbackFunction,
        args = contextArgs or {}
    }
    table.insert(TriggerRegistry.actionQueue, actionPayload)
    TriggerRegistry._ensureHeartbeat()
end

function TriggerRegistry._ensureHeartbeat()
    if not TriggerRegistry.isActive then
        TriggerRegistry.isActive = true
        timer.scheduleFunction(TriggerRegistry._heartbeat, {}, timer.getTime() + TriggerRegistry.tickInterval)
    end
end

-- The private master loop handler
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
        -- env.info(string.format("[TriggerRegistry] evaluating: %s", sector.groupName))
        if TriggerRegistry.evaluate(sector) then
            -- sector:spawnUnits()
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

-- Process the sector.  Return true to signal that all processing is complete
function TriggerRegistry.evaluate(sector)
    if sector.droneConfig and sector.droneConfig.enabled then
        -- check if drone is dead and cleanup
        local isDead = sector:checkDroneDead()
        if isDead then sector.dronConfig.enabled = false end
    end

    -- env.info("Trigger Registry evaluate loop: " .. sector.groupName )
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
        -- env.info(string.format("[TriggerRegistry Warning] Unknown trigger type '%s' on group %s", sector.triggerType, sector.groupName))
    end

    return false
end

-- ==============================================================================
-- INDIVIDUAL ISOLATED EVALUATORS (Easy to expand later!)
-- ==============================================================================

function TriggerRegistry._checkZone(zoneName)
    if not zoneName or not trigger.misc.getZone(zoneName) then
        env.info("[TriggerRegistry] Zone not found.")
        return false
    end
    -- Wrap MIST utility checks safely
    local blueUnits = mist.makeUnitTable({'[blue]'})
    local playersInZone = mist.getUnitsInZones(blueUnits, {zoneName})
    return playersInZone ~= nil and #playersInZone > 0
end

function TriggerRegistry._checkRadarDetection(radarSector)
    local threatFound = RadarHandler.checkRadar(radarSector)
    if threatFound and shouldGroupSpawn(radarSector.triggeredUnits.groupName) then
        radarSector:spawnTriggeredUnits()
    end
end

function TriggerRegistry._checkGroupDestroyed(parentGroupName)
    if not parentGroupName then
        return true
    end
    local gp = Group.getByName(parentGroupName)

    -- If the group reference returns nil or contains no active airframes/hulls
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

UnitPlacementConfig = {}

function UnitPlacementConfig.new(placementConfig)
    local self = setmetatable({}, UnitPlacementConfig)

    self.heading = placementConfig.heading or 0 -- degrees
    self.offsetX = mist.utils.NMToMeters(placementConfig.offsetX or 0) -- nm
    self.offsetY = mist.utils.NMToMeters(placementConfig.offsetY or 0) -- nm
    self.spawnRadius = mist.utils.NMToMeters(placementConfig.spawnRadius or 0) -- nm

    -- Bearing/distance positioning fields (keep in original units)
    self.offsetHeading = placementConfig.offsetHeading
    self.offsetDistance = placementConfig.offsetDistance

    -- Altitude and speed for air unit spawning
    self.altitude = placementConfig.altitude
    self.speed = placementConfig.speed

    self.strategy = placementConfig.strategy or ""
    self.zoneName = placementConfig.zoneName

    self.groupName = placementConfig.groupName
    self.waypoint = placementConfig.waypoint

    self.startType = placementConfig.startType
    self.airbaseName = placementConfig.airbaseName
    return self
end

UnitRouteWaypoint = {}

function UnitRouteWaypoint.new(routeConfig)
    local self = setmetatable({}, UnitRouteWaypoint)
    self.type = routeConfig.type
    self.speed = mist.utils.knotsToMps(routeConfig.speed or 200)
    self.alt = mist.utils.feetToMeters(routeConfig.alt or 3000)
    self.offsetX = mist.utils.NMToMeters(routeConfig.offsetX or 0)
    self.offsetY = mist.utils.NMToMeters(routeConfig.offsetY or 0)
    self.roe = routeConfig.roe or ""
    self.airbaseName = routeConfig.airbaseName
    return self
end

Sector = {}
Sector.__index = Sector
local GlobalUnitGroupRegistry = {}

function Sector:new(sectorConfig)
    local self = setmetatable({}, Sector)
    self.__index = self

    if is_nil_or_empty(sectorConfig) then return self end

    self.enabled = sectorConfig.enabled
    -- if self.enable == nil then self.enabled = true end

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

    self.droneConfig = sectorConfig.drone -- Stores the nested drone sub-table

    -- State Lifecycles
    self.hasSpawned = false
    self.isCleared = false

    GlobalUnitGroupRegistry[self.groupName] = self
    return self
end

function Sector:addDroneRadioMenu()
    if not self.droneConfig then
        env.info("Not adding radio menu, no drone config found")
        return
    end

    local droneName = self.droneConfig.groupName

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

function Sector:assignDroneToTarget(droneGroupName, targetGroupName)
    local droneGroup = Group.getByName(droneGroupName)

    if droneGroup then
        local droneController = droneGroup:getController()

        -- Pull final coordinates bound during spawn tracking
        local searchX = self.droneConfig.targetX or self.offsetX
        local searchY = self.droneConfig.targetY or self.offsetY

        -- FIX: Structured format for EngageTargetsInZone with correct data parameters
        local engageZoneTask = {
            id = 'EngageTargetsInZone',
            params = {
                point = {searchX, searchY},
                zoneRadius = self.spawnRadius or 5000,
                targetTypes = {"Vehicles", "Air Defense"},
                priority = 1
            }
        }

        droneController:pushTask(engageZoneTask)
        env.info(string.format("[Director] EngageTargetsInZone pushed cleanly to Drone %s over absolute center.",
            droneGroupName))
    else
        env.info(string.format("[Director Warning] Drone %s missing for zone engagement routing.", droneGroupName))
    end
end

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

function Sector:checkDroneDead()
    local droneName = self.droneConfig.groupName
    local liveDrone = Group.getByName(droneName)

    -- If the sector has spawned, but the drone attached to it is now missing/dead
    if self.hasSpawned and (not liveDrone or liveDrone:getSize() == 0) then
        env.info("Drone " .. droneName .. " is dead")
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

function Sector:spawnDynamicDrone(spawnX, spawnY)
    if self.droneConfig.enabled == false then
        return
    end

    TriggerRegistry.scheduleAction(2.0, function()
        mist.dynAdd(AssetFactories.buildDrone(self.droneConfig, spawnX, spawnY))
        env.info("[Director] Dynamic Overwatch Drone spawned directly over target coordinates: " ..
                     self.droneConfig.groupName)

        -- Wait 3 seconds for the airframe to register before assigning its search task
        TriggerRegistry.scheduleAction(3.0, function()
            if Group.getByName(self.droneConfig.groupName) then
                -- Paint map tracking markpoint readouts onto the player's F10 layer
                self:createGroundTargetMarkpoint(spawnX, spawnY)
                self:assignDroneToTarget(self.droneConfig.groupName, self.groupName)
                self:addDroneRadioMenu()
            end
        end)
    end)
end

function Sector:spawnRadarStation()
    if self.hasSpawned then
        return
    end
    if not self.groupName or not self.unitType then
        return
    end
    local zoneName = self.placement.zoneName
    local finalX, finalY

    -- 1. Grab a random point inside the specified ME Trigger Zone
    if zoneName then
        local zoneData = trigger.misc.getZone(zoneName)

        if zoneData then
            local randomZonePoint = mist.getRandomPointInZone(zoneName)
            local surfaceType = land.getSurfaceType(randomZonePoint)

            if surfaceType ~= 3 then
                finalX = randomZonePoint.x
                finalY = randomZonePoint.y
                env.info("[Director] Radar " .. self.groupName .. " successfully randomized inside zone: " .. zoneName)
            else
                finalX = zoneData.point.x
                finalY = zoneData.point.z
                env.info(": x, y: " .. randomZonePoint.x .. "," .. randomZonePoint.z)
                env.info(
                    "[Director Warning] Random zone point landed in water. Centering radar safety fallback inside zone.")
            end
        else
            env.info("[Director Error] Named zone '" .. zoneName ..
                         "' completely missing from the Mission Editor! Defaulting to profile offsets.")
        end
    end

    -- 2. Explicit Fallback: If zone logic fails or isn't specified, use your profile offsets
    if not finalX or not finalY then
        finalX, finalY = SpatialSolver.findSafeGroundCoordinates(SpatialSolver.getBullseye("blue"), self.placement)
        env.info("[Director Fallback] Anchoring radar " .. self.groupName .. " to configured profile offsets.")
    end

    -- Construct and deploy the dynamic radar group
    local radarGroupPayload = AssetFactories.buildRadar(self, finalX, finalY)
    mist.dynAdd(radarGroupPayload)

    -- Force radar power state to Red (Active Scan)
    TriggerRegistry.scheduleAction(1.0, function(args)
        local g = Group.getByName(args.name)
        if g and g:getController() then
            g:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
        end
    end, {
        name = self.groupName
    })

    -- 3. Deploy Air Defense Ring Escorts if configured
    if self.pointDefense and type(self.pointDefense.units) == "table" and #self.pointDefense.units > 0 then
        local adPayload = AssetFactories.buildPointDefense(self, finalX, finalY)
        mist.dynAdd(adPayload)
        AssetFactories.activatePointDefense(adPayload)
    end

    -- Sector Drone Deployment Phase
    if self.droneConfig then
        self:spawnDynamicDrone(finalX, finalY)
    end
    self.hasSpawned = true
end




local function spawnUnitsFromConfig(config)
    if is_nil_or_empty(config) or is_nil_or_empty(config.units) then return end

    if config.category == "AIRPLANE" or config.category == "HELICOPTER" then
        local finalX, finalY
        local airbaseObj = nil

        if config.placement.airbaseName then
            airbaseObj = Airbase.getByName(config.placement.airbaseName)
            if airbaseObj then
                env.info("Airbase position being calculated")
                local basePos = airbaseObj:getPosition().p
                finalX, finalY = basePos.x, basePos.z
            else
                env.info("Airbase object not found for: " .. config.airbaseName)
            end
        end

        -- Air start fallback if no airbase is bound
        if not finalX or not finalY then
            local bullseye = SpatialSolver.getBullseye("blue")
            if bullseye then
                finalX, finalY = bullseye.x, bullseye.y
            else
                finalX, finalY = 0, 0
            end
        end

        local units = AssetFactories.buildAirGroup(config, finalX, finalY, airbaseObj)
        if units then
            mist.dynAdd(units)
            env.info("[Director] Successfully deployed air group array for sector: " .. config.groupName)
        end
    else
        -- Fallback to original Ground Platoon construction engine
        local finalX, finalY
        local bullseye = SpatialSolver.getBullseye("blue")

        finalX, finalY = SpatialSolver.findSafeGroundCoordinates(bullseye, config.placement)
        local units = AssetFactories.buildPlatoon(config, finalX, finalY)

        mist.dynAdd(units)
        env.info("[Director] Successfully deployed ground group array for sector: " .. config.groupName)
    end
end




function Sector:spawnUnits()
    if self.hasSpawned then
        return
    end

    spawnUnitsFromConfig(self)
    -- ========================================================================
    -- STEP 2: PROCESS THE DATA-DRIVEN DRONE OVERWATCH ASSETS
    -- ========================================================================
    if self.droneConfig then
        self:spawnDynamicDrone(SpatialSolver.getCoordinates(bullseye, self.placement))
    end

    self.hasSpawned = true
end

function Sector:spawnTriggeredUnits()
    spawnUnitsFromConfig(self.triggeredUnits)
end

RadarSector = {}
RadarSector.__index = RadarSector
setmetatable(RadarSector, { __index = Sector }) -- inherit from Sector

function RadarSector:new(config)
    local s = Sector:new(config)
    setmetatable(s, self)

    s.radarFilterEnabled = config.radarFilterEnabled
    s.pointDefense = config.pointDefense
    s.maxDetectRange = config.maxDetectRange or 200000.0

    if config.triggeredUnits then
        s.triggeredUnits = Sector:new(config.triggeredUnits)
    end

    return s
end
-- ==============================================================================
-- 2. AUTOMATION CORE ENGINE LOGIC
-- ==============================================================================
MissionDirector = {}
MissionDirector.__index = MissionDirector

-- Shared lookup tracking cache allowing instances to check if other instances finished
local GlobalDirectorRegistry = {}

function MissionDirector.new(coalitionConfig)
    local self = setmetatable({}, MissionDirector)
    self.sectors = {}
    for _, sector in ipairs(coalitionConfig) do
        env.info("[Director] Sector " .. sector.groupName .. " enabled: " .. tostring(sector.enabled))

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

function MissionDirector:initializeGlobalAssets(globalConfig)
    if not globalConfig then
        return
    end

    local bullseye = SpatialSolver.getBullseye("blue")

    for _, unit in ipairs(globalConfig) do
        if unit.enabled then
            mist.dynAdd(AssetFactories.buildAWACSorTanker(bullseye, unit))
            env.info("[Director] Global " .. unit.groupName .. " established relative to Theater Bullseye coordinates.")        
        end
    end
end

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

function MissionDirector:startEngineLoop()
    for _, sector in ipairs(self.sectors) do
        -- IMMEDIATE SECTORS: Fire instantly without scheduling background checks
        if sector.triggerType == "IMMEDIATE" then
            env.info("[Director] Booting Immediate Sector: " .. sector.groupName)
            sector:spawnUnits()
        elseif sector.triggerType == "RADAR" then
            sector:spawnRadarStation()
        end
        -- Hand off tracking responsibility directly to the master ticker registry
        TriggerRegistry.register(sector)
    end
end
