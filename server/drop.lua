drops = {}

function CreateDrop(src, char, item, count, coords, cb)
    local fuck = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
    }

    local newDrop = { type = 2, owner = (#drops + 1), position = fuck }
    table.insert(drops, newDrop)
    char:addToDrop(newDrop.owner, item, count, function(s)
        if item.type == 1 then
            TriggerClientEvent("mythic_inventory:client:RemoveWeapon", src, item.name)
        end

        TriggerClientEvent('mythic_inventory:client:DropCreateForAll', -1, newDrop)

        cb(newDrop)
    end)
end

function AddToDrop(src, char, owner, item, count, cb)
    if drops[owner] ~= nil then
        char:addToDrop(owner, item, count, function(s)
            if item.type == 1 then
                TriggerClientEvent("mythic_inventory:client:RemoveWeapon", src, item.name)
            end

            cb(s)
        end)
    end
end

RegisterServerEvent('mythic_inventory:server:GetActiveDrops')
AddEventHandler('mythic_inventory:server:GetActiveDrops', function()
    TriggerClientEvent('mythic_inventory:client:RecieveActiveDrops', source, drops)
end)

RegisterServerEvent('mythic_inventory:server:Drop')
AddEventHandler('mythic_inventory:server:Drop', function(item, count, coords)
    local src = source
    local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(src)

    if mPlayer ~= nil then
        local char = mPlayer:GetData('character')
        local cData = char:GetData()
        Citizen.CreateThread(function()
            exports['ghmattimysql']:execute('SELECT * FROM inventory_items WHERE type = 1 AND owner = @charid AND slot = @slot LIMIT 1', { ['slot'] = item.slot, ['charid'] = cData.id }, function(dbItem)
                if dbItem[1] ~= nil then
                    if count > tonumber(dbItem[1].qty) then
                        count = tonumber(dbItem[1].qty)
                    end

                    local dropinv = nil
                    local pos = GetEntityCoords(GetPlayerPed(src))
                    for k, v in pairs(drops) do
                        local dist = #(vector3(v.position.x, v.position.y, v.position.z) - pos)
                        if dist < 5.0 then
                            AddToDrop(src, char, v.owner, item, count, function()
                                TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, v, v)
                            end)
                            return
                        end
                    end

                    CreateDrop(src, char, item, count, coords, function(drop)
                        TriggerEvent('mythic_inventory:server:GetSecondaryInventory', src, drop)
                    end)
                    
                    --TriggerClientEvent('mythic_inventory:client:RefreshInventory', src)
                    --TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, dropinv)
                end
            end)
        end)
    
    end
end)

RegisterServerEvent('mythic_inventory:server:RemoveBag')
AddEventHandler('mythic_inventory:server:RemoveBag', function(dropInv)
    table.remove(drops, dropInv.owner)
    TriggerClientEvent('mythic_inventory:client:RemoveBag', -1, dropInv)
end)