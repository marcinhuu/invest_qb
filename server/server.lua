local QBCore = exports[Config.Core]:GetCoreObject()

Cache = {}

-- Get balance of invested companies
RegisterServerEvent("invest_qb:balance")
AddEventHandler("invest_qb:balance", function()
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)

    local user = MySQL.Sync.fetchAll('SELECT `amount` FROM `invest` WHERE `identifier`=@id AND active=1', {["@id"] = xPlayer.PlayerData.citizenid})
    local invested = 0
    for k, v in pairs(user) do
        invested = math.floor(invested + v.amount)
    end
    TriggerClientEvent("invest_qb:nui", src, {
        type = "balance",
        player =  xPlayer.PlayerData.charinfo.firstname,
        balance = invested
    })
end)

-- Get available companies
RegisterServerEvent("invest_qb:list")
AddEventHandler("invest_qb:list", function()
    TriggerClientEvent("invest_qb:nui", source, {
        type = "list",
        cache = Cache
    })
end)

-- Get all invested companies
RegisterServerEvent("invest_qb:all")
AddEventHandler("invest_qb:all", function(special)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local sql = 'SELECT `invest`.*, `companies`.`name`,`companies`.`investRate`,`companies`.`label` FROM `invest` '..
                'INNER JOIN `companies` ON `invest`.`job` = `companies`.`label` '..
                'WHERE `invest`.`identifier`=@id'

    if(special) then 
        sql = sql .. " AND `invest`.`active`=1"
    end

    local user = MySQL.Sync.fetchAll(sql, {["@id"] = xPlayer.PlayerData.citizenid})

    if(special) then
        TriggerClientEvent("invest_qb:nui", src, {
            type = "sell",
            cache = user
        })
    else 
        TriggerClientEvent("invest_qb:nui", src, {
            type = "all",
            cache = user
        })
    end
end)

-- Invest into a job
RegisterServerEvent("invest_qb:buy")
AddEventHandler("invest_qb:buy", function(job, amount, rate)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local bank = xPlayer.PlayerData.money["bank"]
    local id = xPlayer.PlayerData.citizenid
    amount = tonumber(amount)

    local inf = MySQL.Sync.fetchAll('SELECT * FROM `invest` WHERE `identifier`=@id AND active=1 AND job=@job LIMIT 1', {["@id"] = id, ['@job'] = job})
    for k, v in pairs(inf) do inf = v end

    if(amount == nil or amount <= 0) then
        return TriggerClientEvent('invest_qb:Client:Notify', src, Language["invalid_amount"], "error")
    elseif(Config.Stock.Limit ~= 0 and amount > Config.Stock.Limit) then
        return TriggerClientEvent('invest_qb:Client:Notify', src, string.gsub(Language["to_much"], "error", "{limit}", format_int(Config.Stock.Limit)))
    else
        if(bank < amount) then
            return TriggerClientEvent('invest_qb:Client:Notify', src, Language["broke_amount"], "error")
        end
        xPlayer.Functions.RemoveMoney('bank', tonumber(amount))
    end

    if(type(inf) == "table" and inf.job ~= nil) then
        MySQL.Sync.execute("UPDATE `invest` SET amount=amount+@num WHERE `identifier`=@id AND active=1 AND job=@job", {["@id"] = xPlayer.PlayerData.citizenid, ["@num"]=amount, ['@job'] = job})
        
        TriggerClientEvent('invest_qb:Client:Notify', src, Language["added"], "success")
    else
        if rate == nil then
            return TriggerClientEvent('invest_qb:Client:Notify', src, Language["unexpected_error"], "error")
        end

        MySQL.Sync.execute("INSERT INTO `invest` (identifier, job, amount, rate) VALUES (@id, @job, @amount, @rate)", {
            ["@id"] = id,
            ["@job"] = job,
            ["@amount"] = amount,
            ["@rate"] = rate
        })
        
        TriggerClientEvent('invest_qb:Client:Notify', src, Language["buy"], "success")

        PlayerWebhook(
            "**[❗️] Information Player:**" ..
            "\n" ..
            "**Player:** " .. GetPlayerName(src) ..
            "\n" ..
            "**CitizenID:** " .. xPlayer.PlayerData.citizenid ..
            "\n" ..
            "\n" ..
            "**[💵] Buy Investiment:**" ..
            "\n" ..
            "**Company:** " .. job..
            "\n" ..
            "**Amount:** $" .. amount ..
            "\n" ..
            "**Rate:** " .. rate
        )
    end

    TriggerEvent(src, "invest_qb:balance")
end)

