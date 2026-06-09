-- ------------------------------------------------------------------------------
-- 2. LIVE MISSION RUNTIME EXECUTION
-- ------------------------------------------------------------------------------
local function runSpawningTest()
    -- Guard Check: Make sure MIST is loaded before calling its database handler
    if type(mist) ~= "table" then
        trigger.action.outText("TEST FAILED: MIST framework is not loaded! Ensure mist.lua runs first.", 10)
        env.info("[Spawner Test] CRITICAL ERROR: MIST not initialized.")
        return
    end

    env.info("[Spawner Test] Initiating telemetry tracking...")

    -- Step A: Dynamically extract the current Blue Bullseye position coordinates
    
    env.info("[Spawnder Test] Databases: ")
    
    local blueBullseye = mist.DBs.missionData.bullseye.blue
    local bx = blueBullseye.x
    local by = blueBullseye.y
    
    trigger.action.outText("Fetched Blue Bullseye tracking anchors. Generating threat profiles...", 5)
    env.info("[Spawner Test] Blue Bullseye reference grid location: X=" .. bx .. ", Z=" .. by)

    -- Step B: Assemble the programmatic waypoint sequence
    local points = {}

    -- Waypoint 1: Ingress Point (Placed 10km North, 5km East of Bullseye)
    -- Setting action to "On Road" tells the AI pathfinder to snap to asphalt automatically
    local wp1 = Spawner.createWaypoint(bx + 10000, by + 5000, 40, "On Road")
    table.insert(points, wp1)

    -- Waypoint 2: Objective Target Zone (Placed 25km North, 5km East of Bullseye)
    local wp2 = Spawner.createWaypoint(bx + 25000, by + 5000, 25, "Off Road")
    
    -- Inject semantic rules: Hold fire during transit, but evade threats actively
    local wp2Behaviors = {
        Spawner.setOption("ROE", "WEAPON_HOLD"),
        Spawner.setOption("THREAT_REACTION", "EVADE_FIRE")
    }
    Spawner.addOptionsToWaypoint(wp2, wp2Behaviors)
    table.insert(points, wp2)

    -- Waypoint 3: Terminal Combat Line (Placed 35km North, 8km East of Bullseye)
    local wp3 = Spawner.createWaypoint(bx + 35000, by + 8000, 20, "Off Road")
    
    -- Inject terminal behavior: Transition to weapons free to engage blue units
    local wp3Behaviors = {
        Spawner.setOption("ROE", "OPEN_FIRE")
    }
    Spawner.addOptionsToWaypoint(wp3, wp3Behaviors)
    table.insert(points, wp3)

    -- Step C: Build the vehicle unit cluster layout arrays
    local unitPool = {}
    local spawnOrigin = points[1] -- Anchor directly to the starting position coordinates of Waypoint 1
    
    -- Simple armored reconnaissance layout
    local guardPlatoon = { "T-72B", "BMP-2", "BMP-2", "BRDM-2" }
    
    Spawner.spawnSafeColumn(
        "Dynamnic_Vanguard_Platoon", -- Unique Group Name
        guardPlatoon,               -- Unit Composition table
        spawnOrigin,                 -- Where to start (Origin)
        points,                     -- Routed Waypoint array path
        0,                          -- Heading North (Degrees)
        "Russia"                    -- Country Asset Allocation
    )
    
    trigger.action.outText("SUCCESS: Dynamic threat group 'Dynamnic_Vanguard_Platoon' deployed relative to Bullseye!", 10)
    env.info("[Spawner Test] Group initialization completed successfully.")
end

-- Schedule the entire routine to execute 3 seconds after the script loads
-- This buffer gives the DCS world engine moment to settle down when loading the mission
timer.scheduleFunction(runSpawningTest, {}, timer.getTime() + 3.0)