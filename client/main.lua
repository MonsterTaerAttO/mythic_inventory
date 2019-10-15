local isLoggedIn = false
local trunkData = nil
local trunkOpen = false
local isInInventory = false
local openCooldown = false
local myInventory = nil
local secondaryInventory = nil
local verifyItemCount = {}

local isOpenDisabled = false

PlayerVeh = nil
Callbacks = nil

AddEventHandler('mythic_base:shared:ComponentsReady', function()
	PlayerVeh = exports['mythic_base']:FetchComponent('Veh')
    Callbacks = exports['mythic_base']:FetchComponent('Callbacks')
end)

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

function Print3DTextAlt(coords, text)
	local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
	if onScreen then
		SetTextScale(0.35, 0.35)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 215)
		SetTextDropShadow(0, 0, 0, 55)
		SetTextEdge(0, 0, 0, 150)
		SetTextDropShadow()
		SetTextOutline()
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
		DrawText(_x,_y)
	end
end

function CheckVehicle()
    local player = PlayerPedId()
    local startPos = GetOffsetFromEntityInWorldCoords(player, 0, 0.5, 0)
    local endPos = GetOffsetFromEntityInWorldCoords(player, 0, 5.0, 0)

    local rayHandle = StartShapeTestRay(startPos['x'], startPos['y'], startPos['z'], endPos['x'], endPos['y'], endPos['z'], 10, player, 0)
    local a, b, c, d, veh = GetShapeTestResult(rayHandle)

    --return result

    --local coords = GetEntityCoords(player)
    --local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)

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
end

function TrunkDistanceCheck(veh)
    Citizen.CreateThread(function()
        while trunkOpen do
            Citizen.Wait(1)
            local pos = GetEntityCoords(PlayerPedId())
            local dist = #(vector3(pos.x, pos.y, pos.z) - GetOffsetFromEntityInWorldCoords(veh, 0.0, -2.5, 1.0))
            if dist > 1 and trunkOpen then
                closeInventoryInstantly()
            else
                Citizen.Wait(500)
            end
        end
    end)
end

function DisableInvOpen(status)
    isOpenDisabled = status
end

function ShowItemUse(alerts)
    SendNUIMessage({
        action = 'itemUsed',
        alerts = alerts
    })
end

