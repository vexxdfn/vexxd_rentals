Config = {}

-- ============================================================
-- INTEGRATIONS
-- ============================================================
-- Leave on 'auto' and the script works out once, at start, what your server runs and uses that.
-- Set one only to force it.

Config.Framework = 'auto' -- or 'qbx', 'qb', 'esx'
Config.Fuel      = 'auto' -- or 'ox_fuel', 'LegacyFuel', 'ps-fuel', 'lj-fuel', 'cdn-fuel', 'native'
Config.Keys      = 'auto' -- or 'qbx_vehiclekeys', 'qb-vehiclekeys', 'MrNewbVehicleKeys', 'wasabi_carlock', 'Renewed-Vehiclekeys', 'qs-vehiclekeys', 'none'
Config.Notify    = 'auto' -- or 'ox_lib', 'qb', 'esx', 'okokNotify' (auto: okokNotify if running, else your framework's own, else ox_lib)
Config.TextUI    = 'auto' -- or 'ox_lib', 'jg-textui', 'okokTextUI', 'qb'
Config.Target    = 'auto' -- or 'ox_target', 'qb-target', 'none'

Config.AdminAce = 'vexxd_rentals.admin' -- add_ace group.admin vexxd_rentals.admin allow

Config.Commands = {
    admin = 'rentaladmin', -- desks, vehicles and settings
}

-- Starting values. Change them in /rentaladmin > Settings.
Config.Settings = {
    accent      = '#ef4444',
    title       = 'Vehicle Rentals',
    account     = 'bank', -- deposits are taken from and refunded to 'bank' or 'cash'
    fullAbove   = 90,     -- condition % at or above this gets the full deposit back
    noneBelow   = 20,     -- condition % at or below this gets nothing back
    fee         = 0,      -- % of the deposit that is always kept, 0 = full refund possible
    returnRange = 30,     -- metres from a rental desk the vehicle has to be to hand it back
    warp        = true,   -- put the player in the driver seat when the vehicle is delivered
    plate       = 'RENT', -- plate prefix, followed by four numbers
    images      = 'https://docs.fivem.net/vehicles/%s.webp', -- %s is the model name
}

-- Discord webhook goes in server.cfg, never here:
--   set vexxd_rentals_webhook "https://discord.com/api/webhooks/..."
