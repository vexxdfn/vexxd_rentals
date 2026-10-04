Detect = {}

local function started(res) return GetResourceState(res) == 'started' or GetResourceState(res) == 'starting' end

local CHOICES = {
    Framework = { { 'qbx_core', 'qbx' }, { 'qb-core', 'qb' }, { 'es_extended', 'esx' } },
    Fuel = { { 'ox_fuel' }, { 'LegacyFuel' }, { 'ps-fuel' }, { 'lj-fuel' }, { 'cdn-fuel' }, { 'okokGasStation' } },
    Keys = { { 'qbx_vehiclekeys' }, { 'qb-vehiclekeys' }, { 'MrNewbVehicleKeys' }, { 'wasabi_carlock' }, { 'Renewed-Vehiclekeys' }, { 'qs-vehiclekeys' } },
    TextUI = { { 'jg-textui' }, { 'okokTextUI' } },
    Target = { { 'ox_target' }, { 'qb-target' } },
}

local FALLBACK = { Fuel = 'native', Keys = 'none', Notify = 'ox_lib', TextUI = 'ox_lib', Target = 'none' }

local function pick(kind)
    local forced = Config[kind]
    if forced and forced ~= 'auto' then return forced, false end
    for _, c in ipairs(CHOICES[kind] or {}) do
        if started(c[1]) then return c[2] or c[1], true end
    end
    return FALLBACK[kind], true
end

function Detect.run()
    Detect.auto = {}
    for _, kind in ipairs({ 'Framework', 'Fuel', 'Keys', 'Notify', 'TextUI', 'Target' }) do
        Detect[kind], Detect.auto[kind] = pick(kind)
    end
    if Config.Notify == nil or Config.Notify == 'auto' then
        if started('okokNotify') then Detect.Notify = 'okokNotify'
        elseif Detect.Framework == 'qb' then Detect.Notify = 'qb'
        elseif Detect.Framework == 'esx' then Detect.Notify = 'esx'
        else Detect.Notify = 'ox_lib' end
    end
    Detect.Dmv = started('vexxd_dmv')
    return Detect
end

Detect.Dmv = started('vexxd_dmv')

function Detect.info()
    local out = { auto = {} }
    for _, kind in ipairs({ 'Framework', 'Fuel', 'Keys', 'Notify', 'TextUI', 'Target' }) do
        out[kind] = Detect[kind]
        out.auto[kind] = Detect.auto[kind]
    end
    return out
end

Detect.run()

CreateThread(function()
    Wait(3000)
    Detect.run()
end)
