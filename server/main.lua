local Callbacks = nil

AddEventHandler('mythic_base:shared:ComponentsReady', function()
	Callbacks = exports['mythic_base']:FetchComponent('Callbacks')

	Callbacks:RegisterServerCallback('mythic_inventory:server:CheckItem', function(source, data, cb)
		local char = exports['mythic_base']:FetchComponent('Fetch'):Source(source):GetData('character')
		cb(CheckItems(1, char:GetData('id'), data))
	end)

	Callbacks:RegisterServerCallback('mythic_inventory:server:GetHotkeys', function(source, data, cb)
		local returnVal = nil
		returnVal = GetHotkeyItems(source, function(items)
			returnVal = items
		end)

		while returnVal == nil do
			Citizen.Wait(100)
		end
		
		cb(returnVal)
	end)
end)

function CheckItems(type, id, items)
	local failed = nil
	for k, v in pairs(items) do
		checkItemCount(type, id, v.item, v.count, function(hasItem)
			if not hasItem then
				failed = true
				return
			end

			if k == #items then
				failed = false
			end
		end)
	end

	while failed == nil do
		Citizen.Wait(1)
	end

	if not failed then
		return true
	else
		return false
	end
end

function GetHotkeyItems(source, cb)
	local char = exports['mythic_base']:FetchComponent('Fetch'):Source(source):GetData('character')
	char:getHotkeyItems(function(items)
		cb(items)
	end)
end

function GetPlayerInventory(source)
	local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(source)

	local char = mPlayer:GetData('character')
	local cData = char:GetData()

	Citizen.CreateThread(function()
		char:getInventory(function(items)
			local itemsObject = {}
			for k, v in pairs(items) do
				local meta = {}
				if v["metadata"] ~= nil then
					meta = json.decode(v["metadata"])
				end
				local sMeta = {}
				if v["staticMeta"] ~= nil then
					sMeta = json.decode(v["staticMeta"])
				end

				table.insert(itemsObject, {
					id = v["id"],
					itemId = v["itemId"],
					description = v["description"],
					qty = v["qty"],
					slot = v["slot"],
					label = v["label"],
					type = v["type"],
					max = v["max"],
					stackable = v["stackable"],
					unique = v["unique"],
					usable = v["usable"],
					metadata = meta,
					staticMeta = sMeta,
					canRemove = true,
					price = v["price"],
					needs = v["needs_boost"],
					closeUi = v["closeUi"],
				})
			end
		
			local data = {
				invId = { type = 1, owner = cData.id },
				invTier = InvSlots[1],
				inventory = itemsObject,
				cash = cData.cash,
				bank = cData.bank,
			}
		
			TriggerClientEvent('mythic_inventory:client:SetupUI', source, data)
		end)
	end)
end

function GetSecondaryInventory(source, inventory)

end

