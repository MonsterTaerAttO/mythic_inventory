MYTH = MYTH or {}
MYTH.Inventory = MYTH.Inventory or {}

local isLoggedIn = false
local trunkData = nil
local trunkOpen = false
local isInInventory = false
local openCooldown = false
local myInventory = nil
local secondaryInventory = nil

PlayerVeh = nil
Callbacks = nil

AddEventHandler('mythic_base:shared:ComponentsReady', function()
	PlayerVeh = exports['mythic_base']:FetchComponent('Veh')
    Callbacks = exports['mythic_base']:FetchComponent('Callbacks')
end)

MYTH.Inventory.Setup = {
    Startup = function(self)
        Citizen.CreateThread(function()
            while isLoggedIn do
                BlockWeaponWheelThisFrame()
                Citizen.Wait(1)
            end
        end)
    
        Citizen.CreateThread(function()
            Citizen.Wait(100)
            while isLoggedIn do
                Citizen.Wait(0)
                if not MYTH.Inventory.Locked then
                    if IsControlJustReleased(0, 289) then
                        if not openCooldown then
                            if IsPedInAnyVehicle(PlayerPedId(), true) then
                                local veh = GetVehiclePedIsIn(PlayerPedId())
                                local plate = GetVehicleNumberPlateText(veh)
    
                                if DecorExistOn(veh, 'HasFakePlate') then
                                    plate = exports['mythic_veh']:TraceBackPlate(plate)
                                end
    
                                if PlayerVeh:IsPlayerOwnedVeh(veh) then
                                    if plate ~= nil then
                                        secondaryInventory = { type = 4, owner = plate }
                                    end
                                else
                                    if plate ~= nil then
                                        secondaryInventory = { type = 6, owner = plate }
                                    end
                                end
    
                                if plate ~= nil then
                                    MYTH.Inventory.Load:Secondary()
                                end
                            else
                                local veh = MYTH.Inventory.Checks:Vehicle()
    
                                if veh and IsEntityAVehicle(veh) then
                                    local plate = GetVehicleNumberPlateText(veh)
    
                                    if DecorExistOn(veh, 'HasFakePlate') then
                                        plate = exports['mythic_veh']:TraceBackPlate(plate)
                                    end
    
                                    if GetVehicleDoorLockStatus(veh) == 1 then
                                        trunkOpen = true
                                        if PlayerVeh:IsPlayerOwnedVeh(veh) then
                                            secondaryInventory = { type = 5, owner = plate }
                                        else
                                            secondaryInventory = { type = 7, owner = plate }
                                        end
                                        
                                        SetVehicleDoorOpen(veh, 5, true, false)
                                        MYTH.Inventory.Load:Secondary()
                                        MYTH.Inventory.Checks:TrunkDistance(veh)
                                    else
                                        exports['mythic_notify']:SendAlert('error', 'Vehicle Is Locked')
                                        if bagId ~= nil then
                                            openDrop()
                                        else
                                            local container = ScanContainer()
                                            if container then
                                                openContainer()
                                            else
                                                MYTH.Inventory.Open:Personal()
                                            end
                                        end
                                    end
                                else
                                    if bagId ~= nil then
                                        openDrop()
                                    else
                                        local container = ScanContainer()
                                        if container then
                                            openContainer()
                                        else
                                            MYTH.Inventory.Open:Personal()
                                        end
                                    end
                                end
                            end
                        end
                    elseif IsDisabledControlJustReleased(2, 157) then -- 1
                        MYTH.Inventory:Hotkey(1)
                    elseif IsDisabledControlJustReleased(2, 158) then -- 2
                        MYTH.Inventory:Hotkey(2)
                    elseif IsDisabledControlJustReleased(2, 160) then -- 3
                        MYTH.Inventory:Hotkey(3)
                    elseif IsDisabledControlJustReleased(2, 164) then -- 4
                        MYTH.Inventory:Hotkey(4)
                    elseif IsDisabledControlJustReleased(2, 165) then -- 5
                        MYTH.Inventory:Hotkey(5)
                    elseif IsDisabledControlJustReleased(2, 159) or IsControlJustReleased(2, 159) then
                        Callbacks:ServerCallback('mythic_inventory:server:GetHotkeys', { }, function(items)
                            SendNUIMessage({
                                action = 'showActionBar',
                                items = items
                            })
                        end)
                    end
                end
            end
        end)
    end,
    Primary = function(self, data)
        items = {}
        inventory = data.inventory
    
        SendNUIMessage( { action = "setItems", itemList = inventory, invOwner = data.invId, invTier = data.invTier } )
    end,
    Secondary = function(self, data)
        items = {}
        inventory = data.inventory
    
        if #inventory == 0 and data.invId.type == 2 then
            MYTY.Inventory.Close:Secondary()
        else
            secondaryInventory = data.invId
            SendNUIMessage( { action = "setSecondInventoryItems", itemList = inventory, invOwner = data.invId, invTier = data.invTier } )
            MYTH.Inventory.Open:Secondary()
        end
    end
}

