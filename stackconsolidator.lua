_addon.name = 'StackConsolidator'
_addon.author = 'Vafilor'
_addon.version = '1.1'
_addon.commands = { 'stack' }
_addon.windower = '4'

res_items = require('resources').items
packets = require('packets')
storage = require("storage")
require("logger")

local inventories = {
    { id = 0,  name = 'inventory' },
    { id = 1,  name = 'safe' },
    { id = 2,  name = 'storage' },
    { id = 4,  name = 'locker' },
    { id = 5,  name = 'satchel' },
    { id = 6,  name = 'sack' },
    { id = 7,  name = 'case' },
    { id = 10, name = 'safe2' }
}

function message(text, to_log)
    if (text == nil or #text < 1) then
        return
    end

    if (to_log) then
        log(text)
    else
        windower.add_to_chat(207, _addon.name .. ": " .. text)
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

-- The part moves all items to maximze stacks.
-- If you have 50 iron arrows in mog safe and 30 in mog safe 2, and 55 in inventory,
-- It will move 49 to mog safe and 6 to mog safe 2.
-- It does not attempt to organize like items together.
-- However, it does skip moving things to the player inventory.
function stack_items(dry_run)
    local inventory = storage:new(dry_run)

    message("Starting stacking items")
    local all_items = get_all_stackable_items()
    local grouped = group_items_by_id(all_items)

    for _, group in pairs(grouped) do
        local partials = find_merge_candidates(group)
        table.sort(partials, function(a, b)
            -- Put player inventory last
            if a.bag == 0 then
                return false
            elseif b.bag == 0 then
                return true
            end

            return a.count > b.count
        end)


        while #partials > 1 do
            local target = table.remove(partials, 1)
            local donor = table.remove(partials)

            local move_count = math.min(donor.count, target.max_stack - target.count)

            local moved = inventory:move(donor, move_count, target.bag)

            if not dry_run and moved then
                coroutine.sleep(1)
            end
            target.count = target.count + move_count
            donor.count = donor.count - move_count

            if donor.count > 0 then
                table.insert(partials, donor)
            end
        end
    end

    message("Done")
end

windower.register_event('addon command', function(cmd, ...)
    message(cmd)

    local args = T { ... }

    local real_run = args:contains("--run")

    if cmd == 'items' then
        stack_items(not real_run)
    end
end)
