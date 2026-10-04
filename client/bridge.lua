CB = {}

function CB.Notify(msg, kind, title)
    kind = kind or 'inform'
    local n = Detect.Notify
    if n == 'qb' then
        TriggerEvent('QBCore:Notify', msg, kind == 'inform' and 'primary' or kind)
    elseif n == 'esx' then
        TriggerEvent('esx:showNotification', msg)
    elseif n == 'okokNotify' then
        exports['okokNotify']:Alert(title or 'Rentals', msg, 5000, kind == 'inform' and 'info' or kind)
    else
        lib.notify({ title = title, description = msg, type = kind, duration = 5000 })
    end
end

local textShown = false
function CB.ShowText(text)
    textShown = true
    local t = Detect.TextUI
    if t == 'jg-textui' then exports['jg-textui']:DrawText(text)
    elseif t == 'okokTextUI' then exports['okokTextUI']:Open(text, 'darkblue', 'left')
    elseif t == 'qb' then exports['qb-core']:DrawText(text, 'left')
    else lib.showTextUI(text) end
end

function CB.HideText()
    if not textShown then return end
    textShown = false
    local t = Detect.TextUI
    if t == 'jg-textui' then exports['jg-textui']:HideText()
    elseif t == 'okokTextUI' then exports['okokTextUI']:Close()
    elseif t == 'qb' then exports['qb-core']:HideText()
    else lib.hideTextUI() end
end

function CB.SetFuel(veh, level)
    level = level or 100.0
    local f = Detect.Fuel
    if f == 'ox_fuel' then
        Entity(veh).state:set('fuel', level, true)
    elseif f == 'LegacyFuel' or f == 'ps-fuel' or f == 'lj-fuel' or f == 'cdn-fuel' or f == 'okokGasStation' then
        pcall(function() exports[f]:SetFuel(veh, level) end)
    end
    SetVehicleFuelLevel(veh, level + 0.0)
end

function CB.GiveKeys(veh, plate)
    local k = Detect.Keys
    pcall(function()
        if k == 'qb-vehiclekeys' or k == 'qbx_vehiclekeys' then TriggerEvent('vehiclekeys:client:SetOwner', plate)
        elseif k == 'MrNewbVehicleKeys' then exports.MrNewbVehicleKeys:GiveKeys(veh)
        elseif k == 'wasabi_carlock' then exports.wasabi_carlock:GiveKey(plate)
        elseif k == 'Renewed-Vehiclekeys' then exports['Renewed-Vehiclekeys']:addKey(plate)
        elseif k == 'qs-vehiclekeys' then exports['qs-vehiclekeys']:GiveKeys(plate, GetDisplayNameFromVehicleModel(GetEntityModel(veh)), true) end
    end)
end

local function targetName()
    local t = Detect.Target
    if t == 'ox_target' or t == 'qb-target' then return t end
    return nil
end
CB.HasTarget = function() return targetName() ~= nil end

function CB.TargetEntity(entity, opts)
    local t = targetName()
    if t == 'ox_target' then
        local list = {}
        for _, o in ipairs(opts) do
            list[#list + 1] = { name = o.name, icon = o.icon, label = o.label, distance = o.distance or 2.5, onSelect = o.action }
        end
        exports.ox_target:addLocalEntity(entity, list)
    elseif t == 'qb-target' then
        local list = {}
        for _, o in ipairs(opts) do list[#list + 1] = { icon = o.icon, label = o.label, action = o.action } end
        exports['qb-target']:AddTargetEntity(entity, { options = list, distance = (opts[1] and opts[1].distance) or 2.5 })
    end
end

function CB.RemoveTargetEntity(entity, names)
    local t = targetName()
    if t == 'ox_target' then pcall(function() exports.ox_target:removeLocalEntity(entity, names) end)
    elseif t == 'qb-target' then pcall(function() exports['qb-target']:RemoveTargetEntity(entity) end) end
end

function CB.TargetZone(name, coords, radius, opts)
    local t = targetName()
    if t == 'ox_target' then
        local list = {}
        for _, o in ipairs(opts) do
            list[#list + 1] = { name = o.name, icon = o.icon, label = o.label, distance = o.distance or 2.5, onSelect = o.action }
        end
        return exports.ox_target:addSphereZone({ coords = coords, radius = radius, options = list })
    elseif t == 'qb-target' then
        local list = {}
        for _, o in ipairs(opts) do list[#list + 1] = { icon = o.icon, label = o.label, action = o.action } end
        exports['qb-target']:AddCircleZone(name, coords, radius, { name = name, useZ = true, debugPoly = false },
            { options = list, distance = (opts[1] and opts[1].distance) or 2.5 })
        return name
    end
end

function CB.RemoveZone(id)
    local t = targetName()
    if not id then return end
    if t == 'ox_target' then pcall(function() exports.ox_target:removeZone(id) end)
    elseif t == 'qb-target' then pcall(function() exports['qb-target']:RemoveZone(id) end) end
end
