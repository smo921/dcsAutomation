local function nm2Meters(distanceNm) 
    return distanceNm * 1.852 * 1000
end

local function getWaypointFromFlight(flightName, waypoint)
    -- Returns a sub-table containing coordinate positions, speed, and altitude for each waypoint
    local flightPlan = mist.getGroupRoute(flightName)
    if flightPlan and flightPlan[waypoint] then return flightPlan[waypoint] end
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

function SpatialSolver.getBullseye(coalition)
    return mist.DBs.missionData["bullseye"][coalition]
end

function SpatialSolver.terrainIsClear(x, y, radius)
    -- Check surface type (not water)
    if land.getSurfaceType({x, y}) == 3 then
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

function SpatialSolver.getCoordinates(bullseye, placementConfig)
    if placementConfig.offsetX and placementConfig.offsetY then
        return bullseye.x + placementConfig.offsetX, bullseye.y + placementConfig.offsetY
    elseif placementConfig.groupName and placementConfig.waypoint then
        env.info("Placing unit near group: " .. placementConfig.groupName .. "waypoint: " .. placementConfig.waypoint)
        local wp = getWaypointFromFlight(placementConfig.groupName, placementConfig.waypoint)
        return wp.x, wp.y
    else
        return bullseye.x, bullseye.y
    end
end


function SpatialSolver.searchArea(x, y, radius)
    local safeFound = false
    local attempts = 0
    local finalX, finalY
    -- Keep trying to find a clear spot up to 20 times per unit
    while not safeFound and attempts < 20 do
        attempts = attempts + 1
        
        local randomAngle = math.random() * 2 * math.pi
        local randomDist  = math.random() * (radius or 25)
        
        local checkX = x + (math.cos(randomAngle) * randomDist)
        local checkY = y + (math.sin(randomAngle) * randomDist)
        
        if SpatialSolver.terrainIsClear(checkX, checkX, 50) == true then
            finalX = checkX
            finalY = checkY
            safeFound = true            
        end
    end
    
    -- Fallback: If 20 attempts all hit dense forest, fall back to random offset
    if not safeFound then
        finalX = x + (math.random(-50, 50))
        finalY = y + (math.random(-50, 50))
        env.info(string.format("[Director Warning] Could not find clear clearing for %s Unit %d after 20 attempts. Defaulting near center.", self.groupName, i))
    end

    return finalX, finalY
end

-- finds a safe place inside a trigger zone, or based on startingPosition.x,y and placementConfig
function SpatialSolver.findSafeGroundCoordinates(startingPosition, placementConfig)
    local startX, startY
    local finalX, finalY

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
            point = {x = x, y = land.getHeight({x=x, y=y}), z = y}, 
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
        params = { point = {x = x, y = land.getHeight({x=x, y=y}), z = y}, radius = radius }
    }
    world.searchObjects(Object.Category.SCENERY, sphere, function(obj) hasObstruction = true; return false end)
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
    if not (unitA and unitB) then return nil end

    local posA = unitA:getPosition().p
    local posB = unitB:getPosition().p

    if not (posA and posB) then return nil end

    local dx = posA.x - posB.x
    local dy = posA.y - posB.y
    local dz = posA.z - posB.z

    distanceKM = math.sqrt(dx * dx + dy * dy + dz * dz) / 1000
    return RadarHandler.KmToNm(distanceKM)
end

-- Helper: Pretty‑print a single detection ------------------------------------
function RadarHandler.formatDetection(radar, target)
    local name   = target.object:getName() or "Unknown"
    local dist   = RadarHandler.getDistanceInNM(radar, target.object) or 0
    local range  = string.format("%.1f nm", dist)
    return string.format("%s - %s", name, range)
end