RegisterServerEvent('mythic_inventory:server:MoveToEmpty')
AddEventHandler('mythic_inventory:server:MoveToEmpty', function(originOwner, originItem, destinationOwner, destinationItem)
    local src = source
	local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(src)

	local char = mPlayer:GetData('character')
	
	Citizen.CreateThread(function()
		char:moveToEmptySlot(originOwner, originItem, destinationOwner, destinationItem.slot, function(status)
			if originOwner.type ~= destinationOwner.type or originOwner.owner ~= destinationOwner.owner then
				if status then
					if destinationItem.type == 1 then
						if originOwner.type == 1 then
							TriggerClientEvent("mythic_inventory:client:RemoveWeapon", mPlayer:GetData('source'), destinationItem.itemId)
						end

						if destinationOwner.type == 1 then
							if destinationOwner.owner == char:GetData('id') then
								TriggerClientEvent("mythic_inventory:client:AddWeapon", mPlayer:GetData('source'), destinationItem.itemId)
								TriggerClientEvent('mythic_base:client:AddComponentFromItem', mPlayer:GetData('source'), GetHashKey(destinationItem.itemId), destinationItem.metadata.components)
							else
								exports['ghmattimysql']:scalar('SELECT user FROM characters WHERE id = @charid LIMIT 1', { ['charid'] = tonumber(destinationOwner.owner) }, function(res)
									if res ~= nil then
										local tPlayer = exports['mythic_base']:FetchComponent('Fetch'):UserId(res)
										if tPlayer ~= nil then
											TriggerClientEvent("mythic_inventory:client:AddWeapon", tPlayer:GetData('source'), destinationItem.itemId)
											TriggerClientEvent('mythic_base:client:AddComponentFromItem', tPlayer:GetData('source'), GetHashKey(destinationItem.itemId), destinationItem.metadata.components)
										end
									end
								end)
							end
						end
					end
				end

				if originOwner.type == 2 then
					exports['ghmattimysql']:scalar('SELECT COUNT(owner) As DropInventory FROM inventory_items WHERE type = @type AND owner = @owner', { ['type'] = originOwner.type, ['owner'] = tostring(originOwner.owner) }, function(count)
						if tonumber(count) < 1 then
							TriggerClientEvent('mythic_inventory:client:CloseSecondary', -1, originOwner)
							TriggerEvent('mythic_inventory:server:RemoveBag', originOwner)
						else
							TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, originOwner, destinationOwner)
						end
					end)
				else
					TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, originOwner, destinationOwner)
				end
			else
				TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, originOwner, destinationOwner)
			end
		end)
	end)
end)

RegisterServerEvent('mythic_inventory:server:SplitStack')
AddEventHandler('mythic_inventory:server:SplitStack', function(originOwner, originItem, destinationOwner, destinationItem, moveQty)
    local src = source
	local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(src)
	local char = mPlayer:GetData('character')
	
	Citizen.CreateThread(function()
		char:splitStack(originOwner, originItem.slot, destinationOwner, destinationItem.slot, moveQty, function(status)
			if originOwner.type ~= destinationOwner.type or originOwner.owner ~= destinationOwner.owner then
				if originOwner.type == 2 then
					exports['ghmattimysql']:scalar('SELECT COUNT(owner) As DropInventory FROM inventory_items WHERE type = @type AND owner = @owner', { ['type'] = originOwner.type, ['owner'] = originOwner.owner}, function(count)
						if count < 1 then
							TriggerClientEvent('mythic_inventory:client:CloseSecondary', -1, originOwner)
							TriggerEvent('mythic_inventory:server:RemoveBag', originOwner)
						end
					end)
				else
					TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, originOwner, destinationOwner)
				end
			else
				TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, originOwner, destinationOwner)
			end
		end)
	end)
end)

RegisterServerEvent('mythic_inventory:server:CombineStack')
AddEventHandler('mythic_inventory:server:CombineStack', function(originOwner, originItem, destinationOwner, destinationItem)
    local src = source
	local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(src)
	local char = mPlayer:GetData('character')
	
	Citizen.CreateThread(function()
		char:combineStack(originOwner, originItem, destinationOwner, destinationItem.slot, function(status)
			local isDropClosing = false
			if originOwner.type ~= destinationOwner.type or originOwner.owner ~= destinationOwner.owner then
				if originOwner.type == 2 then
					exports['ghmattimysql']:scalar('SELECT COUNT(owner) As DropInventory FROM inventory_items WHERE type = @type AND owner = @owner', { ['type'] = originOwner.type, ['owner'] = originOwner.owner }, function(count)
						if count < 1 then
							isDropClosing = true
							TriggerClientEvent('mythic_inventory:client:CloseSecondary', -1, originOwner)
							TriggerEvent('mythic_inventory:server:RemoveBag', originOwner)
						else
							TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, originOwner, destinationOwner)
						end
					end)
				else
					TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, originOwner, destinationOwner)
				end
			else
				TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, originOwner, destinationOwner)
			end
		end)
	end)
end)

