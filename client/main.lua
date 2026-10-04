World = { locations = {}, settings = {} }
State = { open = false, admin = false, location = nil }

local desks = {}
local rental = nil

function LoadModel(m)
    local hash = type(m) == 'number' and m or joaat(m)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

function SwallowPause()
    CreateThread(function()
        local ends = GetGameTimer() + 500
        while GetGameTimer() < ends do
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 322, true)
            Wait(0)
        end
    end)
end

RegisterNetEvent('vexxd_rentals:client:notify', function(msg, kind)
    CB.Notify(msg, kind)
end)

local function busy()
    return State.open or State.admin
end

local CLASSES = { [0] = 'Compact', 'Sedan', 'SUV', 'Coupe', 'Muscle', 'Sports Classic', 'Sports', 'Super', 'Motorcycle', 'Off-road', 'Industrial', 'Utility', 'Van', 'Cycle', 'Boat' }

local function describe(view)
    local mph = 2.236936
    for _, v in ipairs(view.vehicles or {}) do
        local hash = joaat(v.model)
        v.valid = IsModelInCdimage(hash) and IsModelAVehicle(hash)
        if v.valid then
            v.class = CLASSES[GetVehicleClassFromName(hash)] or 'Vehicle'
            v.seats = GetVehicleModelNumberOfSeats(hash)
            v.speed = math.floor(GetVehicleModelEstimatedMaxSpeed(hash) * mph + 0.5)
            v.accel = GetVehicleModelAcceleration(hash)
            v.braking = GetVehicleModelMaxBraking(hash)
            v.traction = GetVehicleModelMaxTraction(hash)
        end
    end
    return view
end

function OpenRentals(locId)
    if busy() then return end
    local data = lib.callback.await('vexxd_rentals:server:open', false, locId)
    if not data or not data.ok then return CB.Notify(data and data.msg or 'Unavailable.', 'error') end
    State.open = true
    State.location = locId
    CB.HideText()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = describe(data) })
end

local function close()
    if not State.open then return end
    State.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    SwallowPause()
end

RegisterNUICallback('close', function(_, cb)
    close()
    cb(1)
end)

local function location()
    for _, l in ipairs(World.locations or {}) do
        if l.id == State.location then return l end
    end
    return nil
end

local function freeBay(loc)
    for _, s in ipairs(loc and loc.spawns or {}) do
        if not IsAnyVehicleNearPoint(s.x + 0.0, s.y + 0.0, s.z + 0.0, 2.5) then return s end
    end
    return nil
end

local function clearRental()
    if rental and rental.blip then RemoveBlip(rental.blip) end
    rental = nil
end

RegisterNetEvent('vexxd_rentals:client:ended', clearRental)

local function deliver(data, bay)
    local hash = LoadModel(data.model)
    if not hash then
        TriggerServerEvent('vexxd_rentals:server:failed')
        return
    end
    local veh = CreateVehicle(hash, bay.x + 0.0, bay.y + 0.0, bay.z + 0.0, (bay.w or 0.0) + 0.0, true, false)
    SetModelAsNoLongerNeeded(hash)
    local deadline = GetGameTimer() + 3000
    while not NetworkGetEntityIsNetworked(veh) and GetGameTimer() < deadline do Wait(0) end
    if not DoesEntityExist(veh) or not NetworkGetEntityIsNetworked(veh) then
        if DoesEntityExist(veh) then DeleteEntity(veh) end
        TriggerServerEvent('vexxd_rentals:server:failed')
        return
    end
    SetVehicleNumberPlateText(veh, data.plate)
    SetVehicleOnGroundProperly(veh)
    SetVehicleDirtLevel(veh, 0.0)
    SetEntityAsMissionEntity(veh, true, true)
    CB.SetFuel(veh, 100.0)
    if not lib.callback.await('vexxd_rentals:server:vehicle', false, NetworkGetNetworkIdFromEntity(veh)) then
        if DoesEntityExist(veh) then DeleteEntity(veh) end
        return
    end
    CB.GiveKeys(veh, data.plate)
    if data.warp then
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        SetVehicleEngineOn(veh, true, true, false)
    end

    clearRental()
    local blip = AddBlipForEntity(veh)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 0.75)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Your rental')
    EndTextCommandSetBlipName(blip)
    local mine = { veh = veh, blip = blip }
    rental = mine
    CB.Notify(('Your %s is ready. Bring it back to any rental desk in good shape to get your deposit back.'):format(data.label), 'success')

    CreateThread(function()
        while rental == mine do
            Wait(3000)
            if rental == mine and not DoesEntityExist(veh) then clearRental() end
        end
    end)
end

