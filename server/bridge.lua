Bridge = {}

function Bridge.GetIdentifier() return nil end
function Bridge.GetName(src) return GetPlayerName(src) or 'Unknown' end
function Bridge.GetMoney() return 0 end
function Bridge.RemoveMoney() return false end
function Bridge.AddMoney() return false end
function Bridge.IsAdmin() return false end

function Bridge.Init()
    local fw = Detect.Framework
    if fw == 'qb' or fw == 'qbx' then
        local Core
        pcall(function() Core = exports['qb-core']:GetCoreObject() end)

        local function getPlayer(src)
            if fw == 'qbx' then
                local ok, p = pcall(function() return exports.qbx_core:GetPlayer(src) end)
                if ok and p then return p end
            end
            return Core and Core.Functions.GetPlayer(src) or nil
        end

        function Bridge.GetIdentifier(src)
            local p = getPlayer(src)
            return p and p.PlayerData.citizenid or nil
        end

        function Bridge.GetName(src)
            local p = getPlayer(src)
            local ci = p and p.PlayerData.charinfo
            if ci then
                local name = ((ci.firstname or '') .. ' ' .. (ci.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
                if name ~= '' then return name end
            end
            return GetPlayerName(src) or 'Unknown'
        end

        function Bridge.GetMoney(src, account)
            local p = getPlayer(src)
            return p and p.PlayerData.money and p.PlayerData.money[account] or 0
        end

        function Bridge.RemoveMoney(src, account, amount, reason)
            local p = getPlayer(src)
            if not p or Bridge.GetMoney(src, account) < amount then return false end
            return p.Functions.RemoveMoney(account, amount, reason) and true or false
        end

        function Bridge.AddMoney(src, account, amount, reason)
            local p = getPlayer(src)
            if not p then return false end
            p.Functions.AddMoney(account, amount, reason)
            return true
        end

        function Bridge.IsAdmin(src)
            if fw == 'qbx' then
                local ok, has = pcall(function() return exports.qbx_core:HasPermission(src, 'admin') end)
                if ok and has then return true end
            end
            if Core and Core.Functions.HasPermission then
                local ok, has = pcall(Core.Functions.HasPermission, src, 'admin')
                if ok and has then return true end
            end
            return IsPlayerAceAllowed(src, 'command')
        end

    elseif fw == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local function getPlayer(src) return ESX.GetPlayerFromId(src) end
        local function acct(account) return account == 'cash' and 'money' or account end

        function Bridge.GetIdentifier(src)
            local x = getPlayer(src)
            return x and x.identifier or nil
        end

        function Bridge.GetName(src)
            local x = getPlayer(src)
            local name = x and x.getName and x.getName()
            if name and name ~= '' then return name end
            return GetPlayerName(src) or 'Unknown'
        end

        function Bridge.GetMoney(src, account)
            local x = getPlayer(src)
            local a = x and x.getAccount(acct(account))
            return a and a.money or 0
        end

        function Bridge.RemoveMoney(src, account, amount, reason)
            local x = getPlayer(src)
            if not x or Bridge.GetMoney(src, account) < amount then return false end
            x.removeAccountMoney(acct(account), amount, reason)
            return true
        end

        function Bridge.AddMoney(src, account, amount, reason)
            local x = getPlayer(src)
            if not x then return false end
            x.addAccountMoney(acct(account), amount, reason)
            return true
        end

        function Bridge.IsAdmin(src)
            local x = getPlayer(src)
            local group = x and x.getGroup and x.getGroup()
            return group == 'admin' or group == 'superadmin'
        end
    else
        print('^1[vexxd_rentals] No supported framework found (qbx_core, qb-core or es_extended).^0')
    end
end

-- Keys that have to be handed over from the server. The one matching your server is picked once at start (Config.Keys).
-- Every other keys script is handled on the client in client/bridge.lua.
local KEYS = {
    qbx_vehiclekeys = function(src, vehicle)
        exports.qbx_vehiclekeys:GiveKeys(src, vehicle, true)
    end,
    ['qb-vehiclekeys'] = function(src, _, plate)
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
    end,
}

function Bridge.GiveKeys(src, vehicle, plate)
    local give = KEYS[Detect.Keys]
    if not give then return false end
    local ok, err = pcall(give, src, vehicle, plate)
    if not ok then print(('^1[vexxd_rentals] giving keys (%s) failed: %s^0'):format(tostring(Detect.Keys), tostring(err))) end
    return ok
end

function IsRentalAdmin(src)
    if IsPlayerAceAllowed(src, Config.AdminAce) then return true end
    return Bridge.IsAdmin(src) == true
end
