local function countSceneryObstructions(x, y, radius)
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
    self.spawnRadius     = configProfile.spawnRadius -- NEW: Capture the radius property mapping

    -- Conditional Triggers parameters
    self.radarGroupName  = configProfile.radarGroupName
    self.radarUnitType   = configProfile.radarUnitType
    self.radarOffsetX    = configProfile.radarOffsetX
    self.radarOffsetY    = configProfile.radarOffsetY
    self.radarHeading    = configProfile.radarHeading or 0
    self.pointDefense    = configProfile.pointDefense
    self.maxDetectRange  = configProfile.maxDetectRange or 200000.0
    self.radarZoneName   = configProfile.radarZoneName
    self.parentGroupName = configProfile.parentGroupName
    
    -- Spawning Layout Parameters
    self.country         = configProfile.country or "Russia"
    self.groupName       = configProfile.groupName
    self.composition     = configProfile.composition
    self.heading         = configProfile.heading or 0
    self.offsetX         = configProfile.offsetX
    self.offsetY         = configProfile.offsetY
    self.routeConfig     = configProfile.route
    
    -- State Lifecycles
    self.hasSpawned      = false
    self.isCleared       = false
    
    GlobalDirectorRegistry[self.groupName] = self
    return self
end

local function findStaticObstructions(x, y, radius)
    local hasObstruction = false
    local sphere = {
        id = world.VolumeType.SPHERE,
        params = { point = {x = x, y = land.getHeight({x=x, y=y}), z = y}, radius = radius }
    }
    world.searchObjects(Object.Category.SCENERY, sphere, function(obj) hasObstruction = true; return false end)
    return hasObstruction
end

function MissionDirector:deployPlatoon()
    if self.hasSpawned then return end
    local blueBullseye = mist.DBs.missionData["bullseye"]["blue"]
    local bx, bz = blueBullseye.x, blueBullseye.y
    
    -- Calculate our baseline center anchor anchor
    local centerPoint = { x = bx + self.offsetX, y = bz + self.offsetY }
    local spawnOrigin = { x = centerPoint.x, y = centerPoint.y }
    
    -- If a radius is defined, shift our spawn point randomly within that boundary circle
    if self.spawnRadius and self.spawnRadius > 0 then
        -- mist.getRandPointInCircle returns a point structure {x, y}
        local randomPoint = mist.getRandPointInCircle(centerPoint, self.spawnRadius)
        
        -- Run a terrain safety verify layer on the random point to prevent spawning in open ocean water
        if land.getSurfaceType(randomPoint) ~= 3 then -- 3 = Open Water
            spawnOrigin.x = randomPoint.x
            spawnOrigin.y = randomPoint.y
            env.info("[Director] Group '" .. self.groupName .. "' shifted by random radius generator.")
        else
            env.info("[Director] Random point landed in deep water. Defaulting to center anchor for safety.")
        end
    end
    
    -- Compile Waypoints
    local points = {}
    for _, wp in ipairs(self.routeConfig) do
        local node = { ["x"] = bx + wp.offsetX, ["y"] = bz + wp.offsetY, ["type"] = "Turning Point", ["action"] = wp.type or "Off Road", ["speed"] = wp.speed / 3.6 }
        local opts = {}
        if wp.roe and MissionDirector.ROE[wp.roe] then table.insert(opts, { ["id"] = "Option", ["params"] = { ["name"] = OPTION_IDS["ROE"], ["value"] = MissionDirector.ROE[wp.roe] } }) end
        if wp.threat and MissionDirector.THREAT_REACTION[wp.threat] then table.insert(opts, { ["id"] = "Option", ["params"] = { ["name"] = OPTION_IDS["THREAT_REACTION"], ["value"] = MissionDirector.THREAT_REACTION[wp.threat] } }) end
        if #opts > 0 then node["task"] = { ["id"] = "ComboTask", ["params"] = { ["tasks"] = opts } } end
        table.insert(points, node)
    end
    
    -- Compile Safe Units Layout (Maintains linear convoy line trailing back from the random origin point)
    local unitPool = {}
    local currentYOffset = 0
    for idx, unitType in ipairs(self.composition) do
        local checkX, checkY = spawnOrigin.x, spawnOrigin.y + currentYOffset
        local attempts = 0
        while attempts < 20 do
            attempts = attempts + 1
            local surf = land.getSurfaceType({x = checkX, y = checkY})
            -- Accept open Land (1), Roads (4), or Runways (5) -- reject clipping structures
            if (surf == 1 or surf == 4 or surf == 5) and not findStaticObstructions(checkX, checkY, 12) then break end
            checkY = checkY - 20
        end
        table.insert(unitPool, { ["type"] = unitType, ["name"] = self.groupName .. "_Unit_" .. idx, ["x"] = checkX, ["y"] = checkY, ["heading"] = self.heading * (math.pi / 180) })
        currentYOffset = (checkY - spawnOrigin.y) - 25
    end
    
    mist.dynAdd({ ["visible"] = true, ["task"] = "Ground Nothing", ["category"] = "GROUND", ["country"] = self.country, ["name"] = self.groupName, ["route"] = { ["points"] = points }, ["units"] = unitPool })
    self.hasSpawned = true
    env.info("[Director] Successfully spawned group: " .. self.groupName)
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

