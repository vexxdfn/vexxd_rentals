fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Vexxd Scripts'
description 'Rentals - vehicle rental desks with a deposit that is refunded by the condition the vehicle comes back in, set up in game. discord.gg/TzNJ6Z92Y5 for support'
version '1.0.2'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/detect.lua'
}

client_scripts {
    'client/bridge.lua',
    'client/main.lua',
    'client/admin.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua',
    'server/defaults.lua',
    'server/store.lua',
    'server/rentals.lua',
    'server/admin.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/fonts/*.ttf'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
