local QBCore = nil
local ESX = nil

if SDC.Framework == "qb-core" then
    QBCore = exports['qb-core']:GetCoreObject()
elseif SDC.Framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
end

function GetCurrentJob()
    if SDC.Framework == "qb-core" then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.job and PlayerData.job.name then
            return PlayerData.job.name
        else
            return nil
        end
    elseif SDC.Framework == "esx" then
        local PlayerData = ESX.GetPlayerData()
        if PlayerData and PlayerData.job and PlayerData.job.name then
            return PlayerData.job.name
        else
            return nil
        end
    end
end

function DoProgressbar(time, label)
    if SDC.UseProgBar == "progressBars" then
        exports['progressBars']:startUI(time, label)
        Wait(time)
        return true
    elseif SDC.UseProgBar == "mythic_progbar" then
        TriggerEvent("mythic_progbar:client:progress", {
            name = "sdc_foodtrucks",
            duration = time,
            label = label,
            useWhileDead = false,
            canCancel = false,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }
        })
        Wait(time)
        return true
    elseif SDC.UseProgBar == "ox_lib" then
        if lib.progressBar({
            duration = time,
            label =  label,
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
            },
        }) then 
            return true
        end
    else
        Wait(time)
        return true
    end
end


RegisterNetEvent("SDMC:Client:Notification")
AddEventHandler("SDMC:Client:Notification", function(msg, extra)
	if SDC.NotificationSystem == 'tnotify' then
		exports['t-notify']:Alert({
			style = 'message', 
			message = msg
		})
	elseif SDC.NotificationSystem == 'mythic_old' then
		exports['mythic_notify']:DoHudText('inform', msg)
	elseif SDC.NotificationSystem == 'mythic_new' then
		exports['mythic_notify']:SendAlert('inform', msg)
	elseif SDC.NotificationSystem == 'okoknotify' then
		exports['okokNotify']:Alert("SDC Medical Calls", msg, 3000, 'neutral')
	elseif SDC.NotificationSystem == 'print' then
		print(msg)
	elseif SDC.NotificationSystem == 'framework' then
        if SDC.Framework == "qb-core" then
            QBCore.Functions.Notify(msg, extra)
        elseif SDC.Framework == "esx" then
            ESX.ShowNotification(msg)
        end
	end 
end)