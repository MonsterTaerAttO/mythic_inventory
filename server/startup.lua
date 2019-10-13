InvSlots = {--[[
	['misc'] = { slots = 10, label = 'Unknown' },
	['player'] = { slots = 40, label = 'Player' },
	['drop'] = { slots = 100, label = 'Drop' },
	['container'] = { slots = 100, label = 'Container' },
	['car-int'] = { slots = 5, label = 'Glove Box' },
	['car-ext'] = { slots = 50, label = 'Trunk' },
	['prop-1'] = { slots = 50, label = 'Property Stash' },
	['prop-2'] = { slots = 65, label = 'Property Stash' },
	['prop-3'] = { slots = 80, label = 'Property Stash' },
	['prop-4'] = { slots = 100, label = 'Property Stash' },
	['biz-1'] = { slots = 100, label = 'Property Stash' },
	['biz-2'] = { slots = 125, label = 'Property Stash' },
	['biz-3'] = { slots = 150, label = 'Property Stash' },
	['biz-4'] = { slots = 200, label = 'Property Stash' },
	['pd-evidence'] = { slots = 1000, label = 'Evidence Locker' },
	['pd-trash'] = { slots = 1000, label = 'Trash Locker' },
]]}

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    exports['ghmattimysql']:execute('DELETE FROM inventory_items WHERE type IN (0, 2, 3, 6, 7, 8, 9)')
    exports['ghmattimysql']:execute('DELETE FROM inventory_items WHERE qty <= 0')

    exports['ghmattimysql']:execute('SELECT * FROM entity_types', {}, function(entities)
        if entities[1] ~= nil then
            print('^7[^8MYTHIC_BASE ^7: ^8Startup^0] ^5Retrieved ' .. #entities .. ' Entity Types From Database^7')
            for k, v in pairs(entities) do
                InvSlots[v.id] = {
                    label = v.label,
                    slots = v.slots
                }
            end
        else
            print('^8UNABLE TO FETCH ENTITY TYPES^7')
            InvSlots = {
                [0] = { label = 'Unknown', slots = 10 },
                [1] = { label = 'Player', slots = 40 },
                [2] = { label = 'Drop', slots = 100 },
                [3] = { label = 'Container', slots = 100 },
                [4] = { label = 'Glove Box', slots = 5 },
                [5] = { label = 'Trunk', slots = 50 },
                [6] = { label = 'Glove Box', slots = 5 },
                [7] = { label = 'Trunk', slots = 50 },
                [8] = { label = 'Property Stash', slots = 50 },
                [9] = { label = 'Property Stash', slots = 65 },
                [10] = { label = 'Property Stash', slots = 80 },
                [11] = { label = 'Property Stash', slots = 100 },
                [12] = { label = 'Property Stash', slots = 100 },
                [13] = { label = 'Property Stash', slots = 125 },
                [14] = { label = 'Property Stash', slots = 150 },
                [15] = { label = 'Property Stash', slots = 200 },
                [16] = { label = 'Property Stash', slots = 1000 },
                [17] = { label = 'Property Stash', slots = 1000 },
            }
        end
    end)
end)