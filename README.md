<img width="1675" height="960" alt="rentalscript4" src="https://github.com/user-attachments/assets/373ab4fb-876b-41f9-aa3e-98e97276a702" />
<img width="1838" height="983" alt="rentalscript3" src="https://github.com/user-attachments/assets/dd265189-688f-4421-b965-deb09831b438" />
<img width="1621" height="941" alt="rentalscript2" src="https://github.com/user-attachments/assets/ab38b5fe-15d0-4f91-855a-d066f045af51" />
<img width="1658" height="923" alt="rentalscript1" src="https://github.com/user-attachments/assets/a96fbbd6-d066-48e3-8f09-8727c2f7f48a" />
<img width="1829" height="956" alt="rentalscript" src="https://github.com/user-attachments/assets/20d22fb9-b6c9-40ff-b583-8b68321972d5" />
# Rentals

Vehicle rental desks. Players pay a deposit, and get it back based on the condition the vehicle is in when they return it. Desks, parking bays, vehicles and the refund rules are all set up in game.

## Requirements

- ox_lib
- oxmysql
- qbx_core, qb-core or es_extended
- OneSync

## What it picks up on its own

| | Supported |
|---|---|
| Framework | Qbox, QBCore, ESX |
| Vehicle keys | qbx_vehiclekeys, qb-vehiclekeys, MrNewbVehicleKeys, wasabi_carlock, Renewed-Vehiclekeys, qs-vehiclekeys |
| Fuel | ox_fuel, LegacyFuel, ps-fuel, lj-fuel, cdn-fuel, okokGasStation |
| Target | ox_target, qb-target, or an `[E]` prompt when neither is running |
| Notifications | okokNotify, your framework's own, or ox_lib |
| Text prompts | jg-textui, okokTextUI, or ox_lib |

Each of these is worked out once when the resource starts. Anything can be forced in `shared/config.lua`.

If your keys script is not listed, add it to `CB.GiveKeys` in `client/bridge.lua`, or to the `KEYS` table in `server/bridge.lua` if it has to be called from the server.

## Install

1. Put `vexxd_rentals` in your resources folder.
2. Add `ensure vexxd_rentals` to `server.cfg`, after your framework, ox_lib and oxmysql.
3. Restart the server. The database tables are created on first start.

Admins on your framework can use the admin panel straight away. To give access to someone else:

```
add_ace group.admin vexxd_rentals.admin allow
```

Optional Discord log of rentals and returns:

```
set vexxd_rentals_webhook "https://discord.com/api/webhooks/..."
```

## Setup in game

Run `/rentaladmin`.

1. **Rental desks** - stand where the clerk should be and press *New desk*.
2. On that desk, park or stand where a rented vehicle should appear and press *Add a bay where I am*. Add as many bays as you like; the first empty one is used.
3. Pick which vehicles the desk offers, or pick none to offer all of them. Save.
4. **Vehicles** - change names, spawn names, deposits and categories, or add your own.
5. **Settings** - title, accent colour, bank or cash, and the refund rules.

A desk cannot rent anything until it has at least one bay.

## How it works for players

1. Pick a vehicle at a desk and pay the deposit. The vehicle appears in a bay with keys and a full tank.
2. Drive it back and park it near any rental desk.
3. Open the desk and press *Return*. The refund depends on the condition:
   - at or above the *full refund* mark (default 90%): the whole deposit
   - between the two marks: a reduced amount, sliding evenly
   - at or below the *no refund* mark (default 20%): nothing

Condition is the average of the vehicle's body and engine health, read on the server.

One rental at a time. If the vehicle is gone for good, *Report it lost* closes the rental and the deposit is kept.

If a player leaves the server with a rental out, the vehicle is collected, the refund it earned is saved, and it is paid the next time they load in.

## Licences

Each vehicle can be set to need a licence (`car`, `motorcycle`, `commercial`). This only does anything when the `vexxd_dmv` script is running. Without it the setting is ignored and anyone can rent the vehicle.

## Pictures

Vehicle pictures load from the address in *Settings > Picture address*, where `%s` is the spawn name. Add-on vehicles can be given their own picture address on the vehicle.

## Exports (server)

```lua
exports.vexxd_rentals:HasRental(source)   -- true / false
exports.vexxd_rentals:GetRental(source)   -- { vehicle, model, plate, price, netId } or nil
```

Rented vehicles carry the state bag `vexxdRental = true`, so other scripts can tell them apart:

```lua
if Entity(vehicle).state.vexxdRental then ... end
```

## Support

discord.gg/TzNJ6Z92Y5
