Config = {}

Config.Core = "qb-core" -- Your qb-core folder name
Config.Notify = "qb" -- "qb" or "okok" or "ox" ( open code on config_functions.lua )
Config.HelpText = "qb" -- "qb" or "ox" ( open code on config_functions.lua )

-- Locations
Config.Locations = {
    [1] = {coords = vector3(-693.43, -582.59, 31.55), blipEnable = true, blipSprite = 374, blipColour = 2, blipScale = 0.8, blipName = "Investiments" },
}

-- Stock settings
-- min/max is in %
-- time is in minutes
-- limit is in $ (0 = no limit)
-- lost is in % (0 = no lost of money)
Config.Stock = {
    Minimum = -5,
    Maximum = 5,
    Time = 1,
    Limit = 10000,
    Lost = 10
}

-- Documentation:
-- Min/Max is the min/max all the stocks can go
-- Time is the time the new rates will be given
-- Limit is the maximum amount that can be invest into a company
-- Lost is the % that will be lost when a stock is at a negative %