RegisterNetEvent('mythic_inventory:client:LockInventory')
AddEventHandler('mythic_inventory:client:LockInventory', function(state)
    MYTH.Inventory:LockInventory(state)
end)

function MYTH.Inventory.LockInventory(self, state)
    MYTH.Inventory.Locked = not MYTH.Inventory.Locked
end

local cooldown = false
function MYTH.Inventory.Hotkey(self, index)
    if not cooldown and not MYTH.Inventory.Locked then
        TriggerServerEvent('mythic_inventory:server:UseItemFromSlot', index)
        Callbacks:ServerCallback('mythic_inventory:server:UseHotkey', { slot = index }, function()
            cooldown = true

            Citizen.CreateThread(function()
                Citizen.Wait(1000)
                cooldown = false
            end)
            
            Callbacks:ServerCallback('mythic_inventory:server:GetHotkeys', { }, function(items)
                SendNUIMessage({
                    action = 'showActionBar',
                    items = items,
                    timer = 500,
                    index = index
                })
            end)
        end)
    end
end

function MYTH.Inventory.ItemUsed(self, alerts)
    SendNUIMessage({
        action = 'itemUsed',
        alerts = alerts
    })
end

Citizen.CreateThread(function()
    while true do
        local player = PlayerPedId()
        local pos = GetEntityCoords(player)
        local dist = #(vector3(-1045.3142089844, -2731.0183105469, 20.169298171997) - pos)

        if dist < 20 then
            DrawMarker(25, -1045.3142089844, -2731.0183105469, 20.169298171997 - 0.99, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 1.0, 139, 16, 20, 250, false, false, 2, false, false, false, false)

            if dist < 2 then
                if IsControlJustReleased(0, 51) then
                    TriggerServerEvent('mythic_inventory:server:GetSecondaryInventory', GetPlayerServerId(PlayerId()), { type = 18, owner = '1' })
                end
            end
        end

        Citizen.Wait(1)
    end
end)

RegisterNetEvent('mythic_inventory:client:ShowItemUse')
AddEventHandler('mythic_inventory:client:ShowItemUse', function(alerts)
    MYTH.Inventory:ItemUsed(alerts)
end)

