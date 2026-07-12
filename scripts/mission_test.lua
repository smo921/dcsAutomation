-- ==============================================================================
-- CENTRALIZED UNIT MANIFEST
-- Edit your mission profiles here using NATO units:
--   - Altitude: feet
--   - Distance: nautical miles (NM)
--   - Speed: knots
-- ==============================================================================

-- ==============================================================================
-- BLUE COALITION - FRIENDLY FORCES
-- ==============================================================================

local BlueUnitManifest = {
    -- ============================================================================
    -- AIR UNIT: Enroute CAP Falcon (Airbase ramp anchoring)
    -- ============================================================================
    {
        enabled = true,
        triggerType = "IMMEDIATE",
        category = "AIRPLANE",
        groupName = "Enroute_CAP_Falcon",
        country = "USA",
        task = "CAP",
        placement = {
            startType = "takeoff_hot",  -- "takeoff_cold", "takeoff_hot", "takeoff_ramp", or "air_start"
            airbaseName = "Kutaisi"      -- Anchor airbase for taxi nodes
        },
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
            alt = 19000,    -- Flight altitude in feet
            speed = 450,    -- Velocity in knots
            offsetX = 8,    -- NM offset from departure airfield center
            offsetY = 16
        }, {
            type = "Turning Point",
            alt = 19000,
            speed = 450,
            offsetX = -6,
            offsetY = 25,
            roe = "OPEN_FIRE"  -- Hooks straight into AssetFactories.ROE mapping
        }, {
            type = "landing",
            airbaseName = "Kutaisi"
        }}
    },

    -- ============================================================================
    -- AWACS: Magic Global Sentry (Bearing + distance from bullseye)
    -- ============================================================================
    {
        enabled = true,
        triggerType = "IMMEDIATE",
        category = "AIRPLANE",
        groupName = "Magic_Global_Sentry",
        task = "AWACS",
        country = "USA",
        frequency = 271,         -- UHF frequency in MHz (unique from tanker)
        modulation = "AM",
        callsign = "MAGIC",
        callsignNumber = 1,
        placement = {
            offsetHeading = 240,   -- Heading from Bullseye to safe orbit zone (SW)
            offsetDistance = 50,   -- Stay 50nm away from Bullseye center
            heading = 0,           -- Unit orientation (0 = North)
            altitude = 31000,      -- Feet
            speed = 290            -- knots
        },
        units = {{
            unitType = "E-3A"
        }},
        route = {
            {
                type = "Turning Point",
                alt = 31000,
                speed = 290,
                offsetX = 0,
                offsetY = 0
            },
            {
                type = "Turning Point",
                alt = 31000,
                speed = 290,
                offsetX = 5,   -- 5 nautical miles offset for orbit pattern
                offsetY = 0
            }
        }
    },

    -- ============================================================================
    -- TANKER: Texaco Global Refueling (Bearing + distance from bullseye)
    -- ============================================================================
    {
        enabled = true,
        triggerType = "IMMEDIATE",
        category = "AIRPLANE",
        groupName = "Texaco_Global_Refueling",
        task = "Refueling",
        country = "USA",
        frequency = 266,         -- UHF frequency in MHz
        modulation = "AM",
        callsign = "TEXACO",
        callsignNumber = 1,
        tacanChannel = "12X",    -- TACAN channel for navigation
        placement = {
            offsetHeading = 330,   -- Heading from Bullseye to safe orbit zone (SW)
            offsetDistance = 50,   -- Stay 50nm away from Bullseye center
            heading = 0,           -- Unit orientation (0 = North)
            altitude = 31000,      -- Feet
            speed = 290            -- knots
        },
        units = {{
            unitType = "KC-135"
        }},
        route = {
            {
                type = "Turning Point",
                alt = 31000,
                speed = 290,
                offsetX = 0,
                offsetY = 0
            },
            {
                type = "Turning Point",
                alt = 31000,
                speed = 290,
                offsetX = 5,   -- 5 nautical miles offset for orbit pattern
                offsetY = 0
            }
        }
    },

    -- ============================================================================
    -- HELICOPTER: Hunter-Killer Flight (Airbase CAS flight)
    -- ============================================================================
    {
        enabled = true,
        triggerType = "IMMEDIATE",
        category = "HELICOPTER",
        groupName = "Hunter_Killer_Flight",
        country = "USA",
        task = "CAS",
        placement = {
            startType = "takeoff_cold",  -- Spawns cold on the ramp slots
            airbaseName = "Kutaisi"
        },
        units = {{
            unitType = "AH-64D_BLK_II",
            name = "Hunter_Lead",
            groundSpot = 15
        }, {
            unitType = "OH-58D",
            name = "Killer_Wingman",
            groundSpot = 16
        }},
        route = {{
            type = "Turning Point",
            alt = 100,     -- Low altitude ingress (feet)
            speed = 115,   -- Ground speed in knots
            offsetX = 5,   -- 5nm North of Kutaisi
            offsetY = 12   -- 12nm East of Kutaisi
        }, {
            type = "Turning Point",
            alt = 50,      -- Masking behind terrain
            speed = 100,
            offsetX = 8,
            offsetY = 25,
            roe = "OPEN_FIRE"
        }, {
            type = "landing",
            airbaseName = "Kutaisi"
        }}
    }
}

