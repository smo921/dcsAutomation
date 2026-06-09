-- ==============================================================================
-- 1. CENTRALIZED SECTOR MANIFEST (Edit your mission profiles here)
-- ==============================================================================

local SectorManifest = {
    -- SECTOR 1: Spawned instantly at mission start
    {
        triggerType      = "IMMEDIATE",
        groupName        = "Border_Patrol_Alpha",
        country          = "Russia",
        composition      = { "T-72B", "BMP-2" },
        heading          = 90,
        offsetX          = 5000, 
        offsetY          = 5000,
        spawnRadius      = 2000,
        route = {
            { type = "On Road", speed = 30, offsetX = 5000, offsetY = 5000 },
            { type = "On Road", speed = 30, offsetX = 8000, offsetY = 12000 }
        }
    },

    -- SECTOR 2: Traditional Radar Intercept Gate
    {
        triggerType      = "RADAR",
        radarGroupName   = "EW Radar Alpha",
        radarUnitType    = "1L13 EWR",
        radarZoneName    = "Alpha_Radar_Clearing",
        radarHeading    = 135,
        radarOffsetX    = 1500, -- fallback offset from bullseye if zone not found
        radarOffsetY    = 2500,
        
        -- NEW: Air Defense Ring Configuration
        pointDefense = {
            minRadius = 150, -- Minimum distance from the radar (so they don't clip)
            maxRadius = 350, -- Maximum scatter distance
            units = { 
                "Tor 9A331",         -- SA-15 Gauntlet (Tracked SAM)
                "2S6 Tunguska",      -- SA-19 Tunguska (AAA + SAM)
                "Ural-375 ZU-23",    -- Truck-mounted AAA
            }
        },

        maxDetectRange   = 150000.0,
        checkInterval    = 5.0,
        
        groupName        = "North_Vanguard_Platoon",
        country          = "Russia",
        composition      = { "T-72B", "BMP-2", "ZSU-23-4 Shilka" },
        heading          = 0,
        offsetX          = 15000, 
        offsetY          = 10000,
        spawnRadius      = 2000,
        route = {
            { type = "On Road",  speed = 40, offsetX = 15000, offsetY = 10000 },
            { type = "Off Road", speed = 25, offsetX = 30000, offsetY = 10000, roe = "OPEN_FIRE" }
        }
    },

    -- SECTOR 3: Triggered when a player enters a Mission Editor Trigger Zone
    {
        triggerType      = "TRIGGER_ZONE",
        zoneName         = "Valley_Breach_Zone", -- Must match your exact ME Trigger Zone Name
        checkInterval    = 2.0,
        
        groupName        = "Ambush_Team_Bravo",
        country          = "Russia",
        composition      = { "BMP-2", "BRDM-2" },
        heading          = 180,
        offsetX          = -2000, 
        offsetY          = 15000,
        spawnRadius      = 2000,
        route = {
            { type = "Off Road", speed = 40, offsetX = -2000, offsetY = 15000 },
            { type = "Off Road", speed = 30, offsetX = -5000, offsetY = 8000, roe = "OPEN_FIRE" }
        }
    },

    -- SECTOR 4: Chain reaction. Spawns ONLY after Sector 2's objectives are cleared!
    {
        triggerType      = "OBJECTIVE_COMPLETE",
        parentGroupName  = "North_Vanguard_Platoon", -- Watches the group state of Sector 2
        checkInterval    = 5.0,
        
        groupName        = "Quick_Reaction_Force_QRF",
        country          = "Russia",
        composition      = { "T-72B", "T-72B", "BMP-2" },
        heading          = 45,
        offsetX          = 32000, 
        offsetY          = 12000,
        spawnRadius      = 2000,
        route = {
            { type = "Off Road", speed = 50, offsetX = 32000, offsetY = 12000 },
            { type = "Off Road", speed = 30, offsetX = 30000, offsetY = 10000, roe = "OPEN_FREE" }
        }
    }
}
-- ==============================================================================
-- MAIN ORCHESTRATION ENGINE INJECTION
-- ==============================================================================

function startDynamicTheatre()
    for _, configBlock in ipairs(SectorManifest) do
        local directorInstance = MissionDirector.new(configBlock)
        directorInstance:startEngineLoop()
    end
    
    env.info("[Orchestrator] All dynamic theatre environments successfully initialized.")
end

-- Delay processing initialization execution by 3 seconds
timer.scheduleFunction(startDynamicTheatre, {}, timer.getTime() + 3.0)