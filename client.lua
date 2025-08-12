local ESX = exports["es_extended"]:getSharedObject()
local isStabilizing = false
local hasShownNotification = false
local currentVehicle = nil
local targetAltitude = nil

local function IsHelicopter(vehicle)
    return GetVehicleClass(vehicle) == 15
end

local function StabilizeHelicopter(vehicle)
    if DoesEntityExist(vehicle) then
        local velocity = GetEntityVelocity(vehicle)
        local rotation = GetEntityRotation(vehicle, 2)
        local currentPos = GetEntityCoords(vehicle)
        
        local stabilizationForce = 0.985
        SetEntityRotation(vehicle, rotation.x * stabilizationForce, rotation.y * stabilizationForce, rotation.z, 2, true)
        
        if targetAltitude then
            local altitudeDiff = targetAltitude - currentPos.z
            local newVelocityZ = velocity.z
            
            if math.abs(altitudeDiff) > 1.0 then
                newVelocityZ = altitudeDiff * 0.3
            elseif math.abs(altitudeDiff) > 0.2 then
                newVelocityZ = altitudeDiff * 0.15
            else
                newVelocityZ = velocity.z * 0.9
            end
            
            SetEntityVelocity(vehicle, velocity.x * 0.99, velocity.y * 0.99, newVelocityZ)
        else
            SetEntityVelocity(vehicle, velocity.x * 0.99, velocity.y * 0.99, velocity.z)
        end
    end
end

local function ShowNotification(message)
    ESX.ShowNotification(message)
end

CreateThread(function()
    while true do
        Wait(0)
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
            if IsHelicopter(vehicle) then
                currentVehicle = vehicle
                
                if not hasShownNotification then
                    ESX.ShowNotification("~b~Appuyez sur [X] pour activer/désactiver la stabilisation de l'hélicoptère")
                    hasShownNotification = true
                end
                
                if IsControlJustPressed(0, 73) then
                    isStabilizing = not isStabilizing
                    
                    if isStabilizing then
                        local pos = GetEntityCoords(vehicle)
                        targetAltitude = pos.z
                        ESX.ShowNotification(("~g~Stabilisation activée"), 3500)
                    else
                        targetAltitude = nil
                        ESX.ShowNotification(("~r~Stabilisation désactivée"), 2500)
                    end
                end
                
                if isStabilizing then
                    StabilizeHelicopter(vehicle)
                end
            else
                if currentVehicle ~= vehicle then
                    isStabilizing = false
                    hasShownNotification = false
                    currentVehicle = nil
                    targetAltitude = nil
                end
            end
        else
            if currentVehicle then
                isStabilizing = false
                hasShownNotification = false
                currentVehicle = nil
                targetAltitude = nil
            end
        end
    end
end)