RegisterNetEvent('mythic_inventory:client:ShowItemUse')
AddEventHandler('mythic_inventory:client:ShowItemUse', function(alerts)
    ShowItemUse(alerts)
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

RegisterNetEvent('mythic_inventory:client:DisableInvOpen')
AddEventHandler('mythic_inventory:client:DisableInvOpen', function(status)
    isOpenDisabled = status
end)

RegisterNetEvent('mythic_base:client:Logout')
AddEventHandler('mythic_base:client:Logout', function()
    isLoggedIn = false
end)

RegisterNetEvent('mythic_base:client:CharacterSpawned')
AddEventHandler('mythic_base:client:CharacterSpawned', function()
    
end)
isLoggedIn = true

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
        if IsControlJustReleased(0, 289) then
            if not openCooldown and not isOpenDisabled then
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
                        TriggerServerEvent('mythic_inventory:server:GetSecondaryInventory', GetPlayerServerId(PlayerId(-1)), secondaryInventory)
                    end
                else
                    local veh = CheckVehicle()

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
                            TriggerServerEvent('mythic_inventory:server:GetSecondaryInventory', GetPlayerServerId(PlayerId(-1)), secondaryInventory)
                            TrunkDistanceCheck(veh)
                        else
                            exports['mythic_notify']:SendAlert('error', 'Vehicle Is Locked')
                            if bagId ~= nil then
                                openDrop()
                            else
                                local container = ScanContainer()
                                if container then
                                    openContainer()
                                else
                                    openInventory()
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
                                openInventory()
                            end
                        end
                    end
                end
            end
        elseif IsDisabledControlJustReleased(2, 157) then -- 1
            TriggerServerEvent('mythic_inventory:server:UseItemFromSlot', securityToken, 1)
            --[[ShowItemUse({
                { item = { label = 'LMG Ammo', itemId = 'AMMO_MG', slot = 1 }, qty = 100, message = 'Item Added' },
                { item = { label = 'Pistol Ammo', itemId = 'AMMO_PISTOL', slot = 2 }, qty = 100, message = 'Item Added' },
                { item = { label = 'Rifle Ammo', itemId = 'AMMO_RIFLE', slot = 3 }, qty = 100, message = 'Item Added' },
                { item = { label = 'Shotgun Shells', itemId = 'AMMO_SHOTGUN', slot = 4 }, qty = 100, message = 'Item Added' },
                { item = { label = 'SMG Ammo', itemId = 'AMMO_SMG', slot = 5 }, qty = 100, message = 'Item Added' },
            })]]
            Callbacks:ServerCallback('mythic_inventory:server:GetHotkeys', { }, function(items)
                SendNUIMessage({
                    action = 'showActionBar',
                    items = items,
                    timer = 500
                })
                SendNUIMessage({
                    action = 'actionbarUsed',
                    index = 1
                })
            end)
        elseif IsDisabledControlJustReleased(2, 158) then -- 2
            TriggerServerEvent('mythic_inventory:server:UseItemFromSlot', securityToken, 2)
            --[[ShowItemUse({
                { item = { label = 'Water', itemId = 'water', slot = 1 }, qty = 100, message = 'Item Removed' },
                { item = { label = 'Water', itemId = 'water', slot = 2 }, qty = 100, message = 'Item Removed' },
                { item = { label = 'Water', itemId = 'water', slot = 3 }, qty = 100, message = 'Item Removed' },
                { item = { label = 'Burger', itemId = 'burger', slot = 4 }, qty = 100, message = 'Item Added' },
                { item = { label = 'Burger', itemId = 'burger', slot = 5 }, qty = 100, message = 'Item Added' },
                { item = { label = 'Burger', itemId = 'burger', slot = 6 }, qty = 100, message = 'Item Added' },
            })]]
            Callbacks:ServerCallback('mythic_inventory:server:GetHotkeys', { }, function(items)
                SendNUIMessage({
                    action = 'showActionBar',
                    items = items,
                    timer = 500
                })
                SendNUIMessage({
                    action = 'actionbarUsed',
                    index = 2
                })
            end)
        elseif IsDisabledControlJustReleased(2, 160) then -- 3
            TriggerServerEvent('mythic_inventory:server:UseItemFromSlot', securityToken, 3)
            Callbacks:ServerCallback('mythic_inventory:server:GetHotkeys', { }, function(items)
                SendNUIMessage({
                    action = 'showActionBar',
                    items = items,
                    timer = 500
                })
                SendNUIMessage({
                    action = 'actionbarUsed',
                    index = 3
                })
            end)
        elseif IsDisabledControlJustReleased(2, 164) then -- 4
            TriggerServerEvent('mythic_inventory:server:UseItemFromSlot', securityToken, 4)
            Callbacks:ServerCallback('mythic_inventory:server:GetHotkeys', { }, function(items)
                SendNUIMessage({
                    action = 'showActionBar',
                    items = items,
                    timer = 500
                })
                SendNUIMessage({
                    action = 'actionbarUsed',
                    index = 4
                })
            end)
        elseif IsDisabledControlJustReleased(2, 165) then -- 5
            TriggerServerEvent('mythic_inventory:server:UseItemFromSlot', securityToken, 5)
            Callbacks:ServerCallback('mythic_inventory:server:GetHotkeys', { }, function(items)
                SendNUIMessage({
                    action = 'showActionBar',
                    items = items,
                    timer = 500
                })
                SendNUIMessage({
                    action = 'actionbarUsed',
                    index = 5
                })
            end)
        elseif IsDisabledControlJustReleased(2, 159) or IsControlJustReleased(2, 159) then
            Callbacks:ServerCallback('mythic_inventory:server:GetHotkeys', { }, function(items)
                SendNUIMessage({
                    action = 'showActionBar',
                    items = items
                })
            end)
        end
    end
end)

function openInventory()
    loadPlayerInventory()
    isInInventory = true
    SendNUIMessage({
        action = "display",
        type = "normal"
    })
    SetNuiFocus(true, true)
end

function openVehicleExterior()
    loadPlayerInventory()
    isInInventory = true

    SendNUIMessage({
        action = "display",
        type = "secondary"
    })

    SetNuiFocus(true, true)
end

function openVehicleInterior()
    loadPlayerInventory()
    isInInventory = true

    SendNUIMessage({
        action = "display",
        type = "secondary"
    })

    SetNuiFocus(true, true)
end

function closeInventory()
    openCooldown = true
    isInInventory = false
    secondaryInventory = nil
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
end

function closeInventoryInstantly()
    secondaryInventory = nil
    openCooldown = true
    isInInventory = false
    SendNUIMessage({ action = "hide" })
    SetNuiFocus(false, false)

    if trunkOpen then
        trunkOpen = false
    end

    openCooldown = false
end

function closeSecondaryInventory()
    secondaryInventory = nil

    SendNUIMessage({ action = "closeSecondary" })

    if trunkOpen then
        trunkOpen = false
    end

    TriggerEvent('mythic_inventory:client:RefreshInventory')
end

function loadPlayerInventory()
    TriggerServerEvent("mythic_inventory:server:GetPlayerInventory")
end

RegisterNetEvent("mythic_inventory:client:RemoveWeapon")
AddEventHandler("mythic_inventory:client:RemoveWeapon", function(weapon)
    RemoveWeaponFromPed(PlayerPedId(), GetHashKey(weapon))
end)

RegisterNetEvent("mythic_inventory:client:AddWeapon")
AddEventHandler("mythic_inventory:client:AddWeapon", function(weapon)
    GiveWeaponToPed(PlayerPedId(), GetHashKey(weapon), 0, false, false)
end)