-- Main routine that queries the radar ---------------------------------------
function RadarHandler.checkRadar(radarSector)
    local groupName = radarSector.groupName
    local radarGroup = Group.getByName(radarSector.groupName)
    if not radarGroup then return false end

    local radarUnit = radarGroup:getUnit(1)
    if not radarUnit then return false end

    local controller = radarUnit:getController()
    if not controller then
        local message = "[RadarCheck] ERROR: Radar unit '" .. radarUnit:getName() .. "' has no controller. Is it alive and active?"
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

            -- Optional: ignore very far detections
            -- det.distance is a boolean not a number
            if det.distance then
                local distance = RadarHandler.getDistanceInNM(radarUnit, det.object)
                if distance and distance > radarSector.maxDetectRange then
                    threatFound = false
                    local message = "[RadarCheck]  Skipping – beyond max range (" .. radarSector.maxDetectRange .. " nm)."
                    trigger.action.outText(message, 10)
                    -- env.info(message)
                end
            end

            -- Optional: filter by aircraft type
            --if filterByAircraft and threatFound then
            --   local aircraft = det.aircraftName or det.objectName or det.unitName or ""
            --    if not string.find(aircraft, filterByAircraft, 1, true) then
            --        threatFound = false
            --        local message = "[RadarCheck]  Skipping – not a " .. filterByAircraft .. "."
            --        trigger.action.outText(message, 10)
            --        env.info(message)
            --    end
            --end

            -- log all threats identified
            --if threatFound then
            --    local message = "[RadarCheck] Detected: " .. RadarHandler.formatDetection(radarUnit, det)
            --    trigger.action.outText(message, 10)
            --    env.info(message)
            --end
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
    tickInterval = 3.0 -- Evaluation heartbeat frequency in seconds
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
        callback  = callbackFunction,
        args      = contextArgs or {}
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
        
        if TriggerRegistry.evaluate(sector) then
            sector:executeSectorSpawn()
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
    if sector.droneConfig then
        -- return true if drone is dead to signal TriggerRegistry to stop monitoring sector
        return sector:checkDroneDead()
    end

    -- If the sector has somehow already spawned out of band, flag it for immediate cleanup
    if sector.hasSpawned then return true end

    -- env.info("Trigger Registry evaluate loop: " .. sector.groupName )
    if sector.triggerType == "TRIGGER_ZONE" then
        return TriggerRegistry._checkZone(sector.zoneName)
        
    elseif sector.triggerType == "RADAR" then
        return TriggerRegistry._checkRadarDetection(sector)
        
    elseif sector.triggerType == "OBJECTIVE_COMPLETE" then
        return TriggerRegistry._checkGroupDestroyed(sector.parentGroupName) 
    end

    -- Unrecognized or faulty trigger logic drops safe fallback logging
    env.info(string.format("[TriggerRegistry Warning] Unknown trigger type '%s' on group %s", sector.triggerType, sector.groupName))
    return false
end

-- ==============================================================================
-- INDIVIDUAL ISOLATED EVALUATORS (Easy to expand later!)
-- ==============================================================================

function TriggerRegistry._checkZone(zoneName)
    if not zoneName or not trigger.misc.getZone(zoneName) then return false end
    -- Wrap MIST utility checks safely
    local playersInZone = mist.getPlayersInZone(zoneName)
    return playersInZone ~= nil and #playersInZone > 0
end

function TriggerRegistry._checkRadarDetection(radarSector)
    -- env.info("Check radar for unit " .. radarSector.groupName)
    local threatFound = RadarHandler.checkRadar(radarSector)
end

function TriggerRegistry._checkGroupDestroyed(parentGroupName)
    if not parentGroupName then return true end
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


-- ==============================================================================
-- 2. AUTOMATION CORE ENGINE LOGIC
-- ==============================================================================
MissionDirector = {}
MissionDirector.__index = MissionDirector

MissionDirector.ROE = { WEAPON_HOLD = 0, RETURN_FIRE = 1, OPEN_FIRE = 2, WEAPON_FREE = 3 }
MissionDirector.THREAT_REACTION = { PASSIVE_DEFENSE = 0, NO_REACTION = 1, EVADE_FIRE = 2, BYPASS_PASSIVE = 3 }
local OPTION_IDS = { ROE = 0, THREAT_REACTION = 1 }

