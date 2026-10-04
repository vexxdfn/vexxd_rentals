Ready = false

function Broadcast(target)
    TriggerClientEvent('vexxd_rentals:client:world', target or -1, Store.World())
end

CreateThread(function()
    local deadline = GetGameTimer() + 20000
    local function frameworkUp()
        for _, r in ipairs({ 'qbx_core', 'qb-core', 'es_extended' }) do
            if GetResourceState(r) == 'started' then return true end
        end
        return Config.Framework ~= 'auto'
    end
    while not frameworkUp() and GetGameTimer() < deadline do Wait(250) end
    Detect.run()
    Bridge.Init()
    Store.Init()
    Ready = true
    Broadcast()
end)

lib.callback.register('vexxd_rentals:server:world', function()
    while not Ready do Wait(100) end
    return Store.World()
end)

RegisterCommand(Config.Commands.admin, function(src)
    if src == 0 then return end
    if not IsRentalAdmin(src) then
        return TriggerClientEvent('vexxd_rentals:client:notify', src, 'You don\'t have permission.', 'error')
    end
    TriggerClientEvent('vexxd_rentals:client:admin', src)
end, false)
