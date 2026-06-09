-- ==============================================================
-- DCS World – “Detect if any enemy aircraft has been found
--            by an early‑warning radar” – Script
-- ==============================================================

-- CONFIGURABLE --------------------------------------------------
local radarGroupName = "EW Radar 1"   -- <--- Change this to your radar’s group name
local checkInterval  = 5.0           -- seconds between checks (set to 0 to check only once)
local maxDetectRange = 200000.0      -- optional: ignore detections farther than 200 km (in metres)
local filterByAircraft = nil        -- optional: set to a string (e.g. "F-16") to only flag that type
-- ----------------------------------------------------------------

-- Get the radar unit -------------------------------------------------
local radarGroup = Group.getByName(radarGroupName)

if not radarGroup then
    env.info("[RadarCheck] Group '" .. radarGroupName .. "' not found.")
    return
end

-- Assume radar unit is the first unit in the group
local radarUnit = radarGroup:getUnit(1)

if not radarUnit then
    env.info("[RadarCheck] No units found in group '" .. radarGroupName .. "'.")
    return
end

-- Helper: Pretty‑print a single detection ------------------------------------
local function formatDetection(det)
    local name   = det.unitName or det.objectName or det.aircraftName or "Unknown"
    local dist   = det.distance or 0
    local az     = det.azimuth or 0
    local range  = string.format("%.1f km", dist / 1000)
    local azStr  = string.format("%.1f°", az)
    return string.format("%s – %s, azimuth %s", name, range, azStr)
end

-- Main routine that queries the radar ---------------------------------------
local function checkRadar()
    local detections = radarUnit:getDetectedTargets()

    if detections and #detections > 0 then
        env.info("[RadarCheck] Radar '" .. radarGroupName .. "' detected " .. #detections .. " target(s).")

        for _, det in ipairs(detections) do
            -- Optional: ignore very far detections
            if det.distance and det.distance > maxDetectRange then
                env.info("[RadarCheck]  Skipping – beyond max range (" .. maxDetectRange / 1000 .. " km).")
                goto continue
            end

            -- Optional: filter by aircraft type (only works if the radar reports it)
            if filterByAircraft then
                local aircraft = det.aircraftName or det.objectName or det.unitName or ""
                if not string.find(aircraft, filterByAircraft, 1, true) then
                    env.info("[RadarCheck]  Skipping – not a " .. filterByAircraft .. ".")
                    goto continue
                end
            end

            env.info("[RadarCheck]  Target: " .. formatDetection(det))
            ::continue::
        end

        -- Your custom logic here – e.g. trigger a client message, change AI state, etc.
        -- For example: env.mission.setWaypoint(1, "DetectedEnemy")

    else
        env.info("[RadarCheck] Radar '" .. radarGroupName .. "' found NO targets.")
    end

    -- If we want to keep checking, return the next time we want to run
    if checkInterval > 0 then
        return timer.getTime() + checkInterval
    end
end

-- Kick‑off the first check ------------------------------------
timer.scheduleFunction(checkRadar, {}, timer.getTime() + 1)