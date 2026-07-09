-- radar_point_defense.lua
SectorManifest = {
    ["red"] = {
        {
            enabled = true,
            triggerType = "RADAR",
            groupName = "SAM_Cluster",
            country = "Russia",
            units = {"S-300V"},
            placement = {
                heading = 0,
                offsetX = 50,
                offsetY = 0
            },
            pointDefense = {
                units = {"S-300V"},
                minRadius = 5000,
                maxRadius = 15000
            }
        }
    }
}