MYTH.Inventory.Checks = {
    Vehicle = function(self)
        local player = PlayerPedId()
        local startPos = GetOffsetFromEntityInWorldCoords(player, 0, 0.5, 0)
        local endPos = GetOffsetFromEntityInWorldCoords(player, 0, 5.0, 0)
    
        local rayHandle = StartShapeTestRay(startPos['x'], startPos['y'], startPos['z'], endPos['x'], endPos['y'], endPos['z'], 10, player, 0)
        local a, b, c, d, veh = GetShapeTestResult(rayHandle)
    
        if veh ~= 2 then
            local plyCoords = GetEntityCoords(player)
            local offCoords = GetOffsetFromEntityInWorldCoords(veh, 0.0, -2.5, 1.0)
            local dist = #(vector3(offCoords.x, offCoords.y, offCoords.z) - plyCoords)
    
            if dist < 2.5 then
                return veh
            end
        else
            return nil
        end
    end,
    Trunk = function(self)
        
    end,
    TrunkDistance = function(self, veh)
        Citizen.CreateThread(function()
            while trunkOpen do
                Citizen.Wait(1)
                local pos = GetEntityCoords(PlayerPedId())
                local dist = #(vector3(pos.x, pos.y, pos.z) - GetOffsetFromEntityInWorldCoords(veh, 0.0, -2.5, 1.0))
                if dist > 1 and trunkOpen then
                    MYTH.Inventory.Close:Instantly()
                else
                    Citizen.Wait(500)
                end
            end
        end)
    end,
    HasItem = function(self, items, cb)
        Callbacks:ServerCallback('mythic_inventory:server:HasItem', items, function(status)
            cb(status)
        end)
    end
}

MYTH.Inventory.Load = {
    Personal = function(self)
        TriggerServerEvent("mythic_inventory:server:GetPlayerInventory")
    end,
    Secondary = function(self, secondary)
        if secondary ~= nil then
            secondaryInventory = secondary
        end

        TriggerServerEvent('mythic_inventory:server:GetSecondaryInventory', GetPlayerServerId(PlayerId()), secondaryInventory)
    end
}

MYTH.Inventory.Open = {
    Personal = function(self)
        MYTH.Inventory.Load:Personal()
        isInInventory = true
        SendNUIMessage({
            action = "display",
            type = "normal"
        })

        TransitionToBlurred(1000)

        SetNuiFocus(true, true)
    end,
    Secondary = function(self)
        MYTH.Inventory.Load:Personal()
        isInInventory = true

        TransitionToBlurred(1000)
    
        SendNUIMessage({
            action = "display",
            type = "secondary"
        })
    
        SetNuiFocus(true, true)
    end
}

MYTH.Inventory.Close = {
    Normal = function(self)
        openCooldown = true
        isInInventory = false
        secondaryInventory = nil

        TransitionFromBlurred(1000)

        SendNUIMessage({ action = "hide" })
        SetNuiFocus(false, false)
    
        if trunkOpen then
            local coords = GetEntityCoords(PlayerPedId())
            local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    
            exports['mythic_base']:FetchComponent('Progress'):Progress({
                name = "trunk_action",
                duration = 500,
                label = "Closing Trunk",
                useWhileDead = false,
                canCancel = true,
                controlDisables = {
                    disableMovement = false,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = false,
                },
                animation = {
                    animDict = "veh@low@front_dsfps@base",
                    anim = "horn_outro",
                    flags = 49,
                },
            }, function(status)
                SetVehicleDoorShut(veh, 5, false)
                trunkOpen = false
            end)
        end
    
        Citizen.Wait(1200)
        openCooldown = false
    end,
    Instant = function(self)
        secondaryInventory = nil
        openCooldown = true
        isInInventory = false
        SendNUIMessage({ action = "hide" })
        SetNuiFocus(false, false)
    
        if trunkOpen then
            trunkOpen = false
        end
    
        openCooldown = false
    end,
    Secondary = function(self)
        secondaryInventory = nil

        SendNUIMessage({ action = "closeSecondary" })
    
        if trunkOpen then
            trunkOpen = false
        end
    
        TriggerEvent('mythic_inventory:client:RefreshInventory')
    end
}



RegisterNetEvent("mythic_inventory:client:RemoveWeapon")
AddEventHandler("mythic_inventory:client:RemoveWeapon", function(weapon)
    MYTH.Inventory.Weapons:Remove(weapon)
end)

RegisterNetEvent("mythic_inventory:client:AddWeapon")
AddEventHandler("mythic_inventory:client:AddWeapon", function(weapon)
    MYTH.Inventory.Weapons:Add(weapon)
end)

