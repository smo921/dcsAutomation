-- ============================================================================
-- GLOBAL THEATER ASSETS (Spawned relative to Bullseye at Mission Start)
-- ============================================================================
local GlobalTheaterAssets = {
    [1] = {
        enabled = true,
        task = "AWACS",
        groupName = "Magic_Global_Sentry",
        unitType = "E-3A",
        country = "USA",
        frequency = 251.0, -- MHz AM
        modulation = "AM",
        callsign = 2, -- Magic
        callsignNumber = 1, -- Magic 1-1
        altitude = 31000, -- Feet
        speed = 290, -- knots
        orbitPattern = "Circle",

        -- BULLSEYE STANDOFF VECTOR
        offsetHeading = 240, -- Heading from Bullseye to safe orbit zone (SW)
        offsetDistance = 50 -- Stay 50nm away from Bullseye center
    },
    [2] = {
        enabled = true,
        groupName = "Texaco_Global_Refueling",
        task = "Refueling",
        unitType = "KC-135",
        country = "USA",

        frequency = 253.0, -- MHz AM
        modulation = "AM",
        callsign = 1, -- Texaco
        callsignNumber = 1, -- Texaco 1-1
        altitude = 31000, -- Feet
        speed = 290, -- knots
        orbitPattern = "Anchored",
        orbitLength = 32, -- 32nm wide racetrack pattern
        orbitWidth = 50,

        -- BULLSEYE STANDOFF VECTOR
        offsetHeading = 330, -- Heading from Bullseye to safe orbit zone (SW)
        offsetDistance = 50 -- Stay 50nm away from Bullseye center
    }
}
-- ==============================================================================
-- 1. CENTRALIZED SECTOR MANIFEST (Edit your mission profiles here)
-- ==============================================================================

