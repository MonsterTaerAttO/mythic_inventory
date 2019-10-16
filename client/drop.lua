local isLoggedIn = false
local dropsNear = {}
local dropList = {}
bagId = nil

function openDrop()
    if bagId ~= nil then
        MYTh.Inventory.Open:Secondary(bagId)
    end
end

AddEventHandler('mythic_base:client:CharacterSpawned', function()
    TriggerServerEvent('mythic_inventory:server:GetActiveDrops')
end)

RegisterNetEvent('mythic_inventory:client:RecieveActiveDrops')
AddEventHandler('mythic_inventory:client:RecieveActiveDrops', function(drops)
    for k, v in pairs(drops) do
        dropList[v.owner] = v
    end
end)

RegisterNetEvent('mythic_inventory:client:RemoveBag')
AddEventHandler('mythic_inventory:client:RemoveBag', function(owner)
    table.remove(dropsNear, owner.owner)
    table.remove(dropList, owner.owner)
    bagId = nil
end)

RegisterNetEvent('mythic_inventory:client:CleanDropItems')
AddEventHandler('mythic_inventory:client:CleanDropItems', function()
    dropList = {}
end)

RegisterNetEvent('mythic_inventory:client:DropCreateForAll')
AddEventHandler('mythic_inventory:client:DropCreateForAll', function(drop)
    table.insert(dropList, drop)
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
        local pedCoord = GetEntityCoords(PlayerPedId())
        if #dropList > 0 then
            local plyCoords = GetEntityCoords(PlayerPedId())
            for k, v in pairs(dropList) do
                local dist = #(vector3(v.position.x, v.position.y, v.position.z) - plyCoords)
                if dist < 20.0 then
                    dropsNear[k] = v
                    if dist < 5.0 then
                        bagId = v
                    else
                        bagId = nil
                    end
                else
                    table.remove(dropsNear, k)
                end
            end
        else
            dropsNear = {}
        end
        Citizen.Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while isLoggedIn do
        for k, v in pairs(dropsNear) do
            DrawMarker(25, v.position.x, v.position.y, v.position.z - 0.99, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 1.0, 139, 16, 20, 250, false, false, 2, false, false, false, false)
        end
        Citizen.Wait(1)
    end
end)