-- Shared lookup tracking cache allowing instances to check if other instances finished
local GlobalDirectorRegistry = {}

function MissionDirector.new(configProfile)
    local self = setmetatable({}, MissionDirector)
    
    -- Activation Rules Configuration
    self.triggerType     = configProfile.triggerType or "IMMEDIATE"
    self.checkInterval   = configProfile.checkInterval or 5.0

    -- Conditional Triggers parameters
    self.groupName  = configProfile.groupName
    self.unitType   = configProfile.unitType
    self.pointDefense    = configProfile.pointDefense
    self.maxDetectRange  = configProfile.maxDetectRange or 200000.0
        
    self.parentGroupName = configProfile.parentGroupName
    
    -- Spawning Layout Parameters
    self.country         = configProfile.country or "Russia"
    self.units     = configProfile.units

    self.placement = configProfile.placement

    self.routeConfig     = configProfile.route
    
    self.awacsConfig     = configProfile.awacs   -- Stores the nested awacs sub-table
    self.droneConfig     = configProfile.drone   -- Stores the nested drone sub-table

    -- State Lifecycles
    self.hasSpawned      = false
    self.isCleared       = false
    
    GlobalDirectorRegistry[self.groupName] = self
    return self
end

function MissionDirector:initializeGlobalAssets(globalConfig)
    if not globalConfig or not globalConfig.awacs then return end
    
    local awacsData = globalConfig.awacs
    
    -- Fetch the exact coalition Bullseye coordinates from the DCS environment
    local bullseyePos = SpatialSolver.getBullseye("blue")
    
    if bullseyePos then
        local headingDeg = awacsData.offsetHeading or 180
        local distanceNm = awacsData.offsetDistance or 60
        
        local headingRad = math.rad(headingDeg)
        local distanceMeters = nm2Meters(distanceNm)
        
        -- Vector Projection away from Bullseye center
        local safeX = bullseyePos.x + (math.cos(headingRad) * distanceMeters)
        local safeY = bullseyePos.y + (math.sin(headingRad) * distanceMeters)
        
        -- Fire execution
        mist.dynAdd(AssetFactories.buildAWACS(awacsData, safeX, safeY))
        env.info("[Director] Global AWACS established relative to Theater Bullseye coordinates.")
    else
        env.info("[Director Error] Failed to retrieve Blue coalition Bullseye from the environment map!")
    end
end

