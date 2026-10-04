local function payload(msg)
    return { ok = true, msg = msg, vehicles = Store.data.vehicles, locations = Store.data.locations, settings = Store.settings,
        dmv = Detect.Dmv == true }
end

lib.callback.register('vexxd_rentals:server:adminData', function(src)
    if not IsRentalAdmin(src) then return { ok = false, msg = 'You don\'t have permission.' } end
    return payload()
end)

lib.callback.register('vexxd_rentals:server:adminSave', function(src, kind, list)
    if not IsRentalAdmin(src) then return { ok = false, msg = 'You don\'t have permission.' } end
    local clean = Store.Sanitize(kind, list)
    if not clean then return { ok = false, msg = 'That could not be saved.' } end
    Store.Save(kind, clean)
    Broadcast()
    return payload('Saved.')
end)

lib.callback.register('vexxd_rentals:server:adminSettings', function(src, data)
    if not IsRentalAdmin(src) then return { ok = false, msg = 'You don\'t have permission.' } end
    Store.SaveSettings(Store.SanitizeSettings(data))
    Broadcast()
    return payload('Settings saved.')
end)
