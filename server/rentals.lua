local rentals = {}
local busy = {}

local function fmt(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    return '$' .. s:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
end

local function log(title, fields)
    local url = GetConvar('vexxd_rentals_webhook', '')
    if url == '' then return end
    PerformHttpRequest(url, function() end, 'POST', json.encode({
        username = 'vexxd_rentals',
        embeds = { { title = title, color = 0xef4444, fields = fields, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ') } },
    }), { ['Content-Type'] = 'application/json' })
end

local function vec(c) return vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0) end

local function near(src, c, range)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - vec(c)) <= range
end

local function entityOf(r)
    if not r or not r.netId then return nil end
    local ent = NetworkGetEntityFromNetworkId(r.netId)
    if ent and ent ~= 0 and DoesEntityExist(ent) then return ent end
    return nil
end

local function remove(ent)
    if not ent or not DoesEntityExist(ent) then return end
    pcall(function() Entity(ent).state:set('persisted', nil, true) end)
    if Detect.Framework == 'qbx' then
        pcall(function() exports.qbx_core:DeleteVehicle(ent) end)
    end
    if DoesEntityExist(ent) then DeleteEntity(ent) end
end

local function clamp(v) return math.max(0.0, math.min(1000.0, tonumber(v) or 0.0)) end

function Condition(ent)
    return math.floor((clamp(GetVehicleBodyHealth(ent)) + clamp(GetVehicleEngineHealth(ent))) / 20 + 0.5)
end

function Refund(price, condition)
    local s = Store.settings
    local most = price * (100 - s.fee) / 100
    if condition >= s.fullAbove then return math.floor(most) end
    if condition <= s.noneBelow then return 0 end
    return math.floor(most * (condition - s.noneBelow) / (s.fullAbove - s.noneBelow))
end

local function hasLicence(src, v)
    if v.licence == '' or not Detect.Dmv then return true end
    local ok, has = pcall(function() return exports.vexxd_dmv:HasLicence(src, v.licence) end)
    return not ok or has == true
end

local function payPending(src)
    local ident = Bridge.GetIdentifier(src)
    if not ident then return end
    local amount = MySQL.scalar.await('SELECT `amount` FROM `vexxd_rentals_refunds` WHERE `identifier` = ?', { ident })
    if not amount then return end
    MySQL.query.await('DELETE FROM `vexxd_rentals_refunds` WHERE `identifier` = ?', { ident })
    if amount > 0 and Bridge.AddMoney(src, Store.settings.account, amount, 'rental-refund') then
        TriggerClientEvent('vexxd_rentals:client:notify', src, ('Your last rental was collected and %s of the deposit was refunded.'):format(fmt(amount)), 'success')
    end
end

local function rentalView(src, r)
    if not r then return nil end
    local ent = entityOf(r)
    local out = { label = r.label, model = r.model, price = r.price, plate = r.plate, minutes = math.floor((os.time() - r.at) / 60), exists = ent ~= nil, near = false }
    if ent then
        out.condition = Condition(ent)
        out.refund = Refund(r.price, out.condition)
        local pos = GetEntityCoords(ent)
        for _, l in ipairs(Store.data.locations) do
            if #(pos - vec(l.coords)) <= Store.settings.returnRange then out.near = true break end
        end
    end
    return out
end

local function view(src, loc, msg)
    local s = Store.settings
    local vehicles = {}
    for _, v in ipairs(Store.Offered(loc)) do
        vehicles[#vehicles + 1] = { id = v.id, label = v.label, model = v.model, category = v.category, price = v.price, image = v.image,
            licence = v.licence, licenceOk = hasLicence(src, v) }
    end
    return { ok = true, msg = msg, name = Bridge.GetName(src), money = Bridge.GetMoney(src, s.account), settings = s,
        location = { id = loc.id, label = loc.label, bays = #loc.spawns }, vehicles = vehicles, rental = rentalView(src, rentals[src]) }
end

local function guard(src, locId)
    local loc = type(locId) == 'string' and Store.Location(locId)
    if not Bridge.GetIdentifier(src) then return nil, 'Your character is still loading.' end
    if not loc then return nil, 'This rental desk is closed.' end
    if not near(src, loc.coords, 15.0) then return nil, 'You need to be at the rental desk.' end
    return loc
end

local function lock(src)
    if busy[src] then return false end
    busy[src] = true
    return true
end

lib.callback.register('vexxd_rentals:server:open', function(src, locId)
    while not Ready do Wait(100) end
    local loc, err = guard(src, locId)
    if not loc then return { ok = false, msg = err } end
    payPending(src)
    return view(src, loc)
end)

lib.callback.register('vexxd_rentals:server:rent', function(src, locId, vehId)
    if not lock(src) then return { ok = false } end
    local function done(...) busy[src] = nil return ... end

    local loc, err = guard(src, locId)
    if not loc then return done({ ok = false, msg = err }) end
    if rentals[src] then return done({ ok = false, msg = 'Hand your current rental back first.' }) end
    if #loc.spawns == 0 then return done({ ok = false, msg = 'This desk has no parking bays set up yet.' }) end
    local v
    for _, o in ipairs(Store.Offered(loc)) do
        if o.id == vehId then v = o break end
    end
    if not v then return done({ ok = false, msg = 'That vehicle is not offered here.' }) end
    if not hasLicence(src, v) then return done({ ok = false, msg = 'You need the right licence to rent that.' }) end
    local s = Store.settings
    if v.price > 0 and not Bridge.RemoveMoney(src, s.account, v.price, 'rental-deposit') then
        return done({ ok = false, msg = ('The deposit is %s.'):format(fmt(v.price)) })
    end

    local r = { vehicle = v.id, label = v.label, model = v.model, price = v.price, at = os.time(), location = loc.id,
        plate = ('%s%04d'):format(s.plate, math.random(0, 9999)), ident = Bridge.GetIdentifier(src) }
    rentals[src] = r
    SetTimeout(25000, function()
        if rentals[src] == r and not r.netId then
            rentals[src] = nil
            Bridge.AddMoney(src, s.account, r.price, 'rental-refund')
            TriggerClientEvent('vexxd_rentals:client:notify', src, 'The vehicle could not be delivered. Your deposit was refunded.', 'error')
        end
    end)
    return done({ ok = true, model = v.model, label = v.label, plate = r.plate, price = v.price, warp = s.warp })
end)

RegisterNetEvent('vexxd_rentals:server:failed', function()
    local src = source
    local r = rentals[src]
    if not r or r.netId then return end
    rentals[src] = nil
    Bridge.AddMoney(src, Store.settings.account, r.price, 'rental-refund')
    TriggerClientEvent('vexxd_rentals:client:notify', src, 'The vehicle could not be delivered. Your deposit was refunded.', 'error')
end)

lib.callback.register('vexxd_rentals:server:vehicle', function(src, netId)
    local r = rentals[src]
    if not r or r.netId then return false end
    local ent = 0
    for _ = 1, 30 do
        ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
        if ent ~= 0 and DoesEntityExist(ent) then break end
        Wait(100)
    end
    if rentals[src] ~= r or r.netId then return false end
    if ent == 0 or not DoesEntityExist(ent) or NetworkGetEntityOwner(ent) ~= src or GetEntityModel(ent) ~= joaat(r.model) then
        rentals[src] = nil
        Bridge.AddMoney(src, Store.settings.account, r.price, 'rental-refund')
        TriggerClientEvent('vexxd_rentals:client:notify', src, 'The vehicle could not be delivered. Your deposit was refunded.', 'error')
        return false
    end
    r.netId = tonumber(netId)
    Entity(ent).state:set('vexxdRental', true, true)
    Bridge.GiveKeys(src, ent, r.plate)
    log('Vehicle rented', {
        { name = 'Player', value = ('%s (%s)'):format(Bridge.GetName(src), r.ident) },
        { name = 'Vehicle', value = ('%s [%s]'):format(r.label, r.plate), inline = true },
        { name = 'Deposit', value = fmt(r.price), inline = true },
    })
    return true
end)

lib.callback.register('vexxd_rentals:server:return', function(src, locId)
    if not lock(src) then return { ok = false } end
    local function done(...) busy[src] = nil return ... end

    local loc, err = guard(src, locId)
    if not loc then return done({ ok = false, msg = err }) end
    local r = rentals[src]
    if not r then return done({ ok = false, msg = 'You have no rental out.' }) end
    local ent = entityOf(r)
    if not ent then return done({ ok = false, msg = 'Your rental can\'t be found. Report it lost to close the rental.' }) end
    if #(GetEntityCoords(ent) - vec(loc.coords)) > Store.settings.returnRange then
        return done({ ok = false, msg = 'Park the rental closer to the desk first.' })
    end

    local condition = Condition(ent)
    local refund = Refund(r.price, condition)
    rentals[src] = nil
    remove(ent)
    if refund > 0 then Bridge.AddMoney(src, Store.settings.account, refund, 'rental-refund') end
    TriggerClientEvent('vexxd_rentals:client:ended', src)
    log('Vehicle returned', {
        { name = 'Player', value = ('%s (%s)'):format(Bridge.GetName(src), r.ident) },
        { name = 'Vehicle', value = ('%s [%s]'):format(r.label, r.plate), inline = true },
        { name = 'Condition', value = condition .. '%', inline = true },
        { name = 'Refund', value = ('%s of %s'):format(fmt(refund), fmt(r.price)), inline = true },
    })
    local out = view(src, loc)
    out.receipt = { label = r.label, plate = r.plate, price = r.price, condition = condition, refund = refund, minutes = math.floor((os.time() - r.at) / 60) }
    return done(out)
end)

lib.callback.register('vexxd_rentals:server:lost', function(src, locId)
    if not lock(src) then return { ok = false } end
    local function done(...) busy[src] = nil return ... end

    local loc, err = guard(src, locId)
    if not loc then return done({ ok = false, msg = err }) end
    local r = rentals[src]
    if not r then return done({ ok = false, msg = 'You have no rental out.' }) end
    rentals[src] = nil
    remove(entityOf(r))
    TriggerClientEvent('vexxd_rentals:client:ended', src)
    return done(view(src, loc, 'Rental closed. The deposit was kept.'))
end)

RegisterNetEvent('vexxd_rentals:server:loaded', function()
    local src = source
    while not Ready do Wait(100) end
    payPending(src)
end)

local function collect(src, online)
    local r = rentals[src]
    rentals[src] = nil
    busy[src] = nil
    local ent = entityOf(r)
    if not r or not ent then return end
    local refund = Refund(r.price, Condition(ent))
    remove(ent)
    if refund <= 0 then return end
    if online and Bridge.AddMoney(src, Store.settings.account, refund, 'rental-refund') then return end
    MySQL.query.await([[INSERT INTO `vexxd_rentals_refunds` (`identifier`, `amount`) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE `amount` = `amount` + VALUES(`amount`)]], { r.ident, refund })
end

AddEventHandler('playerDropped', function()
    collect(source, false)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    local list = {}
    for src in pairs(rentals) do list[#list + 1] = src end
    for _, src in ipairs(list) do collect(src, true) end
end)

exports('HasRental', function(src)
    return rentals[src] ~= nil
end)

exports('GetRental', function(src)
    local r = rentals[src]
    return r and { vehicle = r.vehicle, model = r.model, plate = r.plate, price = r.price, netId = r.netId } or nil
end)