function MissionDirector:executeSectorSpawn()
    if self.hasSpawned then return end

    -- ========================================================================
    -- SPATIAL CORRECTION MATRIX: Translate Relative Offsets to Absolute Map Space
    -- ========================================================================
    -- local blueBullseye = SpatialSolver.getBullseye("blue")
    
    -- ========================================================================
    -- STEP 1: CONSTRUCT AND DEPLOY GROUND ELEMENTS VIA MIST
    -- ========================================================================
    local finalX, finalY
    local unitsPayload = {}
    local bullseye = SpatialSolver.getBullseye("blue")
    -- 1A. If this is a RADAR sector, insert the master emitting radar unit first
    if self.triggerType == "RADAR" and self.radarUnitType then
        finalX, finalY = SpatialSolver.findSafeGroundCoordinates(bullseye, self.placement)
        table.insert(unitsPayload, {
            ["type"]    = self.unitType,
            ["name"]    = self.groupName .. "_Master_Unit",
            ["x"]       = finalX,
            ["y"]       = finalY,
            ["heading"] = math.rad(self.placement.heading or 0),
            ["skill"]   = "Excellent"
        })
    end


    
    -- 1B. Dynamic Radial Scatter for Ground Columns (Forest-Proofed)
    if self.units then
        finalX, finalY = SpatialSolver.findSafeGroundCoordinates(bullseye, self.placement)
        table.insert(unitsPayload, AssetFactories.buildPlatoon(self, finalX, finalY))


        for i, unitType in ipairs(self.units) do
            table.insert(unitsPayload, {
                ["type"]    = unitType,
                ["name"]    = self.groupName .. "_Unit_" .. i,
                ["x"]       = finalX,
                ["y"]       = finalY,
                ["heading"] = math.rad(self.placement.heading or 0),
                ["skill"]   = "High"
            })
        end

    end
    
    -- 1C. Assemble the structural master group wrapper for the MIST database
    local groundGroupPayload = {
        ["visible"]  = true,
        ["category"] = "GROUND",
        ["country"]  = self.country or "Russia",
        ["name"]     = self.groupName,
        ["units"]    = unitsPayload,
        ["route"]    = { ["points"] = {} }
    }

    -- 1D. Inject waypoint nodes relative to the new absolute center point
    if self.routeConfig then
        for _, wp in ipairs(self.routeConfig) do
            table.insert(groundGroupPayload.route.points, {
                ["x"]      = finalX + wp.offsetX,
                ["y"]      = finalY + wp.offsetY,
                ["action"] = "Turning Point",
                ["type"]   = wp.type or "Off Road",
                ["speed"]  = (wp.speed or 30) / 3.6, -- Convert km/h to m/s
                ["task"]   = { ["id"] = "ComboTask", ["params"] = { ["tasks"] = {} } }
            })
        end
    end

    -- Inject ground elements directly into the DCS engine environment
    mist.dynAdd(groundGroupPayload)
    env.info("[Director] Successfully deployed ground group array for sector: " .. self.groupName)

    -- ========================================================================
    -- STEP 2: PROCESS THE DATA-DRIVEN DRONE OVERWATCH ASSETS
    -- ========================================================================
    if self.droneConfig then
        self:spawnDynamicDrone(SpatialSolver.getCoordinates(SpatialSolver.getBullseye("blue"), self.placement))
    end

    self.hasSpawned = true
end

function MissionDirector:addDroneRadioMenu()
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
    local cmdPath = missionCommands.addCommand(
        string.format("Request Update: %s", droneName),
        MapMarkerRegistry.rootMenu,
        function()
            local liveDrone = Group.getByName(droneName)
            if liveDrone and liveDrone:getSize() > 0 and liveDrone:getUnit(1):getLife() > 1 then
                -- Player clicked the menu item! Notify them over radio text:
                trigger.action.outText(string.format("[Radio] %s acknowledging request. Scanning theater area...", droneName), 5)
            
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
                            trigger.action.outText(string.format("[Radio] %s: Data updated. Check F10 tactical marks map.", droneName), 7)
                        else
                            trigger.action.outText(string.format("[Radio] %s: Scanned target sector area. Target appears completely neutralized.", droneName), 7)
                            MapMarkerRegistry.clearMark(self.groupName)
                        end
                    end
                end)
            else
                -- drone is dead, wait and notify offline
                TriggerRegistry.scheduleAction(2.0, function()
                    trigger.action.outText(string.format("[Radio] Communication failed. Recon drone '%s' is offline or shot down.", droneName), 10)
                    
                    
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
        end
    )

    -- cache the returned menu path token
    MapMarkerRegistry.activeRadios[droneName] = cmdPath
end