-- Sell an investment
RegisterServerEvent("invest_qb:sell")
AddEventHandler("invest_qb:sell", function(job)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)

    local id = xPlayer.PlayerData.citizenid

    local result = MySQL.Sync.fetchAll( 'SELECT `invest`.*, `companies`.`investRate` FROM `invest` '..
                                            'INNER JOIN `companies` ON `invest`.`job` = `companies`.`label` '..
                                            'WHERE `identifier`=@id AND active=1 AND job=@job', {["@id"] = id, ['@job'] = job})
    for k, v in pairs(result) do result = v end

    local amount = result.amount
    local sellRate = math.abs(result.investRate - result.rate)
    local addMoney = amount + ((amount * sellRate) / 100)

    
    MySQL.Sync.execute("UPDATE `invest` SET active=0, sold=now(), soldAmount=@money, rate=@rate WHERE `id`=@id", {["@id"] = result.id, ["@money"] = addMoney, ["@rate"] =  sellRate})

    if(addMoney > 0) then
        xPlayer.Functions.RemoveMoney('bank', addMoney)
    else
        addMoney = math.abs(addMoney)*-1
        xPlayer.Functions.RemoveMoney('bank', addMoney)
    end
    
    TriggerClientEvent('invest_qb:Client:Notify', src, Language["sold"], "success")
    TriggerEvent(src, "invest_qb:balance")

end)

-- Gives a random number
function genRand(min, max, decimalPlaces)
    local rand = math.random()*(max-min) + min;
    local power = math.pow(10, decimalPlaces);
    return math.floor(rand*power) / power;
end

-- Loop invest rates
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    function loopUpdate()
        Citizen.Wait(60000 * Config.Stock.Time)
    
        local companies = MySQL.Sync.fetchAll("SELECT * FROM `companies`")
    
        local message = "**[❗️] Information:**\n"  -- Inicialize a mensagem
    
        for k, v in pairs(companies) do
            newRate = genRand(Config.Stock.Minimum, Config.Stock.Maximum, 2)
    
            local rate = "stale"
            if newRate > v.investRate then
                rate = "up"
            elseif newRate < v.investRate then
                rate = "down"
            end
    
            if (Config.Stock.Lost ~= 0 and newRate < 0) then
                MySQL.Sync.execute("UPDATE `invest` SET amount=(amount/100*(100-@lost)) WHERE active=1 AND job=@label", {
                    ["@label"] = v.label,
                    ["@lost"] = Config.Stock.Lost
                })
            end
    
            MySQL.Sync.execute("UPDATE `companies` SET investRate=@invest, rate=@rate WHERE label=@label", {
                ["@invest"] = newRate,
                ["@label"] = v.label,
                ["@rate"] = rate
            })
            Cache[v.label] = {stock = newRate, rate = rate, label = v.label, name = v.name}
    
            message = message ..
                "**Name:** " .. v.name ..
                "   |   **Label:** " .. v.label ..
                "   |   **Rate:** " .. rate ..
                "   |   **InvestRate:** " .. v.investRate .. "\n\n"
        end
    
        InvestWebhook(message)
    
        loopUpdate()
    end
    

    Citizen.Wait(0) --Don't remove, crashes SQL

    local companies = MySQL.Sync.fetchAll("SELECT * FROM `companies`")
    for k, v in pairs(companies) do
        if(v.investRate == nil) then
            v.investRate = genRand(Config.Stock.Minimum, Config.Stock.Maximum, 2)

            MySQL.Sync.execute("UPDATE companies SET investRate=@rate WHERE label=@label", {
                ["@rate"] = v.investRate,
                ["@label"] = v.label
            })
        end

        Cache[v.label] = {stock = v.investRate, rate = v.rate, label = v.label, name = v.name}
    end
    loopUpdate()
end)

function format_int(number)
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

function InvestWebhook(message)
    local embed = {
        {
            ["color"] = 65280,
            ["title"] = "Invest | Logs",
            ["description"] = "" .. message .. "",
            ["footer"] = {
                ["icon_url"] = "https://media.discordapp.net/attachments/1049749773185470537/1135266178688876595/avatar.png",
                ["text"] = 'Invest | Logs | Created By marcinhu#0001',
            },
        }
    }

    PerformHttpRequest("INSERT_YOUR_WEBOOK_HERE", 
        function(err, text, headers) end,
        'POST',
        json.encode({username = 'Invest - Logs', embeds = embed, avatar_url = "https://media.discordapp.net/attachments/1049749773185470537/1135266178688876595/avatar.png"}),
        { ['Content-Type'] = 'application/json' }
    )
end

function PlayerWebhook(message)
    local embed = {
        {
            ["color"] = 65280,
            ["title"] = "Invest | Logs",
            ["description"] = "" .. message .. "",
            ["footer"] = {
                ["icon_url"] = "https://media.discordapp.net/attachments/1049749773185470537/1135266178688876595/avatar.png",
                ["text"] = 'Invest | Logs | Created By marcinhu#0001',
            },
        }
    }

    PerformHttpRequest("INSERT_YOUR_WEBOOK_HERE", 
        function(err, text, headers) end,
        'POST',
        json.encode({username = 'Invest - Logs', embeds = embed, avatar_url = "https://media.discordapp.net/attachments/1049749773185470537/1135266178688876595/avatar.png"}),
        { ['Content-Type'] = 'application/json' }
    )
end