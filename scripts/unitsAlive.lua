local function isAlive(groupName)
    local g = Group.getByName(groupName)
    if not g or g == nil then
        return false
    end
    local gs = g:getSize()
    if gs < 1 then
        return false
    end

    -- search for active units in the group
    for i = 1, gs do
        u = g:getUnit(i)
        if u and u:isActive() then
            return true
        end
    end
    return false
end

local start = 1
local stop = 3

for i = start, stop do
    if isAlive('Random-' .. i) then
        return false
    end
end

return true
