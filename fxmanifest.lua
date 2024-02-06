fx_version 'bodacious'
game 'gta5'

author 'Tazio de Bruin - TR Version : Abdulkadir | QBCore Version: marcinhu'
title 'QBCore Invest'
description 'Invest in companies'
version '1.3'

ui_page 'client/html/UI.html'

shared_scripts {
    "@ox_lib/init.lua",
    'configs/**.lua',
}

server_script {
    '@oxmysql/lib/MySQL.lua',
    "server/**.lua",
}

client_script {
    "client/**.lua",
}

export 'openUI'

files {
    'client/html/**',
}

lua54 'yes'