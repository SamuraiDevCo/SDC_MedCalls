local allMedicalCalls = {}
local activeEMS = 0

local allInjuries = {}
local allComplaints = {}
local calltable = {}

RegisterServerEvent("SDMC:Server:LoadedIn")
AddEventHandler("SDMC:Server:LoadedIn", function()
    local src = source
    TriggerClientEvent("SDMC:Client:UpdateCalls", src, allMedicalCalls)
end)

Citizen.CreateThread(function()
    for k,v in pairs(SDC.Injuries) do
        table.insert(allInjuries, k)
    end
    for k,v in pairs(SDC.Complaints) do
        table.insert(allComplaints, k)
    end
    for i=1, #SDC.ExtraComplaints do
        table.insert(allComplaints, SDC.ExtraComplaints[i])
    end

    for k,v in pairs(SDC.CallChances) do
        for i=1, v do
            table.insert(calltable, k)
        end
    end
    

    while true do
        if activeEMS > 0 and #allMedicalCalls < SDC.MaxCallsAtATime then
            StartCall()
            Citizen.Wait(math.random(SDC.RandomCallTimer[1], SDC.RandomCallTimer[2])*60000)
        else
            Citizen.Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        activeEMS = GetActiveEMS()

        if #allMedicalCalls > 0 and activeEMS > 0 then
            for i=1, #allMedicalCalls do
                if os.difftime(allMedicalCalls[i].TimeStart, os.time()) > (SDC.MaxCallTime*60) then
                    EndCall(i)
                end
            end
        elseif #allMedicalCalls > 0 and activeEMS == 0 then
            for i=1, #allMedicalCalls do
                EndCall(i)
            end
        end
        Citizen.Wait(5000)
    end
end)


