-- zone_entry_waypoints.lua
SectorManifest = {
    ["red"] = {
        {
            enabled = true,
            triggerType = "TRIGGER_ZONE",
            groupName = "Patrol_Squad",
            country = "Russia",
            units = {"T-72B","BMP-2"},
            placement = {
                strategy="ZONE_RANDOM",
                zoneName="NORTH_STAGING",
                spawnRadius = 1
            }
        }
    }
}
