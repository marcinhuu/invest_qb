local QBCore = exports[Config.Core]:GetCoreObject()

function Notify(msg, type)
    if Config.Notify == "qb" then
        QBCore.Functions.Notify(msg, type, 5000)
    elseif Config.Notify == "okok" then
        exports['okokNotify']:Alert('Fishing', msg, 5000, type, true)
    elseif Config.Notify == "ox" then
        lib.notify({ title = 'Fishing', description = msg, type = type })
    end
end

function SendHelpText(msg, position)
    if Config.HelpText == "qb" then
        exports['qb-core']:DrawText(msg, position)
    elseif Config.HelpText == "ox" then
        lib.showTextUI(msg)
    end
end

function RemoveHelpText()
    if Config.HelpText == "qb" then
        exports['qb-core']:HideText()
    elseif Config.HelpText == "ox" then
        lib.hideTextUI()
    end
end