function MissionDirector:createGroundTargetMarkpoint(targetX, targetY)
    local groundGroup = Group.getByName(self.groupName)
    if groundGroup and groundGroup:getUnit(1) and groundGroup:getUnit(1):isExist() then
        local pos = groundGroup:getUnit(1):getPosition().p
        local lat, lon, alt = coord.LOtoLL(pos)
        local mgrs = coord.LLtoMGRS(lat, lon)
        
        local targetType = self.radarUnitType or "Mechanized Armor Platoon"
        
        local x = mgrs.Easting / 100
        local y = mgrs.Northing / 100
        x = x - (math.floor(x / 100) * 100)
        y = y - (math.floor(y / 100) * 100)
        local grid = string.format("%s%-1d%-1d %2d %2d", mgrs.MGRSDigraph, mgrs.Easting/10000, mgrs.Northing/10000, x, y)
        local report = string.format(
            "== RECON INTEL UPDATE ==\nTRACK KEY: %s\nINTEL TYPE: %s\nMGRS GRID: %s\nALTITUDE: %d ft\nLAST UPDATE: %s\n=============================",
            self.groupName, targetType, grid, math.floor(alt * 3.28084),
            string.format("%02d:%02d", math.floor(timer.getTime() / 3600), math.floor((timer.getTime() % 3600) / 60))
        )
        
        -- Hand off drawing and updating rules cleanly to the registry!
        MapMarkerRegistry.drawTacticalMark(self.groupName, report, pos)
    else
        -- If the group is entirely dead, clear out its old operational tracks from the map
        MapMarkerRegistry.clearMark(self.groupName)
    end
end


function MissionDirector:checkOwnUnitsDead()
    local g = Group.getByName(self.groupName)
    if not g or g:getSize() == 0 then return true end
    for i = 1, g:getSize() do
        local u = g:getUnit(i)
        if u and u:isActive() and u:getLife() > 1 then return false end
    end
    return true
end

function MissionDirector:assignDroneToTarget(droneGroupName, targetGroupName)
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
                point = { searchX, searchY }, 
                zoneRadius = self.spawnRadius or 5000, 
                targetTypes = { "Vehicles", "Air Defense" }, 
                priority = 1
            }
        }
        
        droneController:pushTask(engageZoneTask)
        env.info(string.format("[Director] EngageTargetsInZone pushed cleanly to Drone %s over absolute center.", droneGroupName))
    else
        env.info(string.format("[Director Warning] Drone %s missing for zone engagement routing.", droneGroupName))
    end
end


function MissionDirector:checkDroneDead()
    local droneName = self.droneConfig.groupName
    local liveDrone = Group.getByName(droneName)
    
    -- If the sector has spawned, but the drone attached to it is now missing/dead
    if self.hasSpawned and (not liveDrone or liveDrone:getSize() == 0) then
        env.info("Drone " .. droneName .. " is dead")
        -- clear map marker after 5 minutes of drone being shot down
        TriggerRegistry.scheduleAction(300, function()
            MapMarkerRegistry.clearMark(self.groupName)    
        end)

        trigger.action.outText(string.format("[Radio] Communication failed. Recon drone '%s' is offline or shot down.", droneName), 10)

        -- Clean up F10 item instantly
        if MapMarkerRegistry.activeRadios[droneName] then
            missionCommands.removeItem(MapMarkerRegistry.activeRadios[droneName])
            MapMarkerRegistry.activeRadios[droneName] = nil
        end
        return true
    end
    return false
end

