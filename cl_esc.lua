local CONTROLS = {
    TOGGLE = {"", 80},
    ENABLE = {"Activer la sirène", 80},
    DISABLE = {"Désactiver la sirène", 80},
    LIGHTS = {"Désactiver les gyrophares", 86},
}

local isInEmergencyVehicle = false
local currentVehicle = 0
local mainThreadActive = false
local vehicleEnumThreadActive = false
local monitoringActive = false

local Wait = Wait
local GetVehiclePedIsUsing = GetVehiclePedIsUsing
local PlayerPedId = PlayerPedId
local IsVehicleSirenOn = IsVehicleSirenOn
local DisableControlAction = DisableControlAction
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local DecorExistOn = DecorExistOn
local DecorGetBool = DecorGetBool
local DecorSetBool = DecorSetBool
local PlaySoundFrontend = PlaySoundFrontend
local GetVehicleClass = GetVehicleClass
local EnumerateVehicles = EnumerateVehicles
local DisableVehicleImpactExplosionActivation = DisableVehicleImpactExplosionActivation
local IsPedInAnyVehicle = IsPedInAnyVehicle
local GetPedInVehicleSeat = GetPedInVehicleSeat
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist

local globalVehicleThread = false

local function IsPlayerDriver(vehicle)
    local ped = PlayerPedId()
    local driver = GetPedInVehicleSeat(vehicle, -1)
    return driver == ped
end

local function ClearInstructionalButtons()
    SetInstructionalButton("ESC_ENABLE", CONTROLS['ENABLE'][2], false)
    SetInstructionalButton("ESC_DISABLE", CONTROLS['DISABLE'][2], false)
    SetInstructionalButton("ESC_LIGHTS", CONTROLS['LIGHTS'][2], false)
end

local function SyncSirenState(vehicle, enabled)
    if DoesEntityExist(vehicle) then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        if NetworkDoesNetworkIdExist(netId) then
            TriggerServerEvent('esc:setSirenState', netId, enabled)
        end
    end
end

local function GetSirenState(vehicle)
    local entity = Entity(vehicle)
    local statebagState = entity.state.esc_siren_enabled
    
    if statebagState ~= nil then
        return statebagState
    end
    
    if DecorExistOn(vehicle, "esc_siren_enabled") then
        return DecorGetBool(vehicle, "esc_siren_enabled")
    end
    
    return false
end

local function StartGlobalVehicleThread()
    if globalVehicleThread then return end
    globalVehicleThread = true
    
    Citizen.CreateThread(function()
        while true do
            local _c = 0
            
            for veh in EnumerateVehicles() do
                local vehClass = GetVehicleClass(veh)
                if vehClass == 18 then
                    local sirenEnabled = GetSirenState(veh)
                    
                    if sirenEnabled then
                        DisableVehicleImpactExplosionActivation(veh, false)
                    else
                        DisableVehicleImpactExplosionActivation(veh, true)
                    end
                end
                
                _c = (_c + 1) % 20
                if _c == 0 then
                    Wait(0)
                end
            end
            
            Wait(100)
        end
    end)
end

local function StartMainThread()
    if mainThreadActive then return end
    mainThreadActive = true
    
    Citizen.CreateThread(function()
        while mainThreadActive and isInEmergencyVehicle do
            local veh = GetVehiclePedIsUsing(PlayerPedId())
            if veh and veh ~= 0 and veh == currentVehicle then
                if IsPlayerDriver(veh) then
                    if IsVehicleSirenOn(veh) then
                        DisableControlAction(0, CONTROLS['TOGGLE'][2], true)
                        SetInstructionalButton("ESC_LIGHTS", CONTROLS['LIGHTS'][2], true)
                        
                        local sirenEnabled = GetSirenState(veh)
                        
                        if sirenEnabled then
                            SetInstructionalButton("ESC_ENABLE", CONTROLS['ENABLE'][2], false)
                            SetInstructionalButton("ESC_DISABLE", CONTROLS['DISABLE'][2], true)
                            if IsDisabledControlJustPressed(0, CONTROLS['TOGGLE'][2]) then
                                DecorSetBool(veh, "esc_siren_enabled", false)
                                SyncSirenState(veh, false)
                                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                            end
                        else
                            SetInstructionalButton("ESC_ENABLE", CONTROLS['ENABLE'][2], true)
                            SetInstructionalButton("ESC_DISABLE", CONTROLS['DISABLE'][2], false)
                            if IsDisabledControlJustPressed(0, CONTROLS['TOGGLE'][2]) then
                                DecorSetBool(veh, "esc_siren_enabled", true)
                                SyncSirenState(veh, true)
                                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                            end
                        end
                        Wait(0)
                    else
                        ClearInstructionalButtons()
                        Wait(50)
                    end
                else
                    ClearInstructionalButtons()
                    Wait(100)
                end
            else
                ClearInstructionalButtons()
                break
            end
        end
        ClearInstructionalButtons()
        mainThreadActive = false
    end)
