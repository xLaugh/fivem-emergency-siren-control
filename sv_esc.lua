local vehicleStates = {}

RegisterNetEvent('esc:setSirenState')
AddEventHandler('esc:setSirenState', function(netId, enabled)
    local source = source
    
    if not netId or netId == 0 then
        return
    end
    
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then
        return
    end
    
    local playerPed = GetPlayerPed(source)
    if not playerPed or playerPed == 0 then
        return
    end
    
    vehicleStates[netId] = enabled
    
    local entity = Entity(vehicle)
    entity.state.esc_siren_enabled = enabled
    
    TriggerClientEvent('esc:updateSirenState', -1, netId, enabled)
    
    if GetConvar('esc_debug', 'false') == 'true' then
        print(string.format('[ESC] Joueur %s (%d) a %s les sirènes du véhicule (NetID: %d)', 
            GetPlayerName(source), source, enabled and 'activé' or 'désactivé', netId))
    end
end)

RegisterNetEvent('esc:requestVehicleState')
AddEventHandler('esc:requestVehicleState', function(netId)
    local source = source
    
    if netId and vehicleStates[netId] ~= nil then
        TriggerClientEvent('esc:updateSirenState', source, netId, vehicleStates[netId])
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(30000)
        
        local toRemove = {}
        for netId, _ in pairs(vehicleStates) do
            local vehicle = NetworkGetEntityFromNetworkId(netId)
            if not DoesEntityExist(vehicle) then
                table.insert(toRemove, netId)
            end
        end
        
        for _, netId in ipairs(toRemove) do
            vehicleStates[netId] = nil
            if GetConvar('esc_debug', 'false') == 'true' then
                print(string.format('[ESC] Nettoyage véhicule supprimé (NetID: %d)', netId))
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
end)

RegisterCommand('esc_debug', function(source, args)
    if source == 0 then
        local newState = args[1] == 'true' and 'true' or 'false'
        SetConvar('esc_debug', newState)
        print('[ESC] Debug mode: ' .. newState)
        
        if newState == 'true' then
            print('[ESC] États des véhicules:')
            for netId, enabled in pairs(vehicleStates) do
                print(string.format('  NetID %d: %s', netId, enabled and 'activé' or 'désactivé'))
            end
        end
    end
end, true)

Citizen.CreateThread(function()
    print('[ESC] Emergency Siren Control - Serveur démarré')
    print('[ESC] Synchronisation des sirènes activée')
    print('[ESC] Utilisez "esc_debug true" en console pour activer le debug')
end) 