function MissionDirector:deployRadarStation()
    if self.hasSpawned then return end
    if not self.groupName or not self.unitType then return end
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
                env.info("[Director Warning] Random zone point landed in water. Centering radar safety fallback inside zone.")
            end
        else
            env.info("[Director Error] Named zone '" .. self.radarZoneName .. "' completely missing from the Mission Editor! Defaulting to profile offsets.")
        end
    end    
    
    -- 2. Explicit Fallback: If zone logic fails or isn't specified, use your profile offsets
    if not finalX or not finalY then
        finalX, finalY = SpatialSolver.findSafeGroundCoordinates(SpatialSolver.getBullseye("blue"), self.placement)
        env.info("[Director Fallback] Anchoring radar " .. self.radarGroupName .. " to configured profile offsets.")
    end

    -- Construct and deploy the dynamic radar group
    local radarGroupPayload = {
        ["visible"] = true,
        ["task"] = "EWR",
        ["category"] = "GROUND",
        ["country"] = self.country,
        ["name"] = self.groupName,
        ["route"] = { ["points"] = { { ["x"] = finalX, ["y"] = finalY, ["type"] = "Turning Point", ["action"] = "From Ground Area", ["speed"] = 0 } } },
        ["units"] = {
            {
                ["type"] = self.unitType,
                ["name"] = self.groupName .. "_Sensor_Unit",
                ["x"] = finalX, ["y"] = finalY,
                ["heading"] = (self.placement.heading or 0) * (math.pi / 180)
            }
        }
    }
    
    mist.dynAdd(radarGroupPayload)
    
    -- Force radar power state to Red (Active Scan)
    TriggerRegistry.scheduleAction(1.0, function(args)
        local g = Group.getByName(args.name)
        if g and g:getController() then
            g:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
        end
    end, {name = self.groupName})

    -- 3. Deploy Air Defense Ring Escorts if configured
    if self.pointDefense and type(self.pointDefense.units) == "table" and #self.pointDefense.units > 0 then
        local adPayload = AssetFactories.buildPointDefense(self, finalX, finalY)
        mist.dynAdd(adPayload)        
        activatePointDefense(adPayload)
    end

    -- Sector Drone Deployment Phase
    if self.droneConfig then
        self:spawnDynamicDrone(finalX, finalY)
    end
    self.hasSpawned = true
end

function MissionDirector:spawnDynamicDrone(spawnX, spawnY)
    TriggerRegistry.scheduleAction(2.0, function()
        mist.dynAdd(AssetFactories.buildDrone(self.droneConfig, spawnX, spawnY))
        env.info("[Director] Dynamic Overwatch Drone spawned directly over target coordinates: " .. self.droneConfig.groupName)

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

function MissionDirector:isPlayerInZone(zoneName)
    return trigger.misc.getZone(zoneName) and #mist.getPlayersInZone(zoneName) > 0
end

function MissionDirector:isPlayerDetectedByRadar()
    return false 
end

function MissionDirector:isParentGroupDestroyed()
    local gp = Group.getByName(self.parentGroupName)
    local parentDirector = GlobalDirectorRegistry[self.parentGroupName]
    
    if parentDirector and not parentDirector.hasSpawned then
        return false
    end
    
    if gp == nil or gp:isExist() == false or gp:getSize() == 0 then
        return true
    end
    
    return false
end

function MissionDirector:checkTriggerCondition()
    if self.hasSpawned then return end

    local shouldSpawn = false
    
    if self.triggerType == "TRIGGER_ZONE" and self.zoneName then
        if self:isPlayerInZone(self.zoneName) then
            shouldSpawn = true
        end
    elseif self.triggerType == "RADAR" then
        if self:isPlayerDetectedByRadar() then
            shouldSpawn = true
        end
    elseif self.triggerType == "OBJECTIVE_COMPLETE" and self.parentGroupName then
        if self:isParentGroupDestroyed() then
            shouldSpawn = true
        end
    end

    if shouldSpawn then
        self.hasSpawned = true
        env.info("[Director] Trigger conditions met for: " .. self.groupName .. ". Initializing deployment sequence.")
        
        local spawnX, spawnY = nil, nil
        if self.triggerType == "RADAR" then
            -- Note: If you add calculateRandomRadarCoordinates back in, reference it here.
            -- For now, falling back to standard offsets calculation inside executeSectorSpawn.
        end
        
        self:executeSectorSpawn()
    else
        TriggerRegistry.scheduleAction(self.checkInterval or 5.0, function() 
            self:checkTriggerCondition() 
        end)
    end
end

function MissionDirector:startEngineLoop()
    -- IMMEDIATE SECTORS: Fire instantly without scheduling background checks
    if self.triggerType == "IMMEDIATE" then
        env.info("[Director] Booting Immediate Sector: " .. self.groupName)
        self:executeSectorSpawn()
    elseif self.triggerType == "RADAR" then
        self:deployRadarStation()
    end
    -- Hand off tracking responsibility directly to the master ticker registry
    TriggerRegistry.register(self)
end