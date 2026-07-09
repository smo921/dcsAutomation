-- wave_patrol.lua
SectorManifest = {
    ["red"] = {
        {
            enabled = true,
            triggerType = "WAVE_PATROL",
            groupName = "Patrol_Wave_1",
            country = "Russia",
            units = {"T-72B"},
            placement = {
                heading = 0,
                offsetX = 0,
                offsetY = 0
            },
            route = {
                { type="Turning Point", alt=0, speed=45, offsetX=5, offsetY=0 }
            }
        } 
    }
}
