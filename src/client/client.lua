local loadedClient = false
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if NetworkIsSessionStarted() then
			Citizen.Wait(200)
			loadedClient = true
            TriggerServerEvent("SDMC:Server:LoadedIn")
			return -- break the loop
		end
	end
end)

---------------------------------------------------------------------
local allCalls = {}
local closestAssitCall = nil
local closestTransportCall = nil
local allBlips = {}

local hasJob = false

local hasStretcher = nil
local isonstretcher = nil
local stretcherinback = nil

local PlayerHasProp = {}
local closestVeh = nil
local nearbyVehs = {}
local vehConversion = {}
local selectedHospital = nil
local selectedDropoff = nil

RegisterNetEvent("SDMC:Client:UpdateCalls")
AddEventHandler("SDMC:Client:UpdateCalls", function(tab)
	allCalls = tab
end)
RegisterNetEvent("SDMC:Client:NotificationWithJob")
AddEventHandler("SDMC:Client:NotificationWithJob", function(msg, extra)
	if hasJob then
		TriggerEvent("SDMC:Client:Notification", msg, extra)
	end
end)

Citizen.CreateThread(function()
	for k,v in pairs(SDC.VehiclesWithStretchers) do
		vehConversion[tostring(GetHashKey(k))] = v 
	end

	while not HasStreamedTextureDictLoaded("medcall_sprites") do
		Wait(10)
		RequestStreamedTextureDict("medcall_sprites", true)
	end

	while true do
		if hasJob then
			local ped = PlayerPedId()
			local coords = GetEntityCoords(ped)
			for i=1, #allCalls do
				if allBlips[tostring(allCalls[i].CallType.."_"..allCalls[i].CallNum)] then
					if allCalls[i]["Grabbed"] then
						if DoesBlipExist(allBlips[tostring(allCalls[i].CallType.."_"..allCalls[i].CallNum)]) then
							RemoveBlip(allBlips[tostring(allCalls[i].CallType.."_"..allCalls[i].CallNum)])
							allBlips[tostring(allCalls[i].CallType.."_"..allCalls[i].CallNum)] = nil
						end
					elseif allCalls[i]["PickedUp"] then
						if DoesBlipExist(allBlips[tostring(allCalls[i].CallType.."_"..allCalls[i].CallNum)]) then
							RemoveBlip(allBlips[tostring(allCalls[i].CallType.."_"..allCalls[i].CallNum)])
							allBlips[tostring(allCalls[i].CallType.."_"..allCalls[i].CallNum)] = nil
						end
					end
				else
					if allCalls[i].CallType == "AssistanceNeeded" and not allCalls[i].Grabbed then
						local callBlip = AddBlipForCoord(SDC.CallCoords[allCalls[i].CallNum].x, SDC.CallCoords[allCalls[i].CallNum].y, SDC.CallCoords[allCalls[i].CallNum].z)
						SetBlipSprite(callBlip, SDC.InjuryBlip.Sprite)
						SetBlipScale(callBlip, SDC.InjuryBlip.Size)
						SetBlipColour(callBlip, SDC.InjuryBlip.Color)
						BeginTextCommandSetBlipName("STRING")
						AddTextComponentString(SDC.Lang.AssistanceNeeded)
						EndTextCommandSetBlipName(callBlip)
						allBlips[tostring(allCalls[i].CallType.."_"..allCalls[i].CallNum)] = callBlip
					elseif allCalls[i].CallType == "HospitalTransport" and not allCalls[i]["PickedUp"] then
						local callBlip = AddBlipForCoord(SDC.PickupDropoffs[allCalls[i].CallNum].Coords.x, SDC.PickupDropoffs[allCalls[i].CallNum].Coords.y, SDC.PickupDropoffs[allCalls[i].CallNum].Coords.z)
						SetBlipSprite(callBlip, SDC.TransportBlip.Sprite)
						SetBlipScale(callBlip, SDC.TransportBlip.Size)
						SetBlipColour(callBlip, SDC.TransportBlip.Color)
						BeginTextCommandSetBlipName("STRING")
						AddTextComponentString(SDC.Lang.TransportNeeded)
						EndTextCommandSetBlipName(callBlip)
						allBlips[tostring(allCalls[i].CallType.."_"..allCalls[i].CallNum)] = callBlip
					end
				end

				if allCalls[i].Ped and Vdist(coords.x, coords.y, coords.z, SDC.CallCoords[allCalls[i].CallNum]) <= 75 and NetworkDoesNetworkIdExist(allCalls[i].Ped) then
					local daped = NetworkGetEntityFromNetworkId(allCalls[i].Ped)
					if DoesEntityExist(daped) and ((allCalls[i].Details.Status == "Conscious" and not IsEntityPlayingAnim(daped, SDC.StatusConfigs.Conscious.Dict, SDC.StatusConfigs.Conscious.Anim, 3)) or (allCalls[i].Details.Status == "Unconscious" and not IsEntityPlayingAnim(daped, SDC.StatusConfigs.Unconscious.Dict, SDC.StatusConfigs.Unconscious.Anim, 3))) then						
						local good = false
						local counter = 0
						repeat
							if not NetworkHasControlOfNetworkId(allCalls[i].Ped) then
								NetworkRequestControlOfNetworkId(allCalls[i].Ped)
							else
								good = true
							end

							if counter >= 20 then
								good = true
							else
								counter = counter + 1
							end
							Citizen.Wait(500)
						until good 
						if not IsEntityPlayingAnim(daped, "anim@gangops@morgue@table@", "body_search", 3) then
							if NetworkHasControlOfNetworkId(allCalls[i].Ped) then
								LoadAnim(SDC.StatusConfigs[allCalls[i].Details.Status].Dict)
								TaskPlayAnim(daped, SDC.StatusConfigs[allCalls[i].Details.Status].Dict, SDC.StatusConfigs[allCalls[i].Details.Status].Anim, 8.0, 8.0, -1, 1, 1, 0, 0, 0)
								RemoveAnimDict(SDC.StatusConfigs[allCalls[i].Details.Status].Dict)
							end
						end
					end
				end
			end

			for k,v in pairs(allBlips) do
				local keep = false
				if allCalls[1] then
					for i=1, #allCalls do
						if k == tostring(allCalls[i].CallType.."_"..allCalls[i].CallNum) then
							keep = true
						end
					end
				end
				if not keep and k ~= "HospitalBlip" then
					if DoesBlipExist(v) then
						RemoveBlip(v)
						allBlips[k] = nil
					end
				end
			end

			local minDistance = 50
			local minDistance2 = 50
			local closestAssitCall2 = nil
			local closestTransportCall2 = nil
			if allCalls[1] then
				for i=1, #allCalls do
					if allCalls[i].CallType == "AssistanceNeeded"then
						dist = Vdist(SDC.CallCoords[allCalls[i].CallNum].x, SDC.CallCoords[allCalls[i].CallNum].y, SDC.CallCoords[allCalls[i].CallNum].z, coords)
						if dist < minDistance then
							minDistance = dist
							closestAssitCall2 = i
						end
					elseif allCalls[i].CallType == "HospitalTransport" then
						dist = Vdist(SDC.PickupDropoffs[allCalls[i].CallNum].Coords.x, SDC.PickupDropoffs[allCalls[i].CallNum].Coords.y, SDC.PickupDropoffs[allCalls[i].CallNum].Coords.z, coords)
						if dist < minDistance2 then
							minDistance2 = dist
							closestTransportCall2 = i
						end
					end
				end
			end
			closestAssitCall = closestAssitCall2
			closestTransportCall = closestTransportCall2

			local nearbyVehs2 = {}
			for veh in EnumerateVehicles() do
				if veh and DoesEntityExist(veh) and vehConversion[tostring(GetEntityModel(veh))] then
					table.insert(nearbyVehs2, veh)
				end
			end
			nearbyVehs = nearbyVehs2

			if nearbyVehs[1] then
				local minDist = 50
				for i=1, #nearbyVehs do
					dist = Vdist(coords.x, coords.y, coords.z, GetEntityCoords(nearbyVehs[i]))
					if dist < minDist then
						minDist = dist
						closestVeh = nearbyVehs[i]
					end
				end
			else
				closestVeh = nil
			end

			Citizen.Wait(500)
		else
			for k,v in pairs(allBlips) do
				if DoesBlipExist(v) then
					RemoveBlip(v)
					allBlips[k] = nil
				end
			end 
			closestAssitCall = nil
			closestTransportCall = nil
			Citizen.Wait(1000)
		end
	end
end)