RegisterNUICallback('rent', function(body, cb)
    local loc = location()
    local bay = freeBay(loc)
    if loc and #loc.spawns > 0 and not bay then
        CB.Notify('The parking bays are blocked. Wait for them to clear.', 'error')
        return cb({ ok = false })
    end
    local data = lib.callback.await('vexxd_rentals:server:rent', false, State.location, body.vehicle)
    if not data or not data.ok then
        if data and data.msg then CB.Notify(data.msg, 'error') end
        return cb({ ok = false })
    end
    cb({ ok = true })
    close()
    deliver(data, bay)
end)

local function relay(name, server)
    RegisterNUICallback(name, function(_, cb)
        local data = lib.callback.await(server, false, State.location)
        if data and data.msg then CB.Notify(data.msg, data.ok and 'success' or 'error') end
        cb(data and data.ok and describe(data) or { ok = false })
    end)
end

relay('return', 'vexxd_rentals:server:return')
relay('lost', 'vexxd_rentals:server:lost')
relay('refresh', 'vexxd_rentals:server:open')

local function clearDesks()
    for _, d in ipairs(desks) do
        d.gone = true
        if d.blip then RemoveBlip(d.blip) end
        if d.zone then CB.RemoveZone(d.zone) end
        if d.ped then
            if CB.HasTarget() then CB.RemoveTargetEntity(d.ped, { 'vexxd_rentals_open' }) end
            if DoesEntityExist(d.ped) then DeleteEntity(d.ped) end
        end
    end
    desks = {}
end

local function option(def)
    return { name = 'vexxd_rentals_open', icon = 'fa-solid fa-car-side', label = 'Vehicle rental', distance = 2.5, action = function() OpenRentals(def.id) end }
end

local function spawnPed(d)
    local c = d.def.coords
    local hash = LoadModel(d.def.model)
    if not hash or d.gone then return end
    local ped = CreatePed(4, hash, c.x, c.y, c.z - 1.0, c.w or 0.0, false, true)
    SetModelAsNoLongerNeeded(hash)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    d.ped = ped
    if CB.HasTarget() then CB.TargetEntity(ped, { option(d.def) }) end
end

local function apply(data)
    if type(data) ~= 'table' then return end
    World = data
    World.settings = World.settings or {}
    clearDesks()
    for _, def in ipairs(World.locations or {}) do
        local d = { def = def }
        local c = def.coords
        if def.blip then
            local b = AddBlipForCoord(c.x, c.y, c.z)
            SetBlipSprite(b, def.sprite)
            SetBlipColour(b, def.colour)
            SetBlipScale(b, 0.8)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(def.label)
            EndTextCommandSetBlipName(b)
            d.blip = b
        end
        if CB.HasTarget() and not def.ped then
            d.zone = CB.TargetZone('vexxd_rentals_' .. def.id, vector3(c.x, c.y, c.z), 1.2, { option(def) })
        end
        desks[#desks + 1] = d
    end
end

RegisterNetEvent('vexxd_rentals:client:world', apply)

CreateThread(function()
    Wait(1500)
    apply(lib.callback.await('vexxd_rentals:server:world', false))
end)

local prompt = false
CreateThread(function()
    while true do
        local wait = 1500
        local pos = GetEntityCoords(PlayerPedId())
        local showing = false
        for _, d in ipairs(desks) do
            local c = d.def.coords
            local dist = #(pos - vector3(c.x, c.y, c.z))
            if d.def.ped then
                if dist < 60.0 and not d.ped and not d.loading then
                    d.loading = true
                    CreateThread(function()
                        spawnPed(d)
                        d.loading = false
                    end)
                elseif dist > 80.0 and d.ped then
                    if CB.HasTarget() then CB.RemoveTargetEntity(d.ped, { 'vexxd_rentals_open' }) end
                    if DoesEntityExist(d.ped) then DeleteEntity(d.ped) end
                    d.ped = nil
                end
            end
            if not CB.HasTarget() and dist < 2.2 and not busy() then
                showing = true
                wait = 0
                if not prompt then
                    prompt = true
                    CB.ShowText('[E] Vehicle rental')
                end
                if IsControlJustReleased(0, 38) then OpenRentals(d.def.id) end
            end
        end
        if prompt and not showing then
            prompt = false
            CB.HideText()
        end
        Wait(wait)
    end
end)

local function loaded()
    TriggerServerEvent('vexxd_rentals:server:loaded')
end
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', loaded)
RegisterNetEvent('esx:playerLoaded', loaded)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if State.open or State.admin then SetNuiFocus(false, false) end
    CB.HideText()
    clearDesks()
    clearRental()
end)
