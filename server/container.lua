containers = {}

RegisterServerEvent('mythic_inventory:server:GetActiveContainers')
AddEventHandler('mythic_inventory:server:GetActiveContainers', function()
    TriggerClientEvent('mythic_inventory:client:RecieveActiveContainers', source, containers)
end)