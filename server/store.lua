Store = { data = {}, settings = {} }

local KINDS = { 'vehicles', 'locations' }
local CATEGORIES = { car = true, bike = true, bicycle = true, truck = true, boat = true }

local function num(v, d, lo, hi)
    v = tonumber(v)
    if not v or v ~= v then return d end
    if lo and v < lo then v = lo end
    if hi and v > hi then v = hi end
    return v
end
local function int(v, d, lo, hi) return math.floor(num(v, d, lo, hi)) end

local function str(v, d, max)
    if type(v) ~= 'string' then return d end
    v = v:gsub('[%c<>]', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if v == '' then return d end
    if max and #v > max then v = v:sub(1, max) end
    return v
end

local function slug(v)
    v = str(v, nil, 50)
    if not v or not v:match('^[%w_%-]+$') then return nil end
    return v:lower()
end

local function coords(v)
    if type(v) ~= 'table' then return nil end
    local x, y, z = tonumber(v.x), tonumber(v.y), tonumber(v.z)
    if not x or not y or not z or (x == 0 and y == 0) then return nil end
    return { x = x, y = y, z = z, w = num(v.w, 0.0) }
end

local function url(v)
    v = str(v, '', 300)
    if v ~= '' and not v:match('^https?://[%w%-%._~:/%?#%[%]@!%$&%(%)%*%+,;=%%]+$') then return '' end
    return v
end

local SANITIZE = {}

function SANITIZE.vehicles(v)
    local id = slug(v.id)
    local model = slug(v.model)
    if not id or not model then return nil end
    return {
        id = id, label = str(v.label, model, 40), model = model, category = CATEGORIES[v.category] and v.category or 'car',
        price = int(v.price, 250, 0, 10000000), licence = slug(v.licence) or '', image = url(v.image), enabled = v.enabled ~= false,
    }
end

function SANITIZE.locations(v, ctx)
    local id = slug(v.id)
    local pos = coords(v.coords)
    if not id or not pos then return nil end
    local spawns, offered, seen = {}, {}, {}
    for _, s in ipairs(type(v.spawns) == 'table' and v.spawns or {}) do
        local c = coords(s)
        if c and #spawns < 12 then spawns[#spawns + 1] = c end
    end
    for _, vid in ipairs(type(v.vehicles) == 'table' and v.vehicles or {}) do
        vid = slug(vid)
        if vid and ctx.vehicles[vid] and not seen[vid] then
            seen[vid] = true
            offered[#offered + 1] = vid
        end
    end
    return {
        id = id, label = str(v.label, 'Vehicle Rental', 60), coords = pos, model = slug(v.model) or 'a_m_y_business_02', ped = v.ped ~= false,
        blip = v.blip ~= false, sprite = int(v.sprite, 225, 0, 900), colour = int(v.colour, 1, 0, 85),
        spawns = spawns, vehicles = offered,
    }
end

function Store.Sanitize(kind, list)
    local fn = SANITIZE[kind]
    if not fn or type(list) ~= 'table' then return nil end
    local ctx = { vehicles = {} }
    for _, c in ipairs(Store.data.vehicles or {}) do ctx.vehicles[c.id] = true end
    local out, seen = {}, {}
    for _, v in ipairs(list) do
        local clean = type(v) == 'table' and fn(v, ctx) or nil
        if clean and not seen[clean.id] and #out < 300 then
            seen[clean.id] = true
            out[#out + 1] = clean
        end
    end
    return out
end

function Store.SanitizeSettings(v)
    local d = Config.Settings
    v = type(v) == 'table' and v or {}
    local full = int(v.fullAbove, d.fullAbove, 1, 100)
    local images = type(v.images) == 'string' and v.images:match('^https?://[%w%-%._~:/%?#@!%$&%*%+,;=%%]+$') and v.images:sub(1, 200) or d.images
    local plate = type(v.plate) == 'string' and v.plate:upper():gsub('[^%u%d]', ''):sub(1, 4) or d.plate
    if plate == '' then plate = d.plate end
    return {
        accent = type(v.accent) == 'string' and v.accent:match('^#%x%x%x%x%x%x$') and v.accent:lower() or d.accent,
        title = str(v.title, d.title, 50),
        account = (v.account == 'cash' or v.account == 'bank') and v.account or d.account,
        fullAbove = full, noneBelow = int(v.noneBelow, d.noneBelow, 0, full - 1),
        fee = int(v.fee, d.fee, 0, 100), returnRange = int(v.returnRange, d.returnRange, 5, 200),
        warp = (v.warp == nil and d.warp) or v.warp == true, plate = plate, images = images,
    }
end

local function put(kind, data)
    MySQL.query.await('INSERT INTO `vexxd_rentals` (`kind`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)', { kind, json.encode(data) })
end

function Store.Init()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `vexxd_rentals` (
        `kind` VARCHAR(16) NOT NULL, `data` LONGTEXT NOT NULL, PRIMARY KEY (`kind`))]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `vexxd_rentals_refunds` (
        `identifier` VARCHAR(64) NOT NULL, `amount` INT NOT NULL DEFAULT 0, PRIMARY KEY (`identifier`))]])
    local saved = {}
    for _, r in ipairs(MySQL.query.await('SELECT `kind`, `data` FROM `vexxd_rentals`') or {}) do
        local ok, data = pcall(json.decode, r.data)
        if ok and type(data) == 'table' then saved[r.kind] = data end
    end
    Store.settings = Store.SanitizeSettings(saved.settings)
    Store.data = {}
    for _, kind in ipairs(KINDS) do
        Store.data[kind] = Store.Sanitize(kind, saved[kind] or Defaults[kind] or {}) or {}
        if not saved[kind] then put(kind, Store.data[kind]) end
    end
end

function Store.Save(kind, list)
    Store.data[kind] = list
    put(kind, list)
    if kind == 'vehicles' then
        Store.data.locations = Store.Sanitize('locations', Store.data.locations) or {}
        put('locations', Store.data.locations)
    end
end

function Store.SaveSettings(s)
    Store.settings = s
    put('settings', s)
end

function Store.Vehicle(id)
    for _, v in ipairs(Store.data.vehicles) do
        if v.id == id then return v end
    end
    return nil
end

function Store.Location(id)
    for _, l in ipairs(Store.data.locations) do
        if l.id == id then return l end
    end
    return nil
end

function Store.Offered(loc)
    local out = {}
    if #loc.vehicles == 0 then
        for _, v in ipairs(Store.data.vehicles) do
            if v.enabled then out[#out + 1] = v end
        end
    else
        for _, id in ipairs(loc.vehicles) do
            local v = Store.Vehicle(id)
            if v and v.enabled then out[#out + 1] = v end
        end
    end
    return out
end

function Store.World()
    return { locations = Store.data.locations, settings = Store.settings }
end