function MissionDirector:deployRadarStation()
    if not self.radarGroupName or not self.radarUnitType then return end
    
    local finalX, finalY
    
    -- 1. Grab a random point inside the specified ME Trigger Zone
    if self.radarZoneName then
        -- Query the core DCS engine directly—this never returns a nil table error
        local zoneData = trigger.misc.getZone(self.radarZoneName)
        
        if zoneData then
            -- MIST can still randomize coordinates even if its database arrays aren't loaded yet
            local randomZonePoint = mist.getRandomPointInZone(self.radarZoneName)
            
            if randomZonePoint then
                -- TRANSLATION LAYER: Map MIST's 2D vector format to native DCS Surface format
                -- MIST output:  { x = X_COORD, y = Y_COORD }
                -- DCS land API: { x = X_COORD, z = Y_COORD }
                local surfaceCheckPoint = { 
                    x = randomZonePoint.x, 
                    z = randomZonePoint.y 
                }
                
                -- Check surface type accurately (3 = Water)
                if land.getSurfaceType(surfaceCheckPoint) ~= 3 then 
                    finalX = randomZonePoint.x
                    finalY = randomZonePoint.y
                    env.info("[Director] Radar " .. self.radarGroupName .. " successfully randomized inside zone: " .. self.radarZoneName)
                else
                    -- Fallback directly to the exact center of your ME Trigger Zone if the point picked water
                    finalX = zoneData.point.x
                    finalY = zoneData.point.z
                    env.info("[Director Warning] Random zone point landed in water. Centering radar safety fallback inside zone.")
                end
            end
        else
            env.info("[Director Error] Named zone '" .. self.radarZoneName .. "' completely missing from the Mission Editor! Defaulting to profile offsets.")
        end
    end    
    
    -- 2. Explicit Fallback: If zone logic fails or isn't specified, use your profile offsets
    if not finalX or not finalY then
        local blueBullseye = mist.DBs.missionData["bullseye"]["blue"]
        local offsetX = self.radarOffsetX or 0
        local offsetY = self.radarOffsetY or 0
        
        finalX = blueBullseye.x + offsetX
        finalY = blueBullseye.y + offsetY
        env.info("[Director Fallback] Anchoring radar " .. self.radarGroupName .. " to configured profile offsets.")
    end

    -- Construct and deploy the dynamic radar group
    local radarGroupPayload = {
        ["visible"] = true,
        ["task"] = "EWR",
        ["category"] = "GROUND",
        ["country"] = self.country,
        ["name"] = self.radarGroupName,
        ["route"] = { ["points"] = { { ["x"] = finalX, ["y"] = finalY, ["type"] = "Turning Point", ["action"] = "From Ground Area", ["speed"] = 0 } } },
        ["units"] = {
            {
                ["type"] = self.radarUnitType,
                ["name"] = self.radarGroupName .. "_Sensor_Unit",
                ["x"] = finalX, ["y"] = finalY,
                ["heading"] = (self.radarHeading or 0) * (math.pi / 180)
            }
        }
    }
    
    mist.dynAdd(radarGroupPayload)
    
    -- Force radar power state to Red (Active Scan)
    timer.scheduleFunction(function(args)
        local g = Group.getByName(args.name)
        if g and g:getController() then
            g:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
        end
    end, {name = self.radarGroupName}, timer.getTime() + 1.0)

    -- 3. Deploy Air Defense Ring Escorts if configured
    if self.pointDefense and type(self.pointDefense.units) == "table" and #self.pointDefense.units > 0 then
        local minR = self.pointDefense.minRadius or 100
        local maxR = self.pointDefense.maxRadius or 300
        
        for idx, unitType in ipairs(self.pointDefense.units) do
            local randomAngle = math.random() * 2 * math.pi
            local randomDist = minR + (math.random() * (maxR - minR))
            
            local adX = finalX + (math.cos(randomAngle) * randomDist)
            local adY = finalY + (math.sin(randomAngle) * randomDist)
            
            if land.getSurfaceType({x = adX, y = adY}) ~= 3 then
                local adGroupName = self.radarGroupName .. "_AD_Node_" .. idx
                local adPayload = {
                    ["visible"] = true,
                    ["task"] = "Ground Nothing",
                    ["category"] = "GROUND",
                    ["country"] = self.country,
                    ["name"] = adGroupName,
                    ["route"] = { ["points"] = { { ["x"] = adX, ["y"] = adY, ["type"] = "Turning Point", ["action"] = "From Ground Area", ["speed"] = 0 } } },
                    ["units"] = {
                        {
                            ["type"] = unitType,
                            ["name"] = adGroupName .. "_Unit",
                            ["x"] = adX, ["y"] = adY,
                            ["heading"] = math.random(0, 359) * (math.pi / 180)
                        }
                    }
                }
                mist.dynAdd(adPayload)
                
                timer.scheduleFunction(function(args)
                    local g = Group.getByName(args.name)
                    if g and g:getController() then
                        g:getController():setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
                    end
                end, {name = adGroupName}, timer.getTime() + 1.5)
            end
        end
    end
