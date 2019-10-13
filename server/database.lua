function checkItemCount(type, id, itemid, count, cb)
	exports['ghmattimysql']:scalar('SELECT SUM(qty) FROM inventory_items WHERE type = @type AND owner = @id AND itemid = @item', { ['item'] = itemid, ['type'] = type, ['id'] = id }, function(has)
		if has ~= nil then
			cb(has >= count)
		else
			cb(false)
		end
	end)
end