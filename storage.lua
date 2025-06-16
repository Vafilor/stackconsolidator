local res_items = require('resources').items
local packets = require("packets")

local INVENTORY_ID = 0

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

Storage = {}

function Storage:new(dry_run)
    local obj = {
        inventory = {
            [0] = { id = 0, name = 'inventory' },
            [1] = { id = 1, name = 'safe' },
            [2] = { id = 2, name = 'storage' },
            [4] = { id = 4, name = 'locker' },
            [5] = { id = 5, name = 'satchel' },
            [6] = { id = 6, name = 'sack' },
            [7] = { id = 7, name = 'case' },
            [10] = { id = 10, name = 'safe2' }
        },
        limit = 0,
        sleep_between_move_and_sort = 1,
        dry_run = dry_run
    }

    for _, inv in pairs(obj.inventory) do
        local bag = windower.ffxi.get_items(inv.name)
        if bag then
            inv.count = bag.count
            inv.max = bag.max
        end
    end

    setmetatable(obj, self)
    self.__index = self

    return obj
end

function Storage:load_counts(inventory_id)
    local inv = self.inventory[inventory_id]
    local bag = windower.ffxi.get_items(inv.name)
    if bag then
        inv.count = bag.count
        inv.max = bag.max
    end
end

function Storage:get_bag_name(bag_id)
    local bag = self.inventory[bag_id]
    if not bag then
        return nil
    end

    return bag.name
end

function Storage:get_item_name(item_id)
    return res_items[item_id] and res_items[item_id].name or ("ItemID " .. tostring(item_id))
end

function Storage:perform_move(item, count, bag_id)
    if self.dry_run then
        return
    end

    local packet = packets.new('outgoing', 0x29, {
        ["Count"] = count,
        ["Bag"] = item.bag,
        ["Target Bag"] = bag_id,
        ["Current Index"] = item.slot,
        ["Target Index"] = 0x52
    })

    packets.inject(packet)

    coroutine.sleep(self.sleep_between_move_and_sort)

    local packet = packets.new('outgoing', 0x03A, {
        ["Bag"] = bag_id,
        ["_unknown1"] = 0,
        ["_unknown2"] = 0
    })

    packets.inject(packet)

    self:load_counts(item.bag)
    self:load_counts(bag_id)
end

function Storage:move(item, count, bag_id)
    local item_name = self:get_item_name(item.item_id)

    -- TODO support moving between other storages.
    -- First move to player inventory, then the other storage
    -- it is possible you might not have space in inventory or the target, even though a stack spot is open
    -- This requires some checking to make sure we CAN do it, and then moving inventory around to do it.
    if item.bag == INVENTORY_ID then
        if self:has_free_slot(bag_id) then
            print(string.format("Moving %d %s from %s to %s", count, item_name, item.bag_name, self:get_bag_name(bag_id)))
            self:perform_move(item, count, bag_id)
            return
        end
    end
end

--- Checks if a bag has at least one free slot available.
--
-- @param storage_id int The id of the inventory, 0 = player inventory
-- @return boolean true if the bag has free space, false if full or inaccessible
function Storage:has_free_slot(storage_id)
    return self.inventory[storage_id].count < self.inventory[storage_id].max
end

return Storage
