local function show(data)
    State.admin = true
    CB.HideText()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'admin', data = data })
end

local function hide()
    if not State.admin then return end
    State.admin = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'adminClose' })
    SwallowPause()
end

RegisterNetEvent('vexxd_rentals:client:admin', function()
    if State.open or State.admin then return end
    local data = lib.callback.await('vexxd_rentals:server:adminData', false)
    if not data or not data.ok then return CB.Notify(data and data.msg or 'Unavailable.', 'error') end
    show(data)
end)

local function reply(cb, data)
    if data and data.msg then CB.Notify(data.msg, data.ok and 'success' or 'error') end
    cb(data or { ok = false })
end

RegisterNUICallback('adminClose', function(_, cb)
    hide()
    cb(1)
end)

RegisterNUICallback('adminSave', function(body, cb)
    reply(cb, lib.callback.await('vexxd_rentals:server:adminSave', false, body.kind, body.list))
end)

RegisterNUICallback('adminSettings', function(body, cb)
    reply(cb, lib.callback.await('vexxd_rentals:server:adminSettings', false, body.data))
end)

local function round(v, places)
    local m = 10 ^ places
    return math.floor(v * m + 0.5) / m
end

RegisterNUICallback('adminHere', function(_, cb)
    local ped = PlayerPedId()
    local ent = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped
    local c = GetEntityCoords(ent)
    cb({ x = round(c.x, 2), y = round(c.y, 2), z = round(c.z, 2), w = round(GetEntityHeading(ent), 1) })
end)

RegisterNUICallback('adminCheck', function(body, cb)
    local hash = joaat(tostring(body.model or ''))
    cb({ valid = IsModelInCdimage(hash) and IsModelAVehicle(hash) })
end)
