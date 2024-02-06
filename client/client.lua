local QBCore = exports[Config.Core]:GetCoreObject()

local inMenu = false

-- User Interaction
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsControlJustPressed(1, 322) and inMenu then
			closeUI()
		end
	end
end)

RegisterNetEvent('invest_qb:Client:Notify')
AddEventHandler("invest_qb:Client:Notify", function(msg, type, time)
    Notify(msg, type, time)
end)

-- Events
RegisterNetEvent("invest_qb:nui")
AddEventHandler("invest_qb:nui", function (data)
	SendNUIMessage(data)
end)

-- UI callbacks
RegisterNUICallback('close', function(data, cb) 
	if(inMenu) then
		closeUI()
	end
end)

RegisterNUICallback("newBanking", function()
	if(inMenu) then
		closeUI()
		exports.new_banking:openUI()
	end
end)

RegisterNUICallback("list", function()
	TriggerServerEvent("invest_qb:list")
end)

RegisterNUICallback("all", function()
	TriggerServerEvent("invest_qb:all", false)
end)

RegisterNUICallback("sell", function()
	TriggerServerEvent("invest_qb:all", true)
end)

RegisterNUICallback("sellInvestment", function(data, cb)
	TriggerServerEvent("invest_qb:sell", data.job)
end)

RegisterNUICallback("buyInvestment", function(data, cb)
	TriggerServerEvent("invest_qb:buy", data.job, data.amount, data.boughtRate)
end)

RegisterNUICallback("balance", function(data, cb)
	TriggerServerEvent("invest_qb:balance")
end)

-- Open UI
function openUI()
	inMenu = true
	SetNuiFocus(true, true)
    SendNUIMessage({type = "open"})
end

-- Close UI
function closeUI() 
	inMenu = false
	SetNuiFocus(false, false)
    SendNUIMessage({type = "close"})
end

-- Close menu on close
AddEventHandler('onResourceStop', function (resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
	  return
    end
    if inMenu then
        closeUI()
    end
end)

CreateThread(function()
    local function onEnter(self)
		SendHelpText(Language["open_menu"], "right")
    end
    local function onExit(self)
        RemoveHelpText()
    end
    local function inside(self)
        if IsControlJustPressed(0, 38) then
            openUI()
        end
    end

    for index, location in pairs(Config.Locations) do
        local coords = location.coords

		if location.blipEnable then
			local blip = AddBlipForCoord(coords.x, coords.y, coords.z) 
			SetBlipSprite(blip, location.blipSprite) 
			SetBlipDisplay(blip, 2)
			SetBlipScale(blip, location.blipScale)
			SetBlipAsShortRange(blip, true)
			SetBlipColour(blip, location.blipColour)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentSubstringPlayerName(location.blipName) 
			EndTextCommandSetBlipName(blip)
		end

		local box = lib.zones.box({
			coords = vec3(coords.x, coords.y, coords.z),
			size = vec3(2.0, 2.0, 2.0),
			rotation = 45,
			debug = false,
			inside = inside,
			onEnter = onEnter,
			onExit = onExit,
		})
    end
end)