Citizen.CreateThread(function()
	while true do
		if loadedClient and GetCurrentJob() then
			if SDC.EMSJobs[GetCurrentJob()] then
				hasJob = true
			else
				hasJob = false
			end
		end
		Citizen.Wait(1000)
	end
end)

local drawingUI = nil
Citizen.CreateThread(function()
	while true do
		if hasJob then
			local ped = PlayerPedId()
			local coords = GetEntityCoords(ped)

			if closestAssitCall and Vdist(coords.x, coords.y, coords.z, SDC.CallCoords[allCalls[closestAssitCall].CallNum]) <= 1.5 and not allCalls[closestAssitCall].Grabbed then
				if not hasStretcher then
					if not drawingUI or drawingUI ~= "assist" then
						drawingUI = "assist"
						lib.showTextUI("["..SDC.Keybinds.PreformCheckup.Label.."] - "..SDC.Lang.PreformCheckup, {
							position = "right-center",
							icon = "hand",
						})
					end
	
					if IsControlJustReleased(0, SDC.Keybinds.PreformCheckup.Input) then
						if hasStretcher then
							TriggerEvent("SDMC:Client:Notification", SDC.Lang.CantPreformCheckup, "error")
						else
							if not allCalls[closestAssitCall].CheckupDone then
								TriggerServerEvent("SDMC:Server:PreformedCheckup", allCalls[closestAssitCall].CallType, allCalls[closestAssitCall].CallNum)
								LoadAnim("missfam4")
								TaskPlayAnim(ped, "missfam4", "base", 8.0, 8.0, -1, 1, 1, 0, 0, 0)
								RemoveAnimDict("missfam4")
								AddPropToPlayer("p_amb_clipboard_01", 36029, 0.16, 0.08, 0.1, -130.0, -50.0, 0.0, "checkup", ped, true)
								daped = NetworkGetEntityFromNetworkId(allCalls[closestAssitCall].Ped)
								if DoesEntityExist(daped) then
									MakeEntityFaceEntity(ped, daped)
								end
								FreezeEntityPosition(ped, true)
								DoProgressbar(SDC.CheckupAnimTime*1000, SDC.Lang.PreformCheckup2)
								ClearPedTasksImmediately(ped)
								FreezeEntityPosition(ped, false)
								RemovePropFromPlayer("checkup")
	
								local vitalhelpers = {BP = "", Heartrate = "", Respiratory = "", BloodSugar = "", Temperature = ""}
								local injuryTable = nil
								local complaintTable = nil
								local observationTable = nil
	
								for i=1, #allCalls[closestAssitCall].Details.Injuries do
									if injuryTable then
										injuryTable = injuryTable..", "..allCalls[closestAssitCall].Details.Injuries[i]
									else
										injuryTable = allCalls[closestAssitCall].Details.Injuries[i]
									end
								end
								for i=1, #allCalls[closestAssitCall].Details.Complaints do
									if complaintTable then
										complaintTable = complaintTable..", "..allCalls[closestAssitCall].Details.Complaints[i]
									else
										complaintTable = allCalls[closestAssitCall].Details.Complaints[i]
									end
								end
								for i=1, #allCalls[closestAssitCall].Details.Observations do
									if observationTable then
										observationTable = observationTable..", "..allCalls[closestAssitCall].Details.Observations[i]
									else
										observationTable = allCalls[closestAssitCall].Details.Observations[i]
									end
								end
	
	
								if SDC.ShowVitalHelpers then
									local realBP = nil
									realBP = string.sub(allCalls[closestAssitCall].Details.Vitals.BP, 1, 2)
									if string.sub(allCalls[closestAssitCall].Details.Vitals.BP, 3, 3) ~= "/" then
										realBP = realBP..string.sub(allCalls[closestAssitCall].Details.Vitals.BP, 3, 3)
									end
	
									if tonumber(realBP) <= SDC.VitalSettings.BP.UpperCategories.Low then
										vitalhelpers.BP = "("..SDC.Lang.Low..")"
										vitalhelpers.Heartrate = "("..SDC.Lang.High..")"
										vitalhelpers.Respiratory = "("..SDC.Lang.High..")"
									elseif tonumber(realBP) <= SDC.VitalSettings.BP.UpperCategories.Normal then
										vitalhelpers.BP = "("..SDC.Lang.Normal..")"
										vitalhelpers.Heartrate = "("..SDC.Lang.Normal..")"
										vitalhelpers.Respiratory = "("..SDC.Lang.Normal..")"
									elseif tonumber(realBP) <= SDC.VitalSettings.BP.UpperCategories.High then
										vitalhelpers.BP = "("..SDC.Lang.High..")"
										vitalhelpers.Heartrate = "("..SDC.Lang.Low..")"
										vitalhelpers.Respiratory = "("..SDC.Lang.Low..")"
									end
	
									if allCalls[closestAssitCall].Details.Vitals.BloodSugar <= SDC.VitalSettings.BloodSugar.Low.Max then
										vitalhelpers.BloodSugar ="(".. SDC.Lang.Low..")"
									elseif allCalls[closestAssitCall].Details.Vitals.BloodSugar <= SDC.VitalSettings.BloodSugar.Normal.Max then
										vitalhelpers.BloodSugar = "("..SDC.Lang.Normal..")"
									elseif allCalls[closestAssitCall].Details.Vitals.BloodSugar <= SDC.VitalSettings.BloodSugar.High.Max then
										vitalhelpers.BloodSugar = "("..SDC.Lang.High..")"
									end
	
									if allCalls[closestAssitCall].Details.Vitals.Temperature <= SDC.VitalSettings.Temperature.Low.Max then
										vitalhelpers.Temperature = "("..SDC.Lang.Low..")"
									elseif allCalls[closestAssitCall].Details.Vitals.Temperature <= SDC.VitalSettings.Temperature.Normal.Max then
										vitalhelpers.Temperature = "("..SDC.Lang.Normal..")"
									elseif allCalls[closestAssitCall].Details.Vitals.Temperature <= SDC.VitalSettings.Temperature.High.Max then
										vitalhelpers.Temperature = "("..SDC.Lang.High..")"
									end
								end
	
								local alert = lib.alertDialog({
									header = "# "..SDC.Lang.MedicalEvaluation,
									content = "## **"..SDC.Lang.Name..":**\n\n"..allCalls[closestAssitCall].Details.Name.."\n\n## **"..SDC.Lang.Age..":**\n\n"..allCalls[closestAssitCall].Details.Age.."\n\n## **"..SDC.Lang.Height..":**\n\n"..allCalls[closestAssitCall].Details.Height.." "..SDC.Lang.Measurement.."\n\n## **"..SDC.Lang.Status..":**\n\n"..allCalls[closestAssitCall].Details.Status.."\n\n## **"..SDC.Lang.Vitals..":**\n\n**"..SDC.Lang.BP..":** "..allCalls[closestAssitCall].Details.Vitals.BP.." "..vitalhelpers.BP.."\n\n**"..SDC.Lang.Heartrate..":** "..allCalls[closestAssitCall].Details.Vitals.Heartrate..SDC.Lang.BPM.." "..vitalhelpers.Heartrate.."\n\n**"..SDC.Lang.Respiratory..":** "..allCalls[closestAssitCall].Details.Vitals.RespiratoryRate..SDC.Lang.BPM.." "..vitalhelpers.Respiratory.."\n\n**"..SDC.Lang.BloodSugar..":** "..allCalls[closestAssitCall].Details.Vitals.BloodSugar..SDC.Lang.MGDL.." "..vitalhelpers.BloodSugar.."\n\n**"..SDC.Lang.Temperature..":** "..allCalls[closestAssitCall].Details.Vitals.Temperature..SDC.Lang.Degrees.." "..vitalhelpers.Temperature.."\n\n## **"..SDC.Lang.Injuries..":**\n\n"..injuryTable.."\n\n## **"..SDC.Lang.Complaints..":**\n\n"..complaintTable.."\n\n## **"..SDC.Lang.Observations..":**\n\n"..observationTable,
									centered = true
								})
							else
								local vitalhelpers = {BP = "", Heartrate = "", Respiratory = "", BloodSugar = "", Temperature = ""}
								local injuryTable = nil
								local complaintTable = nil
								local observationTable = nil
	
								for i=1, #allCalls[closestAssitCall].Details.Injuries do
									if injuryTable then
										injuryTable = injuryTable..", "..allCalls[closestAssitCall].Details.Injuries[i]
									else
										injuryTable = allCalls[closestAssitCall].Details.Injuries[i]
									end
								end
								for i=1, #allCalls[closestAssitCall].Details.Complaints do
									if complaintTable then
										complaintTable = complaintTable..", "..allCalls[closestAssitCall].Details.Complaints[i]
									else
										complaintTable = allCalls[closestAssitCall].Details.Complaints[i]
									end
								end
								for i=1, #allCalls[closestAssitCall].Details.Observations do
									if observationTable then
										observationTable = observationTable..", "..allCalls[closestAssitCall].Details.Observations[i]
									else
										observationTable = allCalls[closestAssitCall].Details.Observations[i]
									end
								end
	
	
								if SDC.ShowVitalHelpers then
									local realBP = nil
									realBP = string.sub(allCalls[closestAssitCall].Details.Vitals.BP, 1, 2)
									if string.sub(allCalls[closestAssitCall].Details.Vitals.BP, 3, 3) ~= "/" then
										realBP = realBP..string.sub(allCalls[closestAssitCall].Details.Vitals.BP, 3, 3)
									end
	
									if tonumber(realBP) <= SDC.VitalSettings.BP.UpperCategories.Low then
										vitalhelpers.BP = "("..SDC.Lang.Low..")"
										vitalhelpers.Heartrate = "("..SDC.Lang.High..")"
										vitalhelpers.Respiratory = "("..SDC.Lang.High..")"
									elseif tonumber(realBP) <= SDC.VitalSettings.BP.UpperCategories.Normal then
										vitalhelpers.BP = "("..SDC.Lang.Normal..")"
										vitalhelpers.Heartrate = "("..SDC.Lang.Normal..")"
										vitalhelpers.Respiratory = "("..SDC.Lang.Normal..")"
									elseif tonumber(realBP) <= SDC.VitalSettings.BP.UpperCategories.High then
										vitalhelpers.BP = "("..SDC.Lang.High..")"
										vitalhelpers.Heartrate = "("..SDC.Lang.Low..")"
										vitalhelpers.Respiratory = "("..SDC.Lang.Low..")"
									end
	
									if allCalls[closestAssitCall].Details.Vitals.BloodSugar <= SDC.VitalSettings.BloodSugar.Low.Max then
										vitalhelpers.BloodSugar ="(".. SDC.Lang.Low..")"
									elseif allCalls[closestAssitCall].Details.Vitals.BloodSugar <= SDC.VitalSettings.BloodSugar.Normal.Max then
										vitalhelpers.BloodSugar = "("..SDC.Lang.Normal..")"
									elseif allCalls[closestAssitCall].Details.Vitals.BloodSugar <= SDC.VitalSettings.BloodSugar.High.Max then
										vitalhelpers.BloodSugar = "("..SDC.Lang.High..")"
									end
	
									if allCalls[closestAssitCall].Details.Vitals.Temperature <= SDC.VitalSettings.Temperature.Low.Max then
										vitalhelpers.Temperature = "("..SDC.Lang.Low..")"
									elseif allCalls[closestAssitCall].Details.Vitals.Temperature <= SDC.VitalSettings.Temperature.Normal.Max then
										vitalhelpers.Temperature = "("..SDC.Lang.Normal..")"
									elseif allCalls[closestAssitCall].Details.Vitals.Temperature <= SDC.VitalSettings.Temperature.High.Max then
										vitalhelpers.Temperature = "("..SDC.Lang.High..")"
									end
								end
	
								local alert = lib.alertDialog({
									header = "# "..SDC.Lang.MedicalEvaluation,
									content = "## **"..SDC.Lang.Name..":**\n\n"..allCalls[closestAssitCall].Details.Name.."\n\n## **"..SDC.Lang.Age..":**\n\n"..allCalls[closestAssitCall].Details.Age.."\n\n## **"..SDC.Lang.Height..":**\n\n"..allCalls[closestAssitCall].Details.Height.." "..SDC.Lang.Measurement.."\n\n## **"..SDC.Lang.Status..":**\n\n"..allCalls[closestAssitCall].Details.Status.."\n\n## **"..SDC.Lang.Vitals..":**\n\n**"..SDC.Lang.BP..":** "..allCalls[closestAssitCall].Details.Vitals.BP.." "..vitalhelpers.BP.."\n\n**"..SDC.Lang.Heartrate..":** "..allCalls[closestAssitCall].Details.Vitals.Heartrate..SDC.Lang.BPM.." "..vitalhelpers.Heartrate.."\n\n**"..SDC.Lang.Respiratory..":** "..allCalls[closestAssitCall].Details.Vitals.RespiratoryRate..SDC.Lang.BPM.." "..vitalhelpers.Respiratory.."\n\n**"..SDC.Lang.BloodSugar..":** "..allCalls[closestAssitCall].Details.Vitals.BloodSugar..SDC.Lang.MGDL.." "..vitalhelpers.BloodSugar.."\n\n**"..SDC.Lang.Temperature..":** "..allCalls[closestAssitCall].Details.Vitals.Temperature..SDC.Lang.Degrees.." "..vitalhelpers.Temperature.."\n\n## **"..SDC.Lang.Injuries..":**\n\n"..injuryTable.."\n\n## **"..SDC.Lang.Complaints..":**\n\n"..complaintTable.."\n\n## **"..SDC.Lang.Observations..":**\n\n"..observationTable,
									centered = true
								})
							end
						end
					end
				else
					if not drawingUI or drawingUI ~= "assist2" then
						drawingUI = "assist2"
						lib.showTextUI("["..SDC.Keybinds.PickupPed.Label.."] - "..SDC.Lang.PutPedInStretcher, {
							position = "right-center",
							icon = "hand",
						})
					end

					if IsControlJustReleased(0, SDC.Keybinds.PickupPed.Input) then
						local donetrying = false
						local counter = 0
						repeat 
							if NetworkDoesEntityExistWithNetworkId(allCalls[closestAssitCall].Ped) then
								daped = NetworkGetEntityFromNetworkId(allCalls[closestAssitCall].Ped)
								if not NetworkHasControlOfEntity(daped) then
									NetworkRequestControlOfEntity(daped)
									counter = counter + 1
									if counter >= 100 then
										donetrying = true
									end
								end
							else
								donetrying = true
							end
							Citizen.Wait(100)
						until (NetworkHasControlOfEntity(NetworkGetEntityFromNetworkId(allCalls[closestAssitCall].Ped)) or donetrying)

						if donetrying then
							TriggerEvent("SDMC:Client:Notification", SDC.Lang.CouldntPickupPed, "error")
						else
							daped = NetworkGetEntityFromNetworkId(allCalls[closestAssitCall].Ped)
							AttachEntityToEntity(daped, hasStretcher, 0, SDC.StretcherSettings.OnStrecher.Offset[1].x, SDC.StretcherSettings.OnStrecher.Offset[1].y, SDC.StretcherSettings.OnStrecher.Offset[1].z, SDC.StretcherSettings.OnStrecher.Rotation.x, SDC.StretcherSettings.OnStrecher.Rotation.y, SDC.StretcherSettings.OnStrecher.Rotation.z, true, false, false, true, 1, true)
							LoadAnim("anim@gangops@morgue@table@")
							TaskPlayAnim(daped, "anim@gangops@morgue@table@", "body_search", 8.0, -8.0, -1, 1, 0, false, false, false)
							RemoveAnimDict("anim@gangops@morgue@table@")
							isonstretcher = daped
							TriggerServerEvent("SDMC:Server:PickedUpInjury", allCalls[closestAssitCall].CallType, allCalls[closestAssitCall].CallNum)
						end
					end
				end
			elseif drawingUI and (drawingUI == "assist" or drawingUI == "assist2" )then
				lib.hideTextUI()
				drawingUI = nil
			end

			Citizen.Wait(1)
		else
			Citizen.Wait(500)
		end
	end
end)


