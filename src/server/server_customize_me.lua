local QBCore = nil
local ESX = nil

if SDC.Framework == "qb-core" then
    QBCore = exports['qb-core']:GetCoreObject()
elseif SDC.Framework == "esx" then
    ESX = exports['es_extended']:getSharedObject()
end

function GetActiveEMS()
    if SDC.Framework == "qb-core" then
        local Players = QBCore.Functions.GetPlayers()
        local count = 0
        if #Players > 0 then
            for i=1, #Players do
                local Player = QBCore.Functions.GetPlayer(Players[i])
                if Player and SDC.EMSJobs[Player.PlayerData.job.name] and Player.PlayerData.job.onduty then
                    count = count + 1
                end
            end
        end
        return count
    elseif SDC.Framework == "esx" then
        local Players = ESX.GetPlayers()
        local count = 0
        if #Players > 0 then
            for i=1, #Players do
                local Player = ESX.GetPlayerFromId(Players[i])
                if Player and SDC.EMSJobs[Player.job.name] then
                    count = count + 1
                end
            end
        end
        return count
    end
end

function AddBankAmount(src, amt)
    if SDC.Framework == "qb-core" then
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.AddMoney('bank', amt)
    elseif SDC.Framework == "esx" then
        local xPlayer = ESX.GetPlayerFromId(src)
        xPlayer.addAccountMoney('bank', amt)
    end
end