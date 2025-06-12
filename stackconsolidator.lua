_addon.name = 'StackConsolidator'
_addon.author = 'Vafilor'
_addon.version = '1.1'
_addon.commands = {'stack'}
_addon.windower = '4'

res_items = require('resources').items
packets = require('packets')

local inventories = {
    {id=0, name='inventory'},
    {id=1, name='safe'},
    {id=2, name='storage'},
    {id=4, name='locker'},
    {id=5, name='satchel'},
    {id=6, name='sack'},
    {id=7, name='case'},
    {id=10, name='safe2'}
}

function message(text, to_log) 
	if (text == nil or #text < 1) then
		return
	end

	if (to_log) then
		log(text)
	else
		windower.add_to_chat(207, _addon.name..": "..text)
	end
end

function get_all_stackable_items()
    local all = {}
    for _, inv in ipairs(inventories) do
        local bag = windower.ffxi.get_items(inv.name)
        if not bag then
            log("Skipping inaccessible bag: " .. inv.name)
        else
            for i, item in ipairs(bag) do
                if item.id and item.id ~= 0 then
                    local res = res_items[item.id]
                    if res.stack > 1 then
                        table.insert(all, {
                            item_id = item.id,
                            count = item.count,
                            slot = i,
                            bag = inv.id,
                            bag_name = inv.name,
                            max_stack = res.stack
                        })
                    end
                end
            end
        end
    end
    return all
end

function group_items_by_id(items)
    local grouped = {}
    for _, item in ipairs(items) do
        if not grouped[item.item_id] then
            grouped[item.item_id] = {}
        end
        table.insert(grouped[item.item_id], item)
    end
    return grouped
end

function find_merge_candidates(group)
    local partials = {}
    for _, item in ipairs(group) do
        if item.count < item.max_stack then
            table.insert(partials, item)
        end
    end
    return partials
end

function stack_items()
    message("Starting stacking items")
    local all_items = get_all_stackable_items()
    message("Total stackable items found: " .. tostring(#all_items))
    local grouped = group_items_by_id(all_items)

    local move_log = {}

    for item_id, group in pairs(grouped) do
        local partials = find_merge_candidates(group)

        while #partials > 1 do
            table.sort(partials, function(a, b) return a.count > b.count end)
            local target = table.remove(partials, 1)
            local donor = table.remove(partials)

            local move_count = math.min(donor.count, target.max_stack - target.count)
            local item_name = res_items[item_id] and res_items[item_id].name or ("ItemID " .. tostring(item_id))

            message(string.format("Moving %d of %s from %s to %s",
                move_count, item_name, donor.bag_name, target.bag_name))

            -- windower.packets.inject_outgoing(0x29, packets.new('outgoing', 0x29, {
            --     Count = move_count,
            --     From_Bag = donor.bag,
            --     From_Slot = donor.slot,
            --     To_Bag = target.bag,
            --     To_Slot = target.slot
            -- }))

            table.insert(move_log, string.format("%s: %d from %s to %s",
                item_name, move_count, donor.bag_name, target.bag_name))

            coroutine.sleep(0.2)
            target.count = target.count + move_count
            donor.count = donor.count - move_count

            if donor.count > 0 then
                table.insert(partials, donor)
            end
        end
    end

    log("Consolidation complete. Summary:")
    for _, entry in ipairs(move_log) do
        log("  - " .. entry)
    end
end

windower.register_event('addon command', function(cmd)
    message(cmd)
    if cmd == 'items' then
        coroutine.schedule(stack_items, 0)
    end
end)
