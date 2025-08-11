local ESX = exports["es_extended"]:getSharedObject()
local isStabilizing = false
local hasShownNotification = false
local currentVehicle = nil
local targetAltitude = nil

-- Fonction pour vérifier si le véhicule est un hélicoptère
local function IsHelicopter(vehicle)
    return GetVehicleClass(vehicle) == 15
end

-- Fonction pour stabiliser l'hélicoptère
local function StabilizeHelicopter(vehicle)
    if DoesEntityExist(vehicle) then
        local velocity = GetEntityVelocity(vehicle)
        local rotation = GetEntityRotation(vehicle, 2)
        local currentPos = GetEntityCoords(vehicle)
        
        -- Stabilisation progressive de la rotation (réduction plus douce du tangage et du roulis)
        local stabilizationForce = 0.985  -- Plus proche de 1 = plus doux
        SetEntityRotation(vehicle, rotation.x * stabilizationForce, rotation.y * stabilizationForce, rotation.z, 2, true)
        
        -- Maintien de l'altitude
        if targetAltitude then
            local altitudeDiff = targetAltitude - currentPos.z
            local newVelocityZ = velocity.z
            
            -- Ajustement progressif de la vélocité verticale pour maintenir l'altitude
            if math.abs(altitudeDiff) > 1.0 then
                newVelocityZ = altitudeDiff * 0.3  -- Force réduite pour un mouvement plus doux
            elseif math.abs(altitudeDiff) > 0.2 then
                newVelocityZ = altitudeDiff * 0.15  -- Force encore plus réduite pour les petits ajustements
            else
                newVelocityZ = velocity.z * 0.9  -- Réduction très douce de la vélocité verticale
            end
            
            -- Stabilisation complète avec maintien d'altitude progressif
            SetEntityVelocity(vehicle, velocity.x * 0.99, velocity.y * 0.99, newVelocityZ)
        else
            -- Stabilisation horizontale seulement
            SetEntityVelocity(vehicle, velocity.x * 0.99, velocity.y * 0.99, velocity.z)
        end
    end
end

-- Fonction pour afficher les notifications
local function ShowNotification(message)
    ESX.ShowNotification(message)
end

-- Thread principal
CreateThread(function()
    while true do
        Wait(0)
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
            if IsHelicopter(vehicle) then
                currentVehicle = vehicle
                
                -- Afficher la notification la première fois
                if not hasShownNotification then
                    ESX.ShowNotification("~b~Appuyez sur [X] pour activer/désactiver la stabilisation de l'hélicoptère")
                    hasShownNotification = true
                end
                
                -- Vérifier si la touche X est pressée
                if IsControlJustPressed(0, 73) then -- 73 = X key
                    isStabilizing = not isStabilizing
                    
                    if isStabilizing then
                        -- Enregistrer l'altitude actuelle comme référence
                        local pos = GetEntityCoords(vehicle)
                        targetAltitude = pos.z
                        ESX.ShowNotification(("~g~Stabilisation activée"), 3500)
                    else
                        targetAltitude = nil
                        ESX.ShowNotification(("~r~Stabilisation désactivée"), 2500)
                    end
                end
                
                -- Appliquer la stabilisation si activée
                if isStabilizing then
                    StabilizeHelicopter(vehicle)
                end
            else
                -- Réinitialiser si ce n'est pas un hélicoptère
                if currentVehicle ~= vehicle then
                    isStabilizing = false
                    hasShownNotification = false
                    currentVehicle = nil
                    targetAltitude = nil
                end
            end
        else
            -- Réinitialiser si le joueur n'est plus dans un véhicule ou n'est plus pilote
            if currentVehicle then
                isStabilizing = false
                hasShownNotification = false
                currentVehicle = nil
                targetAltitude = nil
            end
        end
    end
end)