RegisterServerEvent('mythic_inventory:server:TopoffStack')
AddEventHandler('mythic_inventory:server:TopoffStack', function(originOwner, originItem, destinationOwner, destinationItem)
    local src = source
	local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(src)
	local char = mPlayer:GetData('character')

	
	Citizen.CreateThread(function()
		char:topoffStack(originOwner, originItem.slot, destinationOwner, destinationItem.slot, function()
			TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, originOwner, destinationOwner)
		end)
	end)
end)

RegisterServerEvent('mythic_inventory:server:SwapItems')
AddEventHandler('mythic_inventory:server:SwapItems', function(originOwner, originItem, destinationOwner, destinationItem)
    local src = source
	local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(src)
	local char = mPlayer:GetData('character')

	Citizen.CreateThread(function()
		char:swapItems(originOwner, originItem.slot, destinationOwner, destinationItem.slot, function(status)
			if (originOwner.type ~= destinationOwner.type or originOwner.owner ~= destinationOwner.owner) and status then
				if originOwner.type == 1 then
					exports['ghmattimysql']:scalar('SELECT user FROM characters WHERE id = @charid LIMIT 1', { ['charid'] = originOwner.owner }, function(res)
						if res ~= nil then
							local tPlayer = exports['mythic_base']:FetchComponent('Fetch'):UserId(res)
							if destinationItem.type == 1 then
								TriggerClientEvent("mythic_inventory:client:RemoveWeapon", tPlayer:GetData('source'), destinationItem.itemId)
							end
							if originItem.type == 1 then
								TriggerClientEvent("mythic_inventory:client:AddWeapon", tPlayer:GetData('source'), originItem.itemId)
								TriggerClientEvent('mythic_base:client:AddComponentFromItem', tPlayer:GetData('source'), originItem.itemId, originItem.metadata.components)
							end
						end
					end)
				end

				if destinationOwner.type == 1 then
					exports['ghmattimysql']:scalar('SELECT user FROM characters WHERE id = @charid LIMIT 1', { ['charid'] = destinationOwner.owner }, function(res)
						if res ~= nil then
							local tPlayer = exports['mythic_base']:FetchComponent('Fetch'):UserId(res)
							if originItem.type == 1 then
								TriggerClientEvent("mythic_inventory:client:RemoveWeapon", tPlayer:GetData('source'), originItem.itemId)
							end
							if destinationItem.type == 1 then
								TriggerClientEvent("mythic_inventory:client:AddWeapon", tPlayer:GetData('source'), destinationItem.itemId)
								TriggerClientEvent('mythic_base:client:AddComponentFromItem', tPlayer:GetData('source'), destinationItem.itemId, destinationItem.metadata.components)
							end
						end
					end)
				end
			end
			TriggerClientEvent('mythic_inventory:client:RefreshInventory2', -1, originOwner, destinationOwner)
		end)
	end)
end)

RegisterServerEvent('mythic_inventory:server:GiveItem')
AddEventHandler('mythic_inventory:server:GiveItem', function(target, item, count)
    local src = source
	local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(src)
	local char = mPlayer:GetData('character')
	local tPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(target)

	if tPlayer ~= nil then
		local tChar = tPlayer:GetData('character')

		Citizen.CreateThread(function()
			char:giveItem(tChar:GetData('id'), item.slot, count, function()
				TriggerClientEvent('mythic_inventory:client:RefreshInventory', mPlayer:GetData('source'))
				TriggerClientEvent('mythic_inventory:client:RefreshInventory', tPlayer:GetData('source'))
			end)
		end)
	end
end)

RegisterServerEvent('mythic_inventory:server:RemoveItem')
AddEventHandler('mythic_inventory:server:RemoveItem', function(uId, qty, disableNotif)
    local src = source
    local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(src)
    local char = mPlayer:GetData('character')

	Citizen.CreateThread(function()
		char:removeItem(uId, qty, function(status)
			TriggerClientEvent('mythic_inventory:client:RefreshInventory', src)
		end, disableNotif)
	end)
end)

