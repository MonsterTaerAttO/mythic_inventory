MYTH.Inventory.Drops = {
    Process = function(self, source, item, count, coords)
        local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(source)
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
                        local pos = GetEntityCoords(GetPlayerPed(source))
                        for k, v in pairs(MYTH.Inventory.Drops.Store) do
                            local dist = #(vector3(v.position.x, v.position.y, v.position.z) - pos)
                            if dist < 5.0 then
                                MYTH.Inventory.Drops:Add(source, char, v.owner, item, count, function()
                                    TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, v, v)
                                end)
                                return
                            end
                        end
    
                        MYTH.Inventory.Drops:Create(source, char, item, count, coords, function(drop)
                            TriggerEvent('mythic_inventory:server:GetSecondaryInventory', source, drop)
                        end)
                        
                        --TriggerClientEvent('mythic_inventory:client:RefreshInventory', src)
                        --TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, dropinv)
                    end
                end)
            end)
        
        end
    end,
    Create = function(self, src, char, item, count, coords, cb)
        local fuck = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
        }
    
        local newDrop = { type = 2, owner = (#MYTH.Inventory.Drops.Store + 1), position = fuck }
        table.insert(MYTH.Inventory.Drops.Store, newDrop)
        char.Inventory.Add:Drop(newDrop.owner, item, count, function(s)
            if item.type == 1 then
                TriggerClientEvent("mythic_inventory:client:RemoveWeapon", src, item.name)
            end
    
            TriggerClientEvent('mythic_inventory:client:DropCreateForAll', -1, newDrop)
    
            cb(newDrop)
        end)
    end,
    Add = function(self, src, char, owner, item, count, cb)
        if MYTH.Inventory.Drops.Store[owner] ~= nil then
            char.Inventory.Add:Drop(owner, item, count, function(s)
                if item.type == 1 then
                    TriggerClientEvent("mythic_inventory:client:RemoveWeapon", src, item.name)
                end
    
                cb(s)
            end)
        end
    end,
    Store = {}
}
drops = {}

RegisterServerEvent('mythic_inventory:server:GetActiveDrops')
AddEventHandler('mythic_inventory:server:GetActiveDrops', function()
    TriggerClientEvent('mythic_inventory:client:RecieveActiveDrops', source, MYTH.Inventory.Drops.Store)
end)

RegisterServerEvent('mythic_inventory:server:Drop')
AddEventHandler('mythic_inventory:server:Drop', function(item, count, coords)
    ProcessDrop(source, item, count, coords)
end)

RegisterServerEvent('mythic_inventory:server:RemoveBag')
AddEventHandler('mythic_inventory:server:RemoveBag', function(dropInv)
    table.remove(MYTH.Inventory.Drops.Store, dropInv.owner)
    TriggerClientEvent('mythic_inventory:client:RemoveBag', -1, dropInv)
end)