MYTH.Inventory.Weapons = {
    Add = function(self, weapon)
        --GiveWeaponToPed(PlayerPedId(), weapon, 0, false, false)
    end,
    Remove = function(self, weapon)
        --RemoveWeaponFromPed(PlayerPedId(), weapon)
    end
}

RegisterNetEvent('mythic_base:client:CharacterDataChanged')
AddEventHandler('mythic_base:client:CharacterDataChanged', function(charData)
    if charData ~= nil then
        if charData:GetData('id') ~= nil then
            myInventory = { type = 1, owner = charData:GetData('id') }
        else
            myInventory = nil
        end
    else
        myInventory = nil
    end
end)

RegisterNetEvent('mythic_inventory:client:RobPlayer')
AddEventHandler('mythic_inventory:client:RobPlayer', function()
    local ped = exports['mythic_base']:GetPedInFront()

    if ped ~= 0 then
        local pedPlayer = exports['mythic_base']:GetPlayerFromPed(ped)
        if pedPlayer ~= -1 then
            TriggerServerEvent('mythic_inventory:server:RobPlayer', GetPlayerServerId(pedPlayer))
        end
    end
end)

RegisterNetEvent('mythic_base:client:Logout')
AddEventHandler('mythic_base:client:Logout', function()
    isLoggedIn = false
end)

RegisterNetEvent('mythic_base:client:CharacterSpawned')
AddEventHandler('mythic_base:client:CharacterSpawned', function()
    isLoggedIn = true
    MYTH.Inventory.Setup:Startup()
end)

RegisterNetEvent("mythic_inventory:client:SetupUI")
AddEventHandler("mythic_inventory:client:SetupUI", function(data)
    MYTH.Inventory.Setup:Primary(data)
end)

RegisterNetEvent("mythic_inventory:client:SetupSecondUI")
AddEventHandler("mythic_inventory:client:SetupSecondUI", function(data)
    MYTH.Inventory.Setup:Secondary(data)
end)

RegisterNetEvent("mythic_inventory:client:RefreshInventory")
AddEventHandler("mythic_inventory:client:RefreshInventory", function()
    MYTH.Inventory.Load:Personal()
    
    if trunkOpen then
        local veh = MYTH.Inventory.Checks:Vehicle()
        if veh and IsEntityAVehicle(veh) then
            local plate = GetVehicleNumberPlateText(veh)
            if GetVehicleDoorLockStatus(veh) == 1 then
                SetVehicleDoorOpen(veh, 5, true, false)
                MYTH.Inventory.Load:Secondary()
            end
        end
    elseif secondaryInventory ~= nil then
        MYTH.Inventory.Load:Secondary()
    end
end)

RegisterNetEvent("mythic_inventory:client:RefreshInventory2")
AddEventHandler("mythic_inventory:client:RefreshInventory2", function(origin, destination)
    if (myInventory ~= nil and origin ~= nil and myInventory.type == origin.type and myInventory.owner == origin.owner) or
    (myInventory ~= nil and myInventory.type == destination.type and myInventory.owner == destination.owner) or
    (secondaryInventory ~= nil and origin ~= nil and secondaryInventory.type == origin.type and secondaryInventory.owner == origin.owner) or
    (secondaryInventory ~= nil and secondaryInventory.type == destination.type and secondaryInventory.owner == destination.owner) then
        MYTH.Inventory.Load:Personal()
        
        if trunkOpen then
            local veh = MYTH.Inventory:Vehicle()
            if veh and IsEntityAVehicle(veh) then
                local plate = GetVehicleNumberPlateText(veh)
                if GetVehicleDoorLockStatus(veh) == 1 then
                    SetVehicleDoorOpen(veh, 5, true, false)
                    MYTH.Inventory.Load:Secondary()
                end
            end
        elseif secondaryInventory ~= nil then
            MYTH.Inventory.Load:Secondary()
        end
    end
end)