function StartCall()
    calltype = calltable[math.random(1, #calltable)]

    if calltype == "AssistanceNeeded" then
        local newCallNum = 0
        repeat
            newCallNum = math.random(1, #SDC.CallCoords)
    
            if allMedicalCalls[1] then
                for i=1, #allMedicalCalls do
                    if allMedicalCalls[i].CallType == "AssistanceNeeded" and allMedicalCalls[i].CallNum == newCallNum then
                        newCallNum = 0
                    end
                end
            end
            Wait(100)
        until newCallNum > 0

        local daStatus = nil
        if math.random(1, 100) > 50 then
            daStatus = "Unconscious"
        else
            daStatus = "Conscious"
        end
        
        local daVitals = {BP = nil, Heartrate = nil, RespiratoryRate = nil, BloodSugar = nil, Temperature = nil}
        upper = math.random(SDC.VitalSettings.BP.UpperConstraints.Min, SDC.VitalSettings.BP.UpperConstraints.Max)
        lower = math.random(SDC.VitalSettings.BP.LowerDifferanceFromUpper.Min, SDC.VitalSettings.BP.LowerDifferanceFromUpper.Max)
        daVitals.BP = upper.."/"..(upper - lower)

        if upper <= SDC.VitalSettings.BP.UpperCategories.Low then
            daVitals.Heartrate = math.random(SDC.VitalSettings.Heartrate.BPComparison.High.Min, SDC.VitalSettings.Heartrate.BPComparison.High.Max)
            daVitals.RespiratoryRate = math.random(SDC.VitalSettings.RespiratoryRate.HeartrateComparison.High.Min, SDC.VitalSettings.RespiratoryRate.HeartrateComparison.High.Max)
        elseif upper <= SDC.VitalSettings.BP.UpperCategories.Normal then
            daVitals.Heartrate = math.random(SDC.VitalSettings.Heartrate.BPComparison.Normal.Min, SDC.VitalSettings.Heartrate.BPComparison.Normal.Max)
            daVitals.RespiratoryRate = math.random(SDC.VitalSettings.RespiratoryRate.HeartrateComparison.Normal.Min, SDC.VitalSettings.RespiratoryRate.HeartrateComparison.Normal.Max)
        elseif upper <= SDC.VitalSettings.BP.UpperCategories.High then
            daVitals.Heartrate = math.random(SDC.VitalSettings.Heartrate.BPComparison.Low.Min, SDC.VitalSettings.Heartrate.BPComparison.Low.Max)
            daVitals.RespiratoryRate = math.random(SDC.VitalSettings.RespiratoryRate.HeartrateComparison.Low.Min, SDC.VitalSettings.RespiratoryRate.HeartrateComparison.Low.Max)
        end
        
        daVitals.BloodSugar = math.random(SDC.VitalSettings.BloodSugar.Low.Min, SDC.VitalSettings.BloodSugar.High.Max)

        daVitals.Temperature = math.random(SDC.VitalSettings.Temperature.Low.Min, SDC.VitalSettings.Temperature.High.Max)

        local daInjuries = {}
        daInjuryAmt = math.random(SDC.RandomInjuryCount[1], SDC.RandomInjuryCount[2])
        repeat 
            ranInjury = allInjuries[math.random(1, #allInjuries)]
            local good = true
            if daInjuries[1] then
                for i=1, #daInjuries do
                    if string.find(daInjuries[i], ranInjury) then
                        good = false
                    end
                end
            end
            if good then
                table.insert(daInjuries, ranInjury.." "..SDC.Injuries[ranInjury][math.random(1, #SDC.Injuries[ranInjury])])
            end
            Wait(10)
        until (#daInjuries == daInjuryAmt)

        local daComplaints = {}
        daComplaintsAmt = math.random(SDC.RandomComplaintCount[1], SDC.RandomComplaintCount[2])
        repeat 
            ranComplaint = allComplaints[math.random(1, #allComplaints)]
            local good = true
            if daComplaints[1] then
                for i=1, #daComplaints do
                    if string.find(daComplaints[i], ranComplaint) then
                        good = false
                    end
                end
            end
            if good then
                if SDC.Complaints[ranComplaint] then
                    table.insert(daComplaints, ranComplaint.." "..SDC.Complaints[ranComplaint][math.random(1, #SDC.Complaints[ranComplaint])])
                else
                    table.insert(daComplaints, ranComplaint)
                end
            end
            Wait(10)
        until (#daComplaints == daComplaintsAmt)

        local daObservations = {}
        daObservationsAmt = math.random(SDC.RandomObservationCount[1], SDC.RandomObservationCount[2])
        repeat
            ranObservation = SDC.Observations[math.random(1, #SDC.Observations)]
            local good = true
            if daObservations[1] then
                for i=1, #daObservations do
                    if string.find(daObservations[i], ranObservation) then
                        good = false
                    end
                end
            end
            if good then
                table.insert(daObservations, ranObservation)
            end
            Wait(10)
        until (#daObservations == daObservationsAmt)

        daname = SDC.FirstNames[math.random(1, #SDC.FirstNames)].." "..SDC.LastNames[math.random(1, #SDC.LastNames)]

        table.insert(allMedicalCalls, {CallType = calltype, CallNum = newCallNum, TimeStart = os.time(), Details = {Status = daStatus, Vitals = daVitals, Injuries = daInjuries, Complaints = daComplaints, Observations = daObservations, Name = daname, Age = math.random(SDC.RandomAge[1], SDC.RandomAge[2]), Height = math.random(SDC.RandomHeight[1], SDC.RandomHeight[2])}, Ped = nil, CheckupDone = false, Grabbed = nil})
        TriggerEvent("SDMC:Server:SpawnCallPed", #allMedicalCalls)
        TriggerClientEvent("SDMC:Client:NotificationWithJob", -1, SDC.Lang.AssistanceNeeded2, "primary")
        TriggerClientEvent("SDMC:Client:UpdateCalls", -1, allMedicalCalls)
    elseif calltype == "HospitalTransport" then
        local newCallNum = 0
        repeat
            newCallNum = math.random(1, #SDC.PickupDropoffs)
    
            if allMedicalCalls[1] then
                for i=1, #allMedicalCalls do
                    if allMedicalCalls[i].CallType == "HospitalTransport" and allMedicalCalls[i].CallNum == newCallNum and not allMedicalCalls[i].PickedUp then
                        newCallNum = 0
                    end
                end
            end
            Wait(100)
        until newCallNum > 0

        table.insert(allMedicalCalls, {CallType = calltype, CallNum = newCallNum, TimeStart = os.time(), PickedUp = false, PedModel = SDC.PedModels[math.random(1, #SDC.PedModels)]})
        TriggerClientEvent("SDMC:Client:NotificationWithJob", -1, SDC.Lang.TransportNeeded2, "primary")
        TriggerClientEvent("SDMC:Client:UpdateCalls", -1, allMedicalCalls)
    end
end

RegisterServerEvent("SDMC:Server:SpawnCallPed")
AddEventHandler("SDMC:Server:SpawnCallPed", function(call)
    local done = false
    while not done do
        pedModel = SDC.PedModels[math.random(1, #SDC.PedModels)]
        local newPed = CreatePed(5, GetHashKey(pedModel), SDC.CallCoords[allMedicalCalls[call].CallNum].x, SDC.CallCoords[allMedicalCalls[call].CallNum].y, SDC.CallCoords[allMedicalCalls[call].CallNum].z, SDC.CallCoords[allMedicalCalls[call].CallNum].w, true, false)
        Wait(100)
        if DoesEntityExist(newPed) then
            allMedicalCalls[call].Ped = NetworkGetNetworkIdFromEntity(newPed)
            SetEntityHeading(newPed, SDC.CallCoords[allMedicalCalls[call].CallNum].w)
            SetPedConfigFlag(newPed, 17, true)
            if allMedicalCalls[call].Details.Status == "Unconscious" then
                TaskPlayAnim(newPed, SDC.StatusConfigs.Unconscious.Dict, SDC.StatusConfigs.Unconscious.Anim, 8.0, 8.0, -1, 1, 1, 0, 0, 0)
            else
                TaskPlayAnim(newPed, SDC.StatusConfigs.Conscious.Dict, SDC.StatusConfigs.Conscious.Anim, 8.0, 8.0, -1, 1, 1, 0, 0, 0)
            end
            Wait(500)
            FreezeEntityPosition(newPed, true)
            done = true
            TriggerClientEvent("SDMC:Client:UpdateCalls", -1, allMedicalCalls)
        end
        Wait(1000)
    end
end)

RegisterServerEvent("SDMC:Server:PreformedCheckup")
AddEventHandler("SDMC:Server:PreformedCheckup", function(callt, calln)
    local src = source

    if allMedicalCalls[1] then
        for i=1, #allMedicalCalls do
            if allMedicalCalls[i].CallType == callt and allMedicalCalls[i].CallNum == calln then
                if not allMedicalCalls[i].CheckupDone then
                    allMedicalCalls[i].CheckupDone = true
                    TriggerClientEvent("SDMC:Client:UpdateCalls", -1, allMedicalCalls)
                end
            end
        end
    end
end)
RegisterServerEvent("SDMC:Server:PickedUpInjury")
AddEventHandler("SDMC:Server:PickedUpInjury", function(callt, calln)
    local src = source

    if allMedicalCalls[1] then
        for i=1, #allMedicalCalls do
            if allMedicalCalls[i].CallType == callt and allMedicalCalls[i].CallNum == calln then
                if not allMedicalCalls[i].Grabbed then
                    allMedicalCalls[i].Grabbed = src
                    TriggerClientEvent("SDMC:Client:UpdateCalls", -1, allMedicalCalls)
                end
            end
        end
    end
end)

RegisterServerEvent("SDMC:Server:DropoffDone")
AddEventHandler("SDMC:Server:DropoffDone", function()
    local src = source
    local found = i
    if allMedicalCalls[1] then
        for i=1, #allMedicalCalls do
            if allMedicalCalls[i].Grabbed and allMedicalCalls[i].Grabbed == src then
                if NetworkGetEntityFromNetworkId(allMedicalCalls[i].Ped) and DoesEntityExist(NetworkGetEntityFromNetworkId(allMedicalCalls[i].Ped)) then
                    DeleteEntity(NetworkGetEntityFromNetworkId(allMedicalCalls[i].Ped))
                end
                found = i
            elseif allMedicalCalls[i].PickedUp and allMedicalCalls[i].PickedUp == src then
                found = i
            end
        end

        if found > 0 then
            if allMedicalCalls[found].CallType == "AssistanceNeeded" then
                AddBankAmount(src, SDC.FinishCallReward.AssistanceNeeded)
            elseif allMedicalCalls[found].CallType == "HospitalTransport" then
                AddBankAmount(src, SDC.FinishCallReward.HospitalTransport)
            end
            table.remove(allMedicalCalls, found)
            TriggerClientEvent("SDMC:Client:NotificationWithJob", -1, SDC.Lang.DeliveredCivilian, "success")
            TriggerClientEvent("SDMC:Client:UpdateCalls", -1, allMedicalCalls)
        end
    end
end)

RegisterServerEvent("SDMC:Server:PickedUpTransport")
AddEventHandler("SDMC:Server:PickedUpTransport", function(callt, calln)
    local src = source

    if allMedicalCalls[1] then
        for i=1, #allMedicalCalls do
            if allMedicalCalls[i].CallType == callt and allMedicalCalls[i].CallNum == calln then
                if not allMedicalCalls[i].PickedUp then
                    allMedicalCalls[i].PickedUp = src
                    TriggerClientEvent("SDMC:Client:UpdateCalls", -1, allMedicalCalls)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if allMedicalCalls[1] then
            for i=1, #allMedicalCalls do
                if allMedicalCalls[i].Ped then
                    if NetworkGetEntityFromNetworkId(allMedicalCalls[i].Ped) and DoesEntityExist(NetworkGetEntityFromNetworkId(allMedicalCalls[i].Ped)) then
                        DeleteEntity(NetworkGetEntityFromNetworkId(allMedicalCalls[i].Ped))
                    end
                end
            end
        end
	end
end)