-- ==============================================================================
-- RED COALITION - OPFOR
-- ==============================================================================

local RedUnitManifest = {
    -- ============================================================================
    -- UNIT 1: Border Patrol (IMMEDIATE - disabled by default)
    -- ============================================================================
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
        drone = {
            groupName = "Reaper_Overwatch_Alpha",
            unitType = "MQ-9 Reaper",
            country = "USA",
            frequency = 133.1,
            callsign = 1,
            altitude = 15000,  -- feet
            speed = 200        -- knots
        }
    },

    -- ============================================================================
    -- SECTOR 2: Radar Intercept Gate (RADAR - triggers on detection)
    -- ============================================================================
    {
        enabled = true,
        triggerType = "RADAR",
        radarFilterEnabled = true,
        groupName = "EW Radar Alpha",
        country = "Russia",
        unitType = "1L13 EWR",
        placement = {
            heading = 135,
            offsetX = 0.9,    -- fallback offset from bullseye if zone not found
            offsetY = 1.4,
            spawnRadius = 0.5,
            strategy = "ZONE_RANDOM",
            zoneName = "Alpha_Radar_Clearing"
        },
        pointDefense = {
            minRadius = 150,  -- Minimum distance from the radar
            maxRadius = 350,  -- Maximum scatter distance
            units = {
                "Tor 9A331",      -- SA-15 Gauntlet (Tracked SAM)
                "2S6 Tunguska",   -- SA-19 Tunguska (AAA + SAM)
                "Ural-375 ZU-23"  -- Truck-mounted AAA
            }
        },
        maxDetectRangeNM = 80.0,  -- Range in nautical miles

        drone = {
            enabled = false,
            groupName = "Reaper_Eye_Bravo",
            unitType = "MQ-9 Reaper",
            country = "USA",
            frequency = 133.0,
            callsign = 1,
            altitude = 16500,  -- feet
            speed = 200        -- knots
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
    },

    -- ============================================================================
    -- SECTOR 3: Trigger Zone Ambush (TRIGGER_ZONE)
    -- ============================================================================
    {
        enabled = true,
        triggerType = "TRIGGER_ZONE",
        zoneName = "Valley_Breach_Zone",
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
    },

    -- ============================================================================
    -- SECTOR 4: Quick Reaction Force (OBJECTIVE_COMPLETE - chain reaction)
    -- ============================================================================
    {
        enabled = false,
        triggerType = "OBJECTIVE_COMPLETE",
        parentGroupName = "North_Vanguard_Platoon",
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
    },

    -- ============================================================================
    -- SECTOR 5: Waypoint Patrol (Follows another group's waypoints)
    -- ============================================================================
    {
        enabled = false,
        triggerType = "IMMEDIATE",
        groupName = "Waypoint_Patrol",
        country = "Russia",
        units = {"T-72B", "BMP-2"},
        placement = {
            groupName = "Aerial-1",
            waypoint = 2,    -- waypoints start at 1
            heading = 90
        }
    },

    -- ============================================================================
    -- SECTOR 6: Red Air CAS (Airbase hot start)
    -- ============================================================================
    {
        enabled = false,
        triggerType = "IMMEDIATE",
        category = "AIRPLANE",
        groupName = "Red_Hot_Start_Flight",
        country = "Russia",
        task = "CAS",
        placement = {
            airbaseName = "Kutaisi",
            startType = "takeoff_hot",
            heading = 90
        },
        units = {{
            unitType = "Su-25T",
            name = "Red_Leader",
            groundSpot = 1
        }},
        route = {{
            type = "Turning Point",
            alt = 2000,     -- Feet
            speed = 200,    -- knots
            offsetX = 15,   -- 15nm East
            offsetY = 5     -- 5nm North
        }, {
            type = "landing",
            airbaseName = "Kutaisi"
        }}
    }
}

-- ==============================================================================
-- MAIN ORCHESTRATION ENGINE INJECTION
-- ==============================================================================

function startDynamicTheatre()
    -- Initialize red coalition units
    if RedUnitManifest then
        local redUnits = MissionDirector.new(RedUnitManifest)
        redUnits:startEngineLoop()
    end

    -- Initialize blue coalition units
    if BlueUnitManifest then
        local blueUnits = MissionDirector.new(BlueUnitManifest)
        blueUnits:startEngineLoop()
    end
end

-- Delay processing initialization execution by 3 seconds
timer.scheduleFunction(startDynamicTheatre, {}, timer.getTime() + 3.0)