end

local function StartMonitoring()
    if monitoringActive then return end
    monitoringActive = true
    
    Citizen.CreateThread(function()
        while monitoringActive do
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsUsing(ped)
            
            if veh and veh ~= 0 then
                local vehClass = GetVehicleClass(veh)
                if vehClass == 18 then
                    if IsPlayerDriver(veh) then
                        if not isInEmergencyVehicle or currentVehicle ~= veh then
                            isInEmergencyVehicle = true
                            currentVehicle = veh
                            
                            if not DecorExistOn(veh, "esc_siren_enabled") then
                                DecorSetBool(veh, "esc_siren_enabled", false)
                                SyncSirenState(veh, false)
                            end
                            
                            StartMainThread()
                        end
                        Wait(100)
                    else
                        if isInEmergencyVehicle then
                            isInEmergencyVehicle = false
                            currentVehicle = 0
                            ClearInstructionalButtons()
                        end
                        monitoringActive = false
                        break
                    end
                else
                    if isInEmergencyVehicle then
                        isInEmergencyVehicle = false
                        currentVehicle = 0
                        ClearInstructionalButtons()
                    end
                    monitoringActive = false
                    break
                end
            else
                if isInEmergencyVehicle then
                    isInEmergencyVehicle = false
                    currentVehicle = 0
                    ClearInstructionalButtons()
                end
                monitoringActive = false
                break
            end
        end
        monitoringActive = false
    end)
end

local function StopMonitoring()
    monitoringActive = false
    isInEmergencyVehicle = false
    currentVehicle = 0
    ClearInstructionalButtons()
end

RegisterNetEvent('esc:updateSirenState')
AddEventHandler('esc:updateSirenState', function(netId, enabled)
    if NetworkDoesNetworkIdExist(netId) then
        local vehicle = NetToVeh(netId)
        if DoesEntityExist(vehicle) then
            DecorSetBool(vehicle, "esc_siren_enabled", enabled)
            local entity = Entity(vehicle)
            entity.state.esc_siren_enabled = enabled
        end
    end
end)

Citizen.CreateThread(function()
    AddTextEntry("ESC_ENABLE", CONTROLS['ENABLE'][1])
    AddTextEntry("ESC_DISABLE", CONTROLS['DISABLE'][1])
    AddTextEntry("ESC_LIGHTS", CONTROLS['LIGHTS'][1])

    DecorRegister("esc_siren_enabled", 2)
    DecorRegisterLock()
    
    StartGlobalVehicleThread()
    
    local wasInVehicle = false
    
    while true do
        local ped = PlayerPedId()
        local isInVehicle = IsPedInAnyVehicle(ped, false)
        
        if isInVehicle ~= wasInVehicle then
            if isInVehicle then
                local veh = GetVehiclePedIsUsing(ped)
                if veh and veh ~= 0 then
                    local vehClass = GetVehicleClass(veh)
                    if vehClass == 18 and IsPlayerDriver(veh) then
                        StartMonitoring()
                    end
                end
            else
                StopMonitoring()
            end
            wasInVehicle = isInVehicle
        end
        
        if isInVehicle then
            Wait(500)
        else
            Wait(2000)
        end
    end
end)