RegisterNetEvent("mythic_inventory:client:CloseUI")
AddEventHandler("mythic_inventory:client:CloseUI", function()
    MYTH.Inventory.Close:Instantly()
end)

RegisterNetEvent("mythic_inventory:client:CloseUI2")
AddEventHandler("mythic_inventory:client:CloseUI2", function(owner)
    if secondaryInventory.type == owner.type and secondaryInventory.owner == owner.owner then
    MYTH.Inventory.Close:Instantly()
    end
end)

RegisterNetEvent("mythic_inventory:client:CloseSecondary")
AddEventHandler("mythic_inventory:client:CloseSecondary", function(owner)
    if secondaryInventory == nil or (secondaryInventory.type == owner.type and secondaryInventory.owner == owner.owner) then
        MYTH.Inventory.Close:Secondary()
    end
end)

RegisterNUICallback("NUIFocusOff",function()
    MYTH.Inventory.Close:Normal()
end)

RegisterNUICallback("GetSurroundingPlayers", function(data, cb)
    local coords = GetEntityCoords(PlayerPedId(), true)
    local players = {}

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player) 
            local targetCoords = GetEntityCoords(ped)
            local distance = #(vector3(targetCoords.x, targetCoords.y, targetCoords.z) - coords)

            if distance <= 3.0 then
                table.insert(players, {
                    name = GetPlayerName(player),
                    id = GetPlayerServerId(player)
                })
            end
        end
	end

    SendNUIMessage({
        action = "nearPlayers",
        players = players
    })

    cb("ok")
end)

RegisterNUICallback("MoveToEmpty", function(data, cb)
    TriggerServerEvent('mythic_inventory:server:MoveToEmpty', data.originOwner, data.originItem, data.destinationOwner, data.destinationItem)
    cb("ok")
end)

RegisterNUICallback("SplitStack", function(data, cb)
    TriggerServerEvent('mythic_inventory:server:SplitStack', data.originOwner, data.originItem, data.destinationOwner, data.destinationItem, data.moveQty)
    cb("ok")
end)

RegisterNUICallback("CombineStack", function(data, cb)
    TriggerServerEvent('mythic_inventory:server:CombineStack', data.originOwner, data.originItem, data.destinationOwner, data.destinationItem)
    cb("ok")
end)

RegisterNUICallback("MoveQuantity", function(data, cb)
    TriggerServerEvent('mythic_inventory:server:CombineStack', data.originOwner, data.originItem, data.destinationOwner, data.destinationItem, data.moveQty)
    cb("ok")
end)

RegisterNUICallback("TopoffStack", function(data, cb)
    TriggerServerEvent('mythic_inventory:server:TopoffStack', data.originOwner, data.originItem, data.destinationOwner, data.destinationItem)
    cb("ok")
end)

RegisterNUICallback("SwapItems", function(data, cb)
    TriggerServerEvent('mythic_inventory:server:SwapItems', data.originOwner, data.originItem, data.destinationOwner, data.destinationItem)
    cb("ok")
end)

RegisterNUICallback("UseItem", function(data, cb)
    TriggerServerEvent("mythic_base:server:UseItem", GetPlayerServerId(PlayerId()), data.item)
    cb(data.item.closeUi)
end)

RegisterNUICallback("DropItem", function(data, cb)
    if IsPedSittingInAnyVehicle(PlayerPedId()) then
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('mythic_inventory:server:Drop', data.item, data.qty, coords)

    MYTH.Inventory:ItemUsed({ item = data.item, qty = data.qty, message = 'Item Dropped' })

    cb("ok")
end)

RegisterNUICallback("GiveItem", function(data, cb)
    TriggerServerEvent('mythic_inventory:server:GiveItem', data.target, data.item, data.count)
    cb("ok")
end)

AddEventHandler('mythic_base:shared:ComponentRegisterReady', function()
    exports['mythic_base']:CreateComponent('Inventory', MYTH.Inventory)
end)