end

function MissionDirector:startEngineLoop()
    -- Immediate Actions Hook
    if self.triggerType == "IMMEDIATE" then
        self:deployPlatoon()
    elseif self.triggerType == "RADAR" then
        self:deployRadarStation()
    end

    local function loopTick(directorInstance)
-- 1. SPAWN LOGIC DISPATCHER
        if not directorInstance.hasSpawned then
            if directorInstance.triggerType == "RADAR" then
                local radarGroup = Group.getByName(directorInstance.radarGroupName)
                
                if radarGroup and radarGroup:getSize() > 0 then
                    local radarUnit = radarGroup:getUnit(1)
                    
                    if radarUnit and radarUnit:isActive() and radarUnit:getLife() > 1 then
                        
                        -- FETCH THE CONTROLLER OBJECT (This is the missing link!)
                        local radarController = radarUnit:getController()
                        
                        if radarController then
                            -- Call getDetectedTargets on the CONTROLLER, not the Unit
                            local detections = radarController:getDetectedTargets()
                            
                            if detections and #detections > 0 then
                                for _, det in ipairs(detections) do
                                    if det.distance and det.distance <= directorInstance.maxDetectRange then
                                        directorInstance:deployPlatoon()
                                        break
                                    end
                                end
                            end
                        end
                        
                    end
                end             
            elseif directorInstance.triggerType == "TRIGGER_ZONE" then
                -- Utilizing MIST's high-performance zone checking vector to find Blue players
                local unitsInZone = mist.getUnitsInZones(mist.makeUnitTable({'[blue]'}), {directorInstance.zoneName})
                if #unitsInZone > 0 then
                    env.info("[Director] Trigger zone '" .. directorInstance.zoneName .. "' breached!")
                    directorInstance:deployPlatoon()
                end
                
            elseif directorInstance.triggerType == "OBJECTIVE_COMPLETE" then
                local parentInstance = GlobalDirectorRegistry[directorInstance.parentGroupName]
                if parentInstance and parentInstance.isCleared then
                    env.info("[Director] Chain criteria met (" .. directorInstance.parentGroupName .. " dead). Dispatching QRF.")
                    directorInstance:deployPlatoon()
                end
            end
        end
        
        -- 2. LIFECYCLE TRACKING CLOSURE
        if directorInstance.hasSpawned and not directorInstance.isCleared then
            if directorInstance:checkOwnUnitsDead() then
                directorInstance.isCleared = true
                trigger.action.outText("Objective Set cleared for " .. directorInstance.groupName, 10)
                return nil -- Terminate this specific loop clock cycle to clean execution heap
            end
        end

        return timer.getTime() + directorInstance.checkInterval
    end
    
    -- Stagger loop cycles to protect engine frametime ticks
    if self.triggerType ~= "IMMEDIATE" or true then
        timer.scheduleFunction(loopTick, self, timer.getTime() + 2.0)
    end
end
