fx_version 'cerulean'
games { 'gta5' }

author 'HoboDevCo#3011'
description 'SDC | Medical Calls Script'
version '1.0.0'

shared_script {
    "@ox_lib/init.lua",
    "config/config.lua",
    "config/lang.lua"
}

client_scripts {
    "src/client/client_customize_me.lua",
    "src/client/client.lua"
}

server_scripts {
    "src/server/server_customize_me.lua",
    "src/server/server.lua",
}

escrow_ignore {
    "config/config.lua",
    "config/lang.lua",
    "src/client/client.lua",
    "src/client/client_customize_me.lua",
    "src/server/server.lua",
    "src/server/server_customize_me.lua",
}

lua54 'yes'

data_file 'DLC_ITYP_REQUEST' 'stream/medical_props.ytyp'