Citizen.CreateThread(function()
	while true do
		if hasJob then
			local ped = PlayerPedId()
			local coords = GetEntityCoords(ped)
			if closestVeh and DoesEntityExist(closestVeh) and ((closestAssitCall and Vdist(coords.x, coords.y, coords.z, SDC.CallCoords[allCalls[closestAssitCall].CallNum]) <= 75) or selectedHospital) then
				local tcoords = GetOffsetFromEntityInWorldCoords(closestVeh, vehConversion[tostring(GetEntityModel(closestVeh))].GrabOffset[1].x, vehConversion[tostring(GetEntityModel(closestVeh))].GrabOffset[1].y, vehConversion[tostring(GetEntityModel(closestVeh))].GrabOffset[1].z)

				if Vdist(coords.x, coords.y, coords.z, tcoords) <= 1.0 then
					if not hasStretcher then
						if not drawingUI or drawingUI ~= "stretcher" then
							drawingUI = "stretcher"
							if not isonstretcher then
								lib.showTextUI("["..SDC.Keybinds.GrabStretcher.Label.."] - "..SDC.Lang.GrabStretcher, {
									position = "right-center",
									icon = "hand",
								})
							else
								lib.showTextUI("["..SDC.Keybinds.GrabStretcher.Label.."] - "..SDC.Lang.GrabStretcher2, {
									position = "right-center",
									icon = "hand",
								})
							end
						end

						if IsControlJustReleased(0, SDC.Keybinds.GrabStretcher.Input) then
							TriggerEvent("SDMC:Client:StretcherLoop")
						end
					else
						if not drawingUI or drawingUI ~= "stretcher2" then
							drawingUI = "stretcher2"
							if isonstretcher then
								lib.showTextUI("["..SDC.Keybinds.GrabStretcher.Label.."] - "..SDC.Lang.StoreStretcher2, {
									position = "right-center",
									icon = "hand",
								})
							else
								lib.showTextUI("["..SDC.Keybinds.GrabStretcher.Label.."] - "..SDC.Lang.StoreStretcher, {
									position = "right-center",
									icon = "hand",
								})
							end
						end

						if IsControlJustReleased(0, SDC.Keybinds.GrabStretcher.Input) then
							if not isonstretcher then
								if DoesEntityExist(hasStretcher) then
									DeleteEntity(hasStretcher)
								end
								hasStretcher = nil
							else
								DetachEntity(hasStretcher, true, false)
								stretcherinback = hasStretcher
								hasStretcher = nil
								AttachEntityToEntity(stretcherinback, closestVeh, 0, 0.0, -2.0, 0.5, 0.0, 0.0, 0.0, true, false, false, true, 1, true)
								local minDist = 5000
								local theHospital = 0
								for i=1, #SDC.HospitalDropOff do
									dist = Vdist(coords.x, coords.y, coords.z, SDC.HospitalDropOff[i].DropOffCoords)
									if dist < minDist then
										minDist = dist
										theHospital = i
									end
								end
								local hospitalBlip = AddBlipForCoord(SDC.HospitalDropOff[theHospital].DropOffCoords.x, SDC.HospitalDropOff[theHospital].DropOffCoords.y, SDC.HospitalDropOff[theHospital].DropOffCoords.z)
								SetBlipSprite(hospitalBlip, SDC.DropOffBlip.Sprite)
								SetBlipScale(hospitalBlip, SDC.DropOffBlip.Size)
								SetBlipColour(hospitalBlip, SDC.DropOffBlip.Color)
								BeginTextCommandSetBlipName("STRING")
								AddTextComponentString(SDC.Lang.DropOffBlip)
								EndTextCommandSetBlipName(hospitalBlip)
								allBlips["HospitalBlip"] = hospitalBlip
								selectedHospital = theHospital
								TriggerEvent("SDMC:Client:Notification", SDC.Lang.DropoffAtHospital.." "..SDC.HospitalDropOff[theHospital].Label.."!", "primary")
							end
						end
					end
					Citizen.Wait(1)
				else
					if drawingUI and (drawingUI == "stretcher" or drawingUI == "stretcher2") then
						lib.hideTextUI()
						drawingUI = nil
					end
					Citizen.Wait(500)
				end
			elseif closestVeh and DoesEntityExist(closestVeh) and ((closestTransportCall and Vdist(coords.x, coords.y, coords.z, SDC.PickupDropoffs[allCalls[closestTransportCall].CallNum].Coords) <= 75) or selectedDropoff) then
				local tcoords = GetOffsetFromEntityInWorldCoords(closestVeh, vehConversion[tostring(GetEntityModel(closestVeh))].GrabOffset[1].x, vehConversion[tostring(GetEntityModel(closestVeh))].GrabOffset[1].y, vehConversion[tostring(GetEntityModel(closestVeh))].GrabOffset[1].z)

				if Vdist(coords.x, coords.y, coords.z, tcoords) <= 1.0 then
					if not hasStretcher then
						if not drawingUI or drawingUI ~= "stretcher" then
							drawingUI = "stretcher"
							if not isonstretcher then
								lib.showTextUI("["..SDC.Keybinds.GrabStretcher.Label.."] - "..SDC.Lang.GrabStretcher, {
									position = "right-center",
									icon = "hand",
								})
							else
								lib.showTextUI("["..SDC.Keybinds.GrabStretcher.Label.."] - "..SDC.Lang.GrabStretcher2, {
									position = "right-center",
									icon = "hand",
								})
							end
						end

						if IsControlJustReleased(0, SDC.Keybinds.GrabStretcher.Input) then
							TriggerEvent("SDMC:Client:StretcherLoop")
						end
					else
						if not drawingUI or drawingUI ~= "stretcher2" then
							drawingUI = "stretcher2"
							if isonstretcher then
								lib.showTextUI("["..SDC.Keybinds.GrabStretcher.Label.."] - "..SDC.Lang.StoreStretcher2, {
									position = "right-center",
									icon = "hand",
								})
							else
								lib.showTextUI("["..SDC.Keybinds.GrabStretcher.Label.."] - "..SDC.Lang.StoreStretcher, {
									position = "right-center",
									icon = "hand",
								})
							end
						end

						if IsControlJustReleased(0, SDC.Keybinds.GrabStretcher.Input) then
							if not isonstretcher then
								if DoesEntityExist(hasStretcher) then
									DeleteEntity(hasStretcher)
								end
								hasStretcher = nil
							else
								DetachEntity(hasStretcher, true, false)
								stretcherinback = hasStretcher
								hasStretcher = nil
								AttachEntityToEntity(stretcherinback, closestVeh, 0, 0.0, -2.0, 0.5, 0.0, 0.0, 0.0, true, false, false, true, 1, true)
								local minDist = 5000
								local theHospital = 0
								repeat
									theHospital = math.random(1, #SDC.PickupDropoffs)

									if theHospital == allCalls[closestTransportCall].CallNum then
										theHospital = 0
									end
								until theHospital > 0 

								local hospitalBlip = AddBlipForCoord(SDC.PickupDropoffs[theHospital].Coords.x, SDC.PickupDropoffs[theHospital].Coords.y, SDC.PickupDropoffs[theHospital].Coords.z)
								SetBlipSprite(hospitalBlip, SDC.DropOffBlip.Sprite)
								SetBlipScale(hospitalBlip, SDC.DropOffBlip.Size)
								SetBlipColour(hospitalBlip, SDC.DropOffBlip.Color)
								BeginTextCommandSetBlipName("STRING")
								AddTextComponentString(SDC.Lang.DropOffBlip)
								EndTextCommandSetBlipName(hospitalBlip)
								allBlips["HospitalBlip"] = hospitalBlip
								selectedDropoff = theHospital
								TriggerEvent("SDMC:Client:Notification", SDC.Lang.DropoffAtHospital.." "..SDC.PickupDropoffs[theHospital].Label.."!", "primary")
							end
						end
					end
					Citizen.Wait(1)
				else
					if drawingUI and (drawingUI == "stretcher" or drawingUI == "stretcher2") then
						lib.hideTextUI()
						drawingUI = nil
					end
					Citizen.Wait(500)
				end
			else
				Citizen.Wait(500)
			end
		else
			Citizen.Wait(1000)
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		if hasJob and selectedHospital then
			if hasStretcher and Vdist(coords.x, coords.y, coords.z, SDC.HospitalDropOff[selectedHospital].DropOffCoords) <= 1.5 then
				if not drawingUI or drawingUI ~= "dropoff" then
					drawingUI = "dropoff"
					lib.showTextUI("["..SDC.Keybinds.DropoffPed.Label.."] - "..SDC.Lang.DropOffBlip, {
						position = "right-center",
						icon = "hand",
					})
				end

				if IsControlJustReleased(0, SDC.Keybinds.DropoffPed.Input) then
					TriggerServerEvent("SDMC:Server:DropoffDone")
					if DoesBlipExist(allBlips["HospitalBlip"]) then
						RemoveBlip(allBlips["HospitalBlip"])
					end
					allBlips["HospitalBlip"] = nil
					if hasStretcher and DoesEntityExist(hasStretcher) then
						DeleteEntity(hasStretcher)
					end
					hasStretcher = nil
					if isonstretcher and DoesEntityExist(isonstretcher) then
						DeleteEntity(isonstretcher)
					end
					isonstretcher = nil
					selectedHospital = nil
				end
				Citizen.Wait(1)
			else
				if drawingUI and drawingUI == "dropoff" then
					lib.hideTextUI()
					drawingUI = nil
				end
				Citizen.Wait(500)
			end
		elseif hasJob and selectedDropoff and Vdist(coords.x, coords.y, coords.z, SDC.PickupDropoffs[selectedDropoff].Coords) <= 1.5 then
			if not drawingUI or drawingUI ~= "dropoff" then
				drawingUI = "dropoff"
				lib.showTextUI("["..SDC.Keybinds.DropoffPed.Label.."] - "..SDC.Lang.DropTransportPatient, {
					position = "right-center",
					icon = "hand",
				})
			end

			if IsControlJustReleased(0, SDC.Keybinds.DropoffPed.Input) then
				TriggerServerEvent("SDMC:Server:DropoffDone")
				if DoesBlipExist(allBlips["HospitalBlip"]) then
					RemoveBlip(allBlips["HospitalBlip"])
				end
				allBlips["HospitalBlip"] = nil
				if hasStretcher and DoesEntityExist(hasStretcher) then
					DeleteEntity(hasStretcher)
				end
				hasStretcher = nil
				if isonstretcher and DoesEntityExist(isonstretcher) then
					DeleteEntity(isonstretcher)
				end
				isonstretcher = nil
				selectedDropoff = nil
			end
			Citizen.Wait(1)
		else
			if drawingUI and drawingUI == "dropoff" then
				lib.hideTextUI()
				drawingUI = nil
			end
			Citizen.Wait(1000)
		end
	end
end)

RegisterNetEvent("SDMC:Client:StretcherLoop")
AddEventHandler("SDMC:Client:StretcherLoop", function()
	local myped = PlayerPedId()
	local coords = GetEntityCoords(myped)

	if not stretcherinback then
		LoadPropDict(SDC.StretcherModel)
		local dastretcher = CreateObject(GetHashKey(SDC.StretcherModel), coords.x, coords.y, coords.z - 10,  true,  true, false)
		AttachEntityToEntity(dastretcher, myped, GetEntityBoneIndexByName(myped,"SKEL_Spine1"), SDC.StretcherSettings.Pushing.Offset[1].x, SDC.StretcherSettings.Pushing.Offset[1].y, SDC.StretcherSettings.Pushing.Offset[1].z, SDC.StretcherSettings.Pushing.Rotation.x, SDC.StretcherSettings.Pushing.Rotation.y, SDC.StretcherSettings.Pushing.Rotation.z, true, false, false, true, 1, true)
		SetModelAsNoLongerNeeded(SDC.StretcherModel)
		hasStretcher = dastretcher
	else
		hasStretcher = stretcherinback
		stretcherinback = nil
		DetachEntity(hasStretcher, true, false)
		AttachEntityToEntity(hasStretcher, myped, GetEntityBoneIndexByName(myped,"SKEL_Spine1"), SDC.StretcherSettings.Pushing.Offset[1].x, SDC.StretcherSettings.Pushing.Offset[1].y, SDC.StretcherSettings.Pushing.Offset[1].z, SDC.StretcherSettings.Pushing.Rotation.x, SDC.StretcherSettings.Pushing.Rotation.y, SDC.StretcherSettings.Pushing.Rotation.z, true, false, false, true, 1, true)
	end


	LoadAnim("anim@amb@clubhouse@bar@drink@idle_a")
	TaskPlayAnim(myped, "anim@amb@clubhouse@bar@drink@idle_a", "idle_a_bartender", 8.0, 8.0, -1, 49, 1, 0, 0, 0)
	RemoveAnimDict("anim@amb@clubhouse@bar@drink@idle_a")

	while hasStretcher do
		local ped = PlayerPedId()
		if not IsEntityPlayingAnim(ped, "anim@amb@clubhouse@bar@drink@idle_a", "idle_a_bartender", 3) then
			LoadAnim("anim@amb@clubhouse@bar@drink@idle_a")
			TaskPlayAnim(ped, "anim@amb@clubhouse@bar@drink@idle_a", "idle_a_bartender", 8.0, 8.0, -1, 49, 1, 0, 0, 0)
			RemoveAnimDict("anim@amb@clubhouse@bar@drink@idle_a")
		end
		Wait(500)
	end
	ClearPedTasksImmediately(myped)
end)



Citizen.CreateThread(function()
	while true do
		if hasJob and closestTransportCall and allCalls[closestTransportCall] then
			local ped = PlayerPedId()
			local coords = GetEntityCoords(ped)
			if Vdist(coords.x, coords.y, coords.z, SDC.PickupDropoffs[allCalls[closestTransportCall].CallNum].Coords) <= 1.5 and hasStretcher and not allCalls[closestTransportCall].PickedUp then
				if not drawingUI or drawingUI ~= "trans_pickup" then
					drawingUI = "trans_pickup"
					lib.showTextUI("["..SDC.Keybinds.PickupPed.Label.."] - "..SDC.Lang.GrabTransportPatient, {
						position = "right-center",
						icon = "hand",
					})
				end

				if IsControlJustReleased(0, SDC.Keybinds.PickupPed.Input) then
					TriggerServerEvent("SDMC:Server:PickedUpTransport", allCalls[closestTransportCall].CallType, allCalls[closestTransportCall].CallNum)
					lib.hideTextUI()
					drawingUI = nil
					FreezeEntityPosition(ped, true)
					DoProgressbar(SDC.PickupAnimTime*1000, SDC.Lang.GrabbingPatient)
					FreezeEntityPosition(ped, false)
					LoadPropDict(allCalls[closestTransportCall].PedModel)
					local daped = CreatePed(5, GetHashKey(allCalls[closestTransportCall].PedModel), coords.x, coords.y, coords -10, 0.0, true, false)
					SetBlockingOfNonTemporaryEvents(daped, true)
					SetPedDropsWeaponsWhenDead(daped, false)
					SetModelAsNoLongerNeeded(allCalls[closestTransportCall].PedModel)
					AttachEntityToEntity(daped, hasStretcher, 0, SDC.StretcherSettings.OnStrecher.Offset[1].x, SDC.StretcherSettings.OnStrecher.Offset[1].y, SDC.StretcherSettings.OnStrecher.Offset[1].z, SDC.StretcherSettings.OnStrecher.Rotation.x, SDC.StretcherSettings.OnStrecher.Rotation.y, SDC.StretcherSettings.OnStrecher.Rotation.z, true, false, false, true, 1, true)
					LoadAnim("anim@gangops@morgue@table@")
					TaskPlayAnim(daped, "anim@gangops@morgue@table@", "body_search", 8.0, -8.0, -1, 1, 0, false, false, false)
					RemoveAnimDict("anim@gangops@morgue@table@")
					isonstretcher = daped

					TriggerEvent("SDMC:Client:Notification", SDC.Lang.StoreStretcher2, "primary")
				end
				Citizen.Wait(1)
			else
				if drawingUI and drawingUI == "trans_pickup" then
					lib.hideTextUI()
					drawingUI = nil
				end
				Citizen.Wait(500)
			end
		else
			if drawingUI and drawingUI == "trans_pickup" then
				lib.hideTextUI()
				drawingUI = nil
			end
			Citizen.Wait(1000)
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		local drawing = false

		if SDC.Icons.Checkup.Enabled and closestAssitCall and not allCalls[closestAssitCall].CheckupDone and Vdist(coords.x, coords.y, coords.z, SDC.CallCoords[allCalls[closestAssitCall].CallNum]) <= SDC.Icons.Checkup.DistToDraw then
			drawing = true
			local drawC = SDC.CallCoords[allCalls[closestAssitCall].CallNum]
			SetDrawOrigin(drawC.x, drawC.y, drawC.z -0.5, 0)
			DrawSprite("medcall_sprites", "clipboard", 0.0, 0.0, 0.025, 0.04, 0, 230, 230, 230, 255)
			ClearDrawOrigin()
		end

		if SDC.Icons.PutOnStrecher.Enabled and closestAssitCall and allCalls[closestAssitCall].CheckupDone and hasStretcher and not allCalls[closestAssitCall].Grabbed and Vdist(coords.x, coords.y, coords.z, SDC.CallCoords[allCalls[closestAssitCall].CallNum]) <= SDC.Icons.PutOnStrecher.DistToDraw then
			drawing = true
			local drawC = SDC.CallCoords[allCalls[closestAssitCall].CallNum]
			SetDrawOrigin(drawC.x, drawC.y, drawC.z - 0.5, 0)
			DrawSprite("medcall_sprites", "put_on_stretcher", 0.0, 0.0, 0.03, 0.04, 0, 230, 230, 230, 255)
			ClearDrawOrigin()
		end

		if SDC.Icons.Stretcher.Enabled and closestVeh and DoesEntityExist(closestVeh) and GetVehiclePedIsIn(ped, false) == 0 then
			local tcoords = GetOffsetFromEntityInWorldCoords(closestVeh, vehConversion[tostring(GetEntityModel(closestVeh))].GrabOffset[1].x, vehConversion[tostring(GetEntityModel(closestVeh))].GrabOffset[1].y, vehConversion[tostring(GetEntityModel(closestVeh))].GrabOffset[1].z)
			if (closestAssitCall and Vdist(coords.x, coords.y, coords.z, SDC.CallCoords[allCalls[closestAssitCall].CallNum]) <= 75) or selectedHospital then
				if Vdist(coords.x, coords.y, coords.z, tcoords) <= SDC.Icons.Stretcher.DistToDraw then
					drawing = true
					local drawC = tcoords
					SetDrawOrigin(drawC.x, drawC.y, drawC.z, 0)
					DrawSprite("medcall_sprites", "stretcher", 0.0, 0.0, 0.04, 0.05, 0, 230, 230, 230, 255)
					ClearDrawOrigin()
				end
			elseif (closestTransportCall and Vdist(coords.x, coords.y, coords.z, SDC.PickupDropoffs[allCalls[closestTransportCall].CallNum].Coords) <= 75) or selectedDropoff then
				if Vdist(coords.x, coords.y, coords.z, tcoords) <= SDC.Icons.Stretcher.DistToDraw then
					drawing = true
					local drawC = tcoords
					SetDrawOrigin(drawC.x, drawC.y, drawC.z, 0)
					DrawSprite("medcall_sprites", "stretcher", 0.0, 0.0, 0.04, 0.05, 0, 230, 230, 230, 255)
					ClearDrawOrigin()
				end
			end
		end

		if SDC.Icons.Transports.Enabled and closestTransportCall and not allCalls[closestTransportCall].PickedUp and hasStretcher and Vdist(coords.x, coords.y, coords.z, SDC.PickupDropoffs[allCalls[closestTransportCall].CallNum].Coords) <= SDC.Icons.Transports.DistToDraw then
			drawing = true
			local drawC = SDC.PickupDropoffs[allCalls[closestTransportCall].CallNum].Coords
			SetDrawOrigin(drawC.x, drawC.y, drawC.z, 0)
			DrawSprite("medcall_sprites", "dropoff", 0.0, 0.0, 0.04, 0.05, 0, 230, 230, 230, 255)
			ClearDrawOrigin()
		elseif SDC.Icons.Transports.Enabled and selectedDropoff and hasStretcher and Vdist(coords.x, coords.y, coords.z, SDC.PickupDropoffs[selectedDropoff].Coords) <= SDC.Icons.Transports.DistToDraw then
			drawing = true
			local drawC = SDC.PickupDropoffs[selectedDropoff].Coords
			SetDrawOrigin(drawC.x, drawC.y, drawC.z, 0)
			DrawSprite("medcall_sprites", "dropoff", 0.0, 0.0, 0.04, 0.05, 0, 230, 230, 230, 255)
			ClearDrawOrigin()
		end

		if SDC.Icons.DropOff.Enabled and hasStretcher and selectedHospital and Vdist(coords.x, coords.y, coords.z, SDC.HospitalDropOff[selectedHospital].DropOffCoords) <= SDC.Icons.DropOff.DistToDraw then
			drawing = true
			local drawC = SDC.HospitalDropOff[selectedHospital].DropOffCoords
			SetDrawOrigin(drawC.x, drawC.y, drawC.z, 0)
			DrawSprite("medcall_sprites", "dropoff", 0.0, 0.0, 0.04, 0.05, 0, 230, 230, 230, 255)
			ClearDrawOrigin()
		end

		if drawing then
			Citizen.Wait(1)
		else
			Citizen.Wait(500)
		end
	end
end)




AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for k,v in pairs(PlayerHasProp) do
            DeleteEntity(v)
        end

		if hasStretcher and DoesEntityExist(hasStretcher) then
			DeleteEntity(hasStretcher)
		end
		if stretcherinback and DoesEntityExist(stretcherinback) then
			DeleteEntity(stretcherinback)
		end
	end
end)

