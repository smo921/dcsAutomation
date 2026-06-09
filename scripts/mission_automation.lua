-- ==============================================================
-- DCS World – Combined Mission Automation Framework
-- ==============================================================


-- 1. GROUP ALIVE UTILITY FUNCTIONS -----------------------------
local function isGroupAlive(groupName)
    local g = Group.getByName(groupName)
    if not g then return false end
    
    local gs = g:getSize()
    if gs < 1 then return false end

    for i = 1, gs do
        local u = g:getUnit(i)
        if u and u:isActive() and u:getLife() > 1 then
            return true
        end
    end
    return false
end

local function isGroupDead(name)
    for i = monitorStartIdx, monitorStopIdx do
        if isGroupAlive(name .. i) then
            return false -- At least one unit is still breathing
        end
    end
    return true -- Entire pool is dead
end

-- 2. RESPAWN & ACTIVATION LOGIC --------------------------------
local function handleThreatResponse(name)
    -- First, try to activate the primary target defense group if it's sleeping
    local g = Group.getByName(name)
    if g and not g:isLateActivation() then
        trigger.action.activateGroup(g)
    end

    -- Integrated MIST Respawn Logic
    if type(mist) ~= "table" then
        env.info("[Automation] CRITICAL: MIST is not loaded. Cannot process respawns.")
        return
    end

    if mist.groupIsDead(name) then
        env.info("[Automation] " .. name .. " is destroyed. Requesting MIST respawn.")
        mist.respawnGroup(name, true)
    end
end

local function formatDetection(det)
    local name   = det.unitName or det.objectName or det.aircraftName or "Unknown"
    local dist   = det.distance or 0
    local az     = det.azimuth or 0
    local range  = string.format("%.1f km", dist / 1000)
    local azStr  = string.format("%.1f°", az)
    return string.format("%s – %s, azimuth %s", name, range, azStr)
end

local function checkRadar(name)
    env.info("[Automation] [checkradar(" .. name .. "Looking for radar: " .. name)

    local radarGroup = Group.getByName(name)
    if not radarGroup then
        env.info("[Automation] Radar group '" .. name .. "' not found.")
        return timer.getTime() + checkInterval
    end

    local radarUnit = radarGroup:getUnit(1)
    if not radarUnit then 
        return timer.getTime() + checkInterval 
    end

    local detections = radarUnit:getDetectedTargets()
    local hostileSpotted = false

    if detections and #detections > 0 then
        for _, det in ipairs(detections) do
            if det.distance and det.distance <= maxDetectRange then
                hostileSpotted = true
                env.info("[RadarCheck]  Target: " .. formatDetection(det))
                break -- We only need one valid detection to trigger defenses
            end
        end
    end

    -- Take action if the early warning network catches a player
    if hostileSpotted then
        env.info("[Automation] Hostiles tracked by " .. name .. ". Tripping defense reactions.")
        handleThreatResponse(targetActivationGroup)
    end

    -- Continuous monitoring of your dynamic target pool
    if isGroupDead(monitoredPrefix) then
        env.info("[Automation] All monitored objective groups are DEAD.")
        -- Insert win conditions, flag adjustments, or secondary respawns here
    end
end

-- 3. MAIN RADAR SINK LOOP --------------------------------------
local function runFramework(argv)
    checkRadar(argv[1])
    return timer.getTime() + checkInterval
end


-- START THE ENGINE ---------------------------------------------
env.info("[Automation] Framework loaded. Starting main tracking loop...")
timer.scheduleFunction(runFramework, {radarGroupName}, timer.getTime() + 2)