RegisterNetEvent("mythic_inventory:client:SetupUI")
AddEventHandler("mythic_inventory:client:SetupUI", function(data)
    items = {}
    inventory = data.inventory

    money = {
        cash = data.cash,
        bank = data.bank,
    }

    SendNUIMessage( { action = "setItems", itemList = inventory, invOwner = data.invId, invTier = data.invTier, money = money } )
end)

RegisterNetEvent("mythic_inventory:client:SetupSecondUI")
AddEventHandler("mythic_inventory:client:SetupSecondUI", function(data)
    items = {}
    inventory = data.inventory

    if #inventory == 0 and data.invId.type == 2 then
        closeSecondaryInventory()
    else
        secondaryInventory = data.invId
    
        SendNUIMessage( { action = "setSecondInventoryItems", itemList = inventory, invOwner = data.invId, invTier = data.invTier } )
        openVehicleExterior()
    end
end)

RegisterNetEvent("mythic_inventory:client:RefreshInventory")
AddEventHandler("mythic_inventory:client:RefreshInventory", function()
    loadPlayerInventory()
    
    if trunkOpen then
        local veh = CheckVehicle()
        if veh and IsEntityAVehicle(veh) then
            local plate = GetVehicleNumberPlateText(veh)
            if GetVehicleDoorLockStatus(veh) == 1 then
                SetVehicleDoorOpen(veh, 5, true, false)
                TriggerServerEvent('mythic_inventory:server:GetSecondaryInventory', GetPlayerServerId(PlayerId(-1)), secondaryInventory)
            end
        end
    elseif secondaryInventory ~= nil then
        TriggerServerEvent('mythic_inventory:server:GetSecondaryInventory', GetPlayerServerId(PlayerId(-1)), secondaryInventory)
    end
end)

RegisterNetEvent("mythic_inventory:client:RefreshInventory2")
AddEventHandler("mythic_inventory:client:RefreshInventory2", function(origin, destination)
    if (myInventory ~= nil and origin ~= nil and myInventory.type == origin.type and myInventory.owner == origin.owner) or
    (myInventory ~= nil and myInventory.type == destination.type and myInventory.owner == destination.owner) or
    (secondaryInventory ~= nil and origin ~= nil and secondaryInventory.type == origin.type and secondaryInventory.owner == origin.owner) or
    (secondaryInventory ~= nil and secondaryInventory.type == destination.type and secondaryInventory.owner == destination.owner) then
        loadPlayerInventory()
        
        if trunkOpen then
            local veh = CheckVehicle()
            if veh and IsEntityAVehicle(veh) then
                local plate = GetVehicleNumberPlateText(veh)
                if GetVehicleDoorLockStatus(veh) == 1 then
                    SetVehicleDoorOpen(veh, 5, true, false)
                    TriggerServerEvent('mythic_inventory:server:GetSecondaryInventory', GetPlayerServerId(PlayerId(-1)), secondaryInventory)
                end
            end
        elseif secondaryInventory ~= nil then
            TriggerServerEvent('mythic_inventory:server:GetSecondaryInventory', GetPlayerServerId(PlayerId(-1)), secondaryInventory)
        end
    end
end)

RegisterNetEvent("mythic_inventory:client:CloseUI")
AddEventHandler("mythic_inventory:client:CloseUI", function()
    closeInventoryInstantly()
end)

RegisterNetEvent("mythic_inventory:client:CloseUI2")
AddEventHandler("mythic_inventory:client:CloseUI2", function(owner)
    if secondaryInventory.type == owner.type and secondaryInventory.owner == owner.owner then
        closeInventoryInstantly()
    end
end)

RegisterNetEvent("mythic_inventory:client:CloseSecondary")
AddEventHandler("mythic_inventory:client:CloseSecondary", function(owner)
    if secondaryInventory.type == owner.type and secondaryInventory.owner == owner.owner or secondaryInventory == nil then
        closeSecondaryInventory()
    end
end)

RegisterNetEvent("mythic_inventory:client:GetSecondaryInventory")
AddEventHandler("mythic_inventory:client:GetSecondaryInventory", function(owner)
    secondaryInventory = owner
    TriggerServerEvent('mythic_inventory:server:GetSecondaryInventory', GetPlayerServerId(PlayerId(-1)), owner)
end)

RegisterNUICallback("NUIFocusOff",function()
    closeInventory()
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

RegisterNetEvent('mythic_inventory:client:CheckItemCount')
AddEventHandler('mythic_inventory:client:CheckItemCount', function(unique, items, cb)
    verifyItemCount[unique] = cb
    TriggerServerEvent('mythic_inventory:server:CheckItemCount', unique, items)
end)

RegisterNetEvent('mythic_inventory:client:SendItemCountStatus')
AddEventHandler('mythic_inventory:client:SendItemCountStatus', function(unique, status)
    verifyItemCount[unique](status)
    verifyItemCount[unique] = nil
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

    ShowItemUse(data.item, data.qty, 'Item Dropped');

    cb("ok")
end)

RegisterNUICallback("GiveItem", function(data, cb)
    TriggerServerEvent('mythic_inventory:server:GiveItem', data.target, data.item, data.count)
    cb("ok")
end)