---------------------------------------------------------------------
-------------------------Functions-----------------------------------
---------------------------------------------------------------------
function MakeEntityFaceEntity(entity1, entity2)
	local p1 = GetEntityCoords(entity1, true)
	local p2 = GetEntityCoords(entity2, true)

	local dx = p2.x - p1.x
	local dy = p2.y - p1.y

	local heading = GetHeadingFromVector_2d(dx, dy)
	SetEntityHeading( entity1, heading )
end

function LoadPropDict(model)
	while not HasModelLoaded(GetHashKey(model)) do
	  RequestModel(GetHashKey(model))
	  Wait(10)
	end
end

function LoadAnim(dict)
	while not HasAnimDictLoaded(dict) do
	  RequestAnimDict(dict)
	  Wait(10)
	end
end

function AddPropToPlayer(prop1, bone, off1, off2, off3, rot1, rot2, rot3, namies, player, network)
	local Player = nil
	if player ~= nil then
		Player = player
	else
		Player = PlayerPedId()
	end
	local x,y,z = table.unpack(GetEntityCoords(Player))
  
	if not HasModelLoaded(prop1) then
	  LoadPropDict(prop1)
	end
  
	if network then
		prop = CreateObject(GetHashKey(prop1), x, y, z+0.2,  true,  true, true)
		AttachEntityToEntity(prop, Player, GetPedBoneIndex(Player, bone), off1, off2, off3, rot1, rot2, rot3, true, true, false, true, 1, true)
        PlayerHasProp[namies] = prop
		SetModelAsNoLongerNeeded(prop1)
	else
		prop = CreateObject(GetHashKey(prop1), x, y, z+0.2,  false,  true, true)
		AttachEntityToEntity(prop, Player, GetPedBoneIndex(Player, bone), off1, off2, off3, rot1, rot2, rot3, true, true, false, true, 1, true)
		PlayerHasProp[namies] = prop
		SetModelAsNoLongerNeeded(prop1)
	end
end
function RemovePropFromPlayer(namies)
    for k,v in pairs(PlayerHasProp) do
        if k == namies then
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
            PlayerHasProp[k] = nil
        end
    end
end

--Enums
local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
		local iter, id = initFunc()
		if not id or id == 0 then
			disposeFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = disposeFunc}
		setmetatable(enum, entityEnumerator)
		local next = true

		repeat
			coroutine.yield(id)
			next, id = moveFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		disposeFunc(iter)
	end)
end

function EnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
	local nearbyEntities = {}

	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		local playerPed = PlayerPedId()
		coords = GetEntityCoords(playerPed)
	end

	for k,entity in pairs(entities) do
		local distance = #(coords - GetEntityCoords(entity))

		if distance <= maxDistance then
			table.insert(nearbyEntities, isPlayerEntities and k or entity)
		end
	end

	return nearbyEntities
end

function EnumerateObjects()
	return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
	return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
	return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumeratePickups()
	return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end