local SectorManifest = {
    ["blue"] = {{
        enabled = true,
        triggerType = "IMMEDIATE", -- Runs inside your existing startEngineLoop()
        category = "AIRPLANE", -- Routes execution flows through the new factory branch
        groupName = "Enroute_CAP_Falcon",
        country = "USA",
        task = "CAP",
        placement = {
            startType = "takeoff_hot", -- "takeoff_cold", "takeoff_hot", "takeoff_ramp", or "air_start"
            airbaseName = "Kutaisi" -- Anchor airbase for taxi nodes and initial translation points
        },

        -- Heterogeneous unit arrays are supported out-of-the-box
        units = {{
            unitType = "F-16C_50",
            name = "Falcon_1_1",
            groundSpot = 22
        }, {
            unitType = "F-16C_50",
            name = "Falcon_1_2",
            groundSpot = 23
        }},

        route = {{
            type = "Turning Point",
            alt = 19000, -- Flight altitude in feet
            speed = 450, -- Velocity in knots
            offsetX = 8, -- NM offset from departure airfield center
            offsetY = 16
        }, {
            type = "Turning Point",
            alt = 19000,
            speed = 450,
            offsetX = -6,
            offsetY = 25,
            roe = "OPEN_FIRE" -- Hooks straight into AssetFactories.ROE mapping
        }, {
            type = "landing", -- Routes safely back to the base specified below
            airbaseName = "Kutaisi"
        }}
    }, -- Add this directly into your SectorManifest["blue"] array inside mission_test.lua
    {
        enabled = true,
        triggerType = "IMMEDIATE", -- Boots up immediately when startEngineLoop() runs
        category = "HELICOPTER", -- Routes the group through the new air factory code
        groupName = "Hunter_Killer_Flight",
        country = "USA",
        task = "CAS", -- Close Air Support role

        placement = {
            startType = "takeoff_cold", -- Spawns cold on the ramp slots at the airbase
            airbaseName = "Kutaisi" -- Airfield anchor for parsing coordinates & parking IDs
        },

        -- Heterogeneous flight: Mixing asymmetric airframes within a single tactical group
        units = {{
            unitType = "AH-64D_BLK_II",
            name = "Hunter_Lead",
            groundSpot = 15
        }, -- Apache Lead
        {
            unitType = "OH-58D",
            name = "Killer_Wingman",
            groundSpot = 16
        } -- Kiowa Scout
        },

        -- Flight path using metric offsets relative to the Kutaisi airbase origin
        route = {{
            type = "Turning Point",
            alt = 100, -- Low altitude ingress (feet)
            speed = 115, -- ~115 knots ground speed (m/s)
            offsetX = 5, -- 5nm North of Kutaisi
            offsetY = 12 -- 12nm East of Kutaisi
        }, {
            type = "Turning Point",
            alt = 50, -- Masking behind terrain
            speed = 100, -- Slowing down to screen the area
            offsetX = 8,
            offsetY = 25,
            roe = "OPEN_FIRE" -- Switches rules of engagement to Weapon Free via AssetFactories.ROE
        }, {
            type = "landing", -- Directs the engine to track landing recovery
            airbaseName = "Kutaisi" -- Routes the flight back to land at the starting airfield
        }}
    }},
    ["red"] = { -- SECTOR 1: Spawned instantly at mission start
    {
        enabled = false,
        triggerType = "IMMEDIATE",
        groupName = "Border_Patrol_Alpha",
        country = "Russia",
        units = {"T-72B", "BMP-2"},

        placement = {
            heading = 90,
            offsetX = 2.7,
            offsetY = 2.7,
            spawnRadius = 1.0
        },

        route = {{
            type = "On Road",
            speed = 30,
            offsetX = 2.7,
            offsetY = 2.7
        }, {
            type = "On Road",
            speed = 30,
            offsetX = 4.3,
            offsetY = 6.5
        }},
        -- NEW: Drone assigned to track this ground movement profile right at mission start
        drone = {
            groupName = "Reaper_Overwatch_Alpha",
            unitType = "MQ-9 Reaper",
            country = "USA",
            frequency = 133.1,
            callsign = 1,
            altitude = 15000,
            speed = 110
        }
    }, -- SECTOR 2: Traditional Radar Intercept Gate
    {
        enabled = true,
        triggerType = "RADAR",
        radarFilterEnabled = true,
        groupName = "EW Radar Alpha",
        country = "Russia",
        unitType = "1L13 EWR",

        placement = {
            heading = 135,
            offsetX = 0.9, -- fallback offset from bullseye if zone not found
            offsetY = 1.4,
            spawnRadius = 0.5,
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

        maxDetectRangeNM = 80.0,
        checkInterval = 5.0,

        -- DEDICATED RECON DRONE: Tied strictly to this localized sector target
        drone = {
            enabled = false,
            groupName = "Reaper_Eye_Bravo",
            unitType = "MQ-9 Reaper",
            country = "USA",
            frequency = 133.0, -- MHz AM
            callsign = 1, -- Darkstar
            altitude = 16500, -- feet
            speed = 120 -- knots
        },

        triggeredUnits = {
            groupName = "North_Vanguard_Platoon",
            country = "Russia",
            units = {"T-72B", "BMP-2", "ZSU-23-4 Shilka"},
            placement = {
                heading = 0,
                offsetX = -1.0,
                offsetY = 16,
                spawnRadius = 0.1
            },
            route = {{
                type = "On Road",
                speed = 40,
                offsetX = 8.0,
                offsetY = 6.0
            }, {
                type = "Off Road",
                speed = 25,
                offsetX = 16.0,
                offsetY = 5.4,
                roe = "OPEN_FIRE"
            }}
        }
    }, -- SECTOR 3: Triggered when a player enters a Mission Editor Trigger Zone
    {
        enabled = true,
        triggerType = "TRIGGER_ZONE",
        zoneName = "Valley_Breach_Zone", -- Must match your exact ME Trigger Zone Name
        checkInterval = 2.0,

        groupName = "Ambush_Team_Bravo",
        country = "Russia",
        units = {"BMP-2", "BRDM-2"},
        placement = {
            heading = 180,
            offsetX = -1.2,
            offsetY = 8.5,
            spawnRadius = 1.0
        },
        route = {{
            type = "Off Road",
            speed = 40,
            offsetX = -1.2,
            offsetY = 8.5
        }, {
            type = "Off Road",
            speed = 30,
            offsetX = -3.0,
            offsetY = 4.0,
            roe = "OPEN_FIRE"
        }}
    }, -- SECTOR 4: Chain reaction. Spawns ONLY after Sector 2's objectives are cleared!
    {
        enabled = false,
        triggerType = "OBJECTIVE_COMPLETE",
        parentGroupName = "North_Vanguard_Platoon", -- Watches the group state of Sector 2
        checkInterval = 5.0,

        groupName = "Quick_Reaction_Force_QRF",
        country = "Russia",
        units = {"T-72B", "T-72B", "BMP-2"},
        placement = {
            heading = 45,
            offsetX = 17.3,
            offsetY = 6.5,
            spawnRadius = 1.2
        },
        route = {{
            type = "Off Road",
            speed = 50,
            offsetX = 17.3,
            offsetY = 6.5
        }, {
            type = "Off Road",
            speed = 30,
            offsetX = 16.2,
            offsetY = 5.4,
            roe = "OPEN_FREE"
        }}
    }, {
        enabled = false,
        triggerType = "IMMEDIATE",
        groupName = "Waypoint_Patrol",
        country = "Russia",
        units = {"T-72B", "BMP-2"},
        placement = {
            groupName = "Aerial-1",
            waypoint = 2, -- waypoints start at 1
            heading = 90
        }
    }, {
        enabled = false,
        triggerType = "IMMEDIATE",
        category = "AIRPLANE",
        groupName = "Red_Hot_Start_Flight",
        country = "Russia",
        task = "CAS",
        placement = {
            airbaseName = "Kutaisi", -- Origin aerodrome
            startType = "takeoff_hot", -- Triggers the "From Parking Area Hot" workflow
            heading = 90
        },
        units = {{
            unitType = "Su-25T",
            name = "Red_Leader",
            groundSpot = 1
        }},
        route = { -- Waypoint 2: Intermediate egress point (15km East, 5km North of airfield center)
        {
            type = "Turning Point",
            alt = 2000, -- Meters MSL
            speed = 200, -- Meters/sec
            offsetX = 15000,
            offsetY = 5000
        }, -- Waypoint 3: Landing sequence back at Kutaisi (or your designated destination)
        {
            type = "landing",
            airbaseName = "Kutaisi"
        }}
    }}
}

-- ==============================================================================
-- MAIN ORCHESTRATION ENGINE INJECTION
-- ==============================================================================

function startDynamicTheatre()
    -- 1. Initialize global assets (AWACS relative to Bullseye)
    MissionDirector:initializeGlobalAssets(GlobalTheaterAssets)

    if SectorManifest["red"] then
        local redSectors = MissionDirector.new(SectorManifest["red"])
        redSectors:startEngineLoop()
    end
    if SectorManifest["blue"] then
        local blueSectors = MissionDirector.new(SectorManifest["blue"])
        blueSectors:startEngineLoop()
    end

    env.info("[Orchestrator] All dynamic theatre environments successfully initialized.")
end

-- Delay processing initialization execution by 3 seconds
timer.scheduleFunction(startDynamicTheatre, {}, timer.getTime() + 3.0)