RegisterServerEvent('mythic_inventory:server:GetPlayerInventory')
AddEventHandler('mythic_inventory:server:GetPlayerInventory', function()
	GetPlayerInventory(source)
end)

RegisterServerEvent('mythic_inventory:server:GetSecondaryInventory')
AddEventHandler('mythic_inventory:server:GetSecondaryInventory', function(source2, owner)
    local src = source2
	local mythic = exports['mythic_base']:FetchComponent('General')

	Citizen.CreateThread(function()
		mythic:GetInventory(owner.type, owner.owner, function(items)
			local itemsObject = {}
			for k, v in pairs(items) do
				local meta = {}
				if v["metadata"] ~= nil then
					meta = json.decode(v["metadata"])
				end
				local sMeta = {}
				if v["staticMeta"] ~= nil then
					sMeta = json.decode(v["staticMeta"])
				end
		
				table.insert(itemsObject, {
					id = v['id'],
					itemId = v['itemId'],
					description = v["description"],
					qty = v['qty'],
					slot = v['slot'],
					label = v['label'],
					type = v['type'],
					max = v['max'],
					stackable = v['stackable'],
					unique = v['unique'],
					usable = v['usable'],
					metadata = meta,
					staticMeta = sMeta,
					canRemove = true,
					price = v['price'],
					needs = v['needs_boost'],
					closeUi = v['closeUi'],
				})
			end

			local tier = 0
			if InvSlots[owner.type] ~= nil then
				tier = InvSlots[owner.type]
			else
				tier = InvSlots[0]
			end
		
			local data = {
				invId = owner,
				invTier = tier,
				inventory = itemsObject,
			}
		
			if owner.type == 2 and #itemsObject == 0 then
				TriggerEvent('mythic_inventory:server:RemoveBag', owner)
			else
				TriggerClientEvent('mythic_inventory:client:SetupSecondUI', src, data)
			end
		end)
	end)
end)

RegisterServerEvent('mythic_inventory:server:CheckItemCount')
AddEventHandler('mythic_inventory:server:CheckItemCount', function(unique, items)
	local src = source
	local char = exports['mythic_base']:FetchComponent('Fetch'):Source(src):GetData('character')
	local cData = char:GetData()

	Citizen.CreateThread(function()
		TriggerClientEvent('mythic_inventory:client:SendItemCountStatus', src, unique, CheckItems(1, cData.id, items))
	end)
end)

RegisterServerEvent('mythic_inventory:server:UseItemFromSlot')
AddEventHandler('mythic_inventory:server:UseItemFromSlot', function(token, slot)
    if not exports['salty_tokenizer']:secureServerEvent(GetCurrentResourceName(), source, token) then
		return false
	end

    local mPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(source)
    local char = mPlayer:GetData('character')

	if slot < 6 and slot > 0 then
		Citizen.CreateThread(function()
			char:getItemFromSlot(slot, function(item)
				if item ~= nil then
					if item.usable then
						TriggerEvent("mythic_base:server:UseItem", mPlayer:GetData('source'), item, slot)
					end
				end
			end)
		end)
	else
        exports['mythic_base']:FetchComponent('PwnzorLog'):CheatLog('Mythic Inventory', 'User #' .. mPlayer:GetData('data').id .. ' Attempted To Use Item In Slot ' .. slot)
        CancelEvent()
	end
end)

RegisterServerEvent('mythic_inventory:server:RobPlayer')
AddEventHandler('mythic_inventory:server:RobPlayer', function(target)
	local src = source
	local char = exports['mythic_base']:FetchComponent('Fetch'):Source(src):GetData('character')
	local cData = char:GetData()

	local tPlayer = exports['mythic_base']:FetchComponent('Fetch'):Source(target)

	if tPlayer ~= nil then
		tChar = tPlayer:GetData('character'):GetData()
		TriggerEvent('mythic_inventory:server:GetSecondaryInventory', target)
	end
end)