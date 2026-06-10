-- ============================================================================
-- GLOBAL THEATER ASSETS (Spawned relative to Bullseye at Mission Start)
-- ============================================================================
local GlobalTheaterAssets = {
    awacs = {
        groupName = "Magic_Global_Sentry",
        unitType = "E-3A",
        country = "USA",
        frequency = 251.0, -- MHz AM
        modulation = "AM",
        callsign = 2, -- Magic
        callsignNumber = 1, -- Magic 1-1
        altitude = 9500, -- Meters (~31,000 ft) for maximum radar horizon
        speed = 540, -- km/h
        orbitLength = 60000, -- 60km wide racetrack pattern

        -- BULLSEYE STANDOFF VECTOR
        offsetHeading = 240, -- Heading from Bullseye to safe orbit zone (SW)
        offsetDistance = 90 -- Stay 90 kilometers away from Bullseye center
    }
}
-- ==============================================================================
-- 1. CENTRALIZED SECTOR MANIFEST (Edit your mission profiles here)
-- ==============================================================================

local SectorManifest = { -- SECTOR 1: Spawned instantly at mission start
{
    triggerType = "IMMEDIATE",
    groupName = "Border_Patrol_Alpha",
    country = "Russia",
    units = {"T-72B", "BMP-2"},
    heading = 90,

    placement = {
        offsetX = 5000,
        offsetY = 5000,
        spawnRadius = 2000
    },

    route = {{
        type = "On Road",
        speed = 30,
        offsetX = 5000,
        offsetY = 5000
    }, {
        type = "On Road",
        speed = 30,
        offsetX = 8000,
        offsetY = 12000
    }},
    -- NEW: Drone assigned to track this ground movement profile right at mission start
    drone = {
        groupName = "Reaper_Overwatch_Alpha",
        unitType = "MQ-9 Reaper",
        country = "USA",
        frequency = 133.1,
        callsign = 1,
        altitude = 4500,
        speed = 200
    }
}, -- SECTOR 2: Traditional Radar Intercept Gate
{
    triggerType = "RADAR",
    groupName = "EW Radar Alpha",
    unitType = "1L13 EWR",
    heading = 135,

    placement = {
        offsetX = 1500, -- fallback offset from bullseye if zone not found
        offsetY = 2500,
        spawnRadius = 1000,
        strategy = "ZONE_RANDOM",
        zoneName = "Alpha_Radar_Clearing"
    },

    -- NEW: Air Defense Ring Configuration
    pointDefense = {
        minRadius = 150, -- Minimum distance from the radar (so they don't clip)
        maxRadius = 350, -- Maximum scatter distance
        units = {"Tor 9A331", -- SA-15 Gauntlet (Tracked SAM)
        "2S6 Tunguska", -- SA-19 Tunguska (AAA + SAM)
        "Ural-375 ZU-23" -- Truck-mounted AAA
        }
    },

    maxDetectRange = 150000.0,
    checkInterval = 5.0,

    -- DEDICATED RECON DRONE: Tied strictly to this localized sector target
    drone = {
        groupName = "Reaper_Eye_Bravo",
        unitType = "MQ-9 Reaper",
        country = "USA",
        frequency = 133.0, -- MHz AM
        callsign = 1, -- Darkstar
        altitude = 5000, -- Meters
        speed = 220 -- km/h
    },

    triggeredUnits = {
        groupName = "North_Vanguard_Platoon",
        country = "Russia",
        units = {"T-72B", "BMP-2", "ZSU-23-4 Shilka"},
        heading = 0,
        offsetX = 15000,
        offsetY = 10000,
        spawnRadius = 2000,
        route = {{
            type = "On Road",
            speed = 40,
            offsetX = 15000,
            offsetY = 10000
        }, {
            type = "Off Road",
            speed = 25,
            offsetX = 30000,
            offsetY = 10000,
            roe = "OPEN_FIRE"
        }}
    }
}, -- SECTOR 3: Triggered when a player enters a Mission Editor Trigger Zone
{
    triggerType = "TRIGGER_ZONE",
    checkInterval = 2.0,

    groupName = "Ambush_Team_Bravo",
    country = "Russia",
    units = {"BMP-2", "BRDM-2"},
    heading = 180,
    placement = {
        zoneName = "Valley_Breach_Zone", -- Must match your exact ME Trigger Zone Name
        offsetX = -2000,
        offsetY = 15000,
        spawnRadius = 2000
    },
    route = {{
        type = "Off Road",
        speed = 40,
        offsetX = -2000,
        offsetY = 15000
    }, {
        type = "Off Road",
        speed = 30,
        offsetX = -5000,
        offsetY = 8000,
        roe = "OPEN_FIRE"
    }}
}, -- SECTOR 4: Chain reaction. Spawns ONLY after Sector 2's objectives are cleared!
{
    triggerType = "OBJECTIVE_COMPLETE",
    parentGroupName = "North_Vanguard_Platoon", -- Watches the group state of Sector 2
    checkInterval = 5.0,

    groupName = "Quick_Reaction_Force_QRF",
    country = "Russia",
    units = {"T-72B", "T-72B", "BMP-2"},
    heading = 45,
    placement = {
        offsetX = 32000,
        offsetY = 12000,
        spawnRadius = 2000,
    },
    route = {{
        type = "Off Road",
        speed = 50,
        offsetX = 32000,
        offsetY = 12000
    }, {
        type = "Off Road",
        speed = 30,
        offsetX = 30000,
        offsetY = 10000,
        roe = "OPEN_FREE"
    }}
}}
-- ==============================================================================
-- MAIN ORCHESTRATION ENGINE INJECTION
-- ==============================================================================

function startDynamicTheatre()
    -- 1. Initialize global assets (AWACS relative to Bullseye)
    MissionDirector:initializeGlobalAssets(GlobalTheaterAssets)

    -- 2. Loop through the manifest, build the objects, and spin up their lifecycles
    for _, profile in ipairs(SectorManifest) do
        local sector = MissionDirector.new(profile)

        -- REUSED HOOK: This kicks off the routing logic we defined above!
        sector:startEngineLoop()
    end
    env.info("[Orchestrator] All dynamic theatre environments successfully initialized.")
end

-- Delay processing initialization execution by 3 seconds
timer.scheduleFunction(startDynamicTheatre, {}, timer.getTime() + 3.0)
