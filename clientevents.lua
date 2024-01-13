ESX = exports["es_extended"]:getSharedObject()
local blip = nil
local sacs = {}
local deleteSac = {}

RegisterNetEvent('eventsfourgon:spawnArgentProps')
AddEventHandler('eventsfourgon:spawnArgentProps', function(vehicleProps, sacsCoords, montant)
    local coords = vehicleProps.coords
    local heading = vehicleProps.heading

    if not montant or montant <= 0 then
        print("Montant non défini ou égal à zéro!")
        return
    end

    local nombreSacs = math.ceil(montant / 500)

    sacs = {}

    for i = 1, nombreSacs do
        local sacCoord = sacsCoords[i]
        table.insert(sacs, {model = 'prop_money_bag_01', x = sacCoord.x, y = sacCoord.y, z = sacCoord.z, pickup = false})
    end

    --print("spawnArgentProps - Coords:", coords.x, coords.y, coords.z)

    local model = GetHashKey(vehicleProps.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end

    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)

    for _, sac in ipairs(sacs) do
        local prop = CreateObject(GetHashKey(sac.model), sac.x, sac.y, sac.z, true, false, true)
        table.insert(deleteSac, prop)
        -- SetEntityHeading(prop, heading)
        -- SetEntityHasGravity(prop, false)
        SetEntityCollision(prop, false, false)
        FreezeEntityPosition(prop, true)
    end

    if not DoesBlipExist(blip) then
        blip = AddBlipForEntity(vehicle)
    end

    TriggerEvent('eventsfourgon:syncSacs', sacsCoords, heading)
end)

RegisterNetEvent('eventsfourgon:supprimerSac')
AddEventHandler('eventsfourgon:supprimerSac', function(sacIndex)
    local sac = sacs[sacIndex]
    coords = GetEntityCoords(deleteSac[sacIndex])
    if sac then
        if coords.x == sacs[sacIndex].x then 
            DeleteEntity(deleteSac[sacIndex])
            table.remove(deleteSac, sacIndex)
            sac.model = nil
            table.remove(sacs, sacIndex)
        end
    else
        print('Sac non trouvé avec l\'index côté client:', sacIndex)  -- Ajout d'un message de débogage
    end
end)





RegisterNetEvent('eventsfourgon:convoiArrete')
AddEventHandler('eventsfourgon:convoiArrete', function()
    TriggerEvent('esx:showNotification', 'Le convoi s\'est arrêté.')

    if DoesBlipExist(blip) then
        RemoveBlip(blip)
        blip = nil
    end
end)

RegisterNetEvent('eventsfourgon:syncSacs')
AddEventHandler('eventsfourgon:syncSacs', function(syncedSacs, heading)
    for i, sacCoord in ipairs(syncedSacs) do
        local sacExists = false

        -- Vérifier si le sac existe déjà dans la table
        for j, existingSac in ipairs(sacs) do
            if existingSac.x == sacCoord.x and existingSac.y == sacCoord.y and existingSac.z == sacCoord.z then
                sacExists = true
                break
            end
        end

        -- Si le sac n'existe pas, l'ajouter
        if not sacExists then
            local newSac = {model = 'prop_money_bag_01', x = sacCoord.x, y = sacCoord.y, z = sacCoord.z, pickup = false}
            table.insert(sacs, newSac)

            -- Créer l'objet sac
            newSac.object = CreateObject(GetHashKey(newSac.model), newSac.x, newSac.y, newSac.z, true, false, true)
            SetEntityHeading(newSac.object, heading)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if sacs then
            for i, sac in ipairs(sacs) do
                if sac then
                    local playerPed = GetPlayerPed(-1)
                    local playerCoords = GetEntityCoords(playerPed)
                    local sacCoords = vector3(sac.x, sac.y, sac.z)
                    local distance = Vdist(playerCoords, sacCoords)

                   -- print("Distance au sac " .. i .. ": " .. distance)  -- Ajout du message de débogage

                    if distance < 2.0 then
                        -- print("Appuyez sur E pour ramasser l'argent")  -- Ajout du message de débogage

                        -- Ajoutez des messages de débogage pour afficher l'index côté client
                        TriggerEvent('eventsfourgon:debugIndex', 'Index côté client: ' .. i)

                        DisplayHelpText("Appuyez sur ~INPUT_CONTEXT~ pour ramasser l'argent")

                        if IsControlJustPressed(0, 38) then
                            local montant = 500
                            TriggerServerEvent('eventsfourgon:ramasserArgent', i, montant)
                        end
                    end
                end
            end
        end
    end
end)

-- Gestionnaire d'événements pour afficher les messages de débogage
RegisterNetEvent('eventsfourgon:debugIndex')
AddEventHandler('eventsfourgon:debugIndex', function(message)
    -- print(message)
end)




function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end