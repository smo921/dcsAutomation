local groupName = 'AA-1'

if mist.groupIsDead(groupName) == true then
    mist.respawnGroup(groupName, true)
else
    local g = Group.getByName(groupName)
    if g ~= nil then
        trigger.action.activateGroup(g)
    end
end