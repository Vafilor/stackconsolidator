require("logger")
local res_items = require('resources').items
local packets = require("packets")
local Bag = require("bag")
local Item = require("item")
local message = require("message")
local constants = require("constants")
local ids = constants.id

local inventories = constants.inventories


---@class Storage
---@field inventory table<integer, Bag>
---@field sleep_between_move_and_sort number
---@field sleep_after_sort number
---@field dry_run boolean
Storage = {}

---@return Storage
function Storage:new(dry_run)
    local obj = {
        inventory = {},
        sleep_between_move_and_sort = 1,
        sleep_after_sort = 1,
        dry_run = dry_run
    }

    for _, inv in pairs(inventories) do
        obj.inventory[inv.id] = Bag:new(inv.id)
    end

    setmetatable(obj, self)
    self.__index = self

    return obj
end

--- Gets items from all inventories that can be stacked.
---@return Item[]
function Storage:get_all_stackable_items()
    local all = {}
    for _, inv in pairs(inventories) do
        local inv_items = windower.ffxi.get_items(inv.name)
        if not inv_items then
            log("Skipping inaccessible bag: " .. inv.name)
        else
            for _, item in ipairs(inv_items) do
                if item.id and item.id ~= 0 then
                    local res = res_items[item.id]
                    if res.stack > 1 then
                        table.insert(all, Item:new(item.id, item.slot, item.count, inv.id))
                    end
                end
            end
        end
    end

    return all
end

function Storage:get_available_space_excluding_bags(excluding_bag_ids)
    if excluding_bag_ids == nil then
        excluding_bag_ids = {}
    end

    -- TODO does lua have a set type?
    local exclude = {}
    for _, bag_id in pairs(excluding_bag_ids) do
        exclude[bag_id] = true
    end


    local space_available = 0
    for _, inventory in pairs(self.inventory) do
        if not exclude[inventory.id] then
            space_available = space_available + inventory.space
        end
    end

    return space_available
end

function Storage:get_cache_bag(exclude_bag_ids, min_space)
    if exclude_bag_ids == nil then
        exclude_bag_ids = {}
    end

    local exclude = {}
    for _, bag_id in pairs(exclude_bag_ids) do
        exclude[bag_id] = true
    end


    for _, inventory in pairs(self.inventory) do
        if not exclude[inventory.id] and inventory.space >= min_space then
            return inventory
        end
    end

    return nil
end

---@param item_slot integer
---@param count integer
---@param source_bag Bag
---@param target_bag Bag
function Storage:perform_move(item_slot, count, source_bag, target_bag)
    if self.dry_run then
        return
    end

    local packet = packets.new('outgoing', 0x029, {
        ["Count"] = count,
        ["Bag"] = source_bag.id,
        ["Target Bag"] = target_bag.id,
        ["Current Index"] = item_slot,
        ["Target Index"] = 0x52
    })

    packets.inject(packet)

    coroutine.sleep(self.sleep_between_move_and_sort)

    local packet = packets.new('outgoing', 0x03A, {
        ["Bag"] = target_bag.id,
        ["_unknown1"] = 0,
        ["_unknown2"] = 0
    })

    packets.inject(packet)

    coroutine.sleep(self.sleep_after_sort)

    source_bag:reload()
    target_bag:reload()
end

--- Attempts to move a number of an item to a bag.
---
---@param item Item
---@param count integer
---@param bag_id integer
---@return boolean true if the item was moved, false otherwise.
function Storage:move(item, count, bag_id)
    local inventory_bag = self.inventory[ids.INVENTORY]
    local source_bag = self.inventory[item.bag_id]
    local target_bag = self.inventory[bag_id]

    -- Skip trying to move to the same bag.
    -- This shouldn't happen, but just in case.
    if source_bag:is(target_bag.id) then
        return false
    end

    -- Case 1: Move from a bag to the player's inventory - ignored.
    if not source_bag:is(ids.INVENTORY) and target_bag:is(ids.INVENTORY) then
        return false
    end


    message(string.format("Moving %d %s from %s to %s", count, item.name, source_bag.name, target_bag.name))

    -- Case 2: Move from player's inventory to a different bag.
    if source_bag:is(ids.INVENTORY) then
        if target_bag:has_free_slot() then
            self:perform_move(item.slot, count, source_bag, target_bag)
            return true
        end

        message(string.format("Unable to move %d %s from %s to %s. No space in %s", count,
            item.name, source_bag.name,
            target_bag.name, target_bag.name))
        -- TODO handle this case
        return false
    end

    -- TODO you don't always need to sort after. Remove when you don't, save some time.

    -- Case 3: Move from a bag to another bag
    -- First we have to move it to the inventory
    -- then to the target bag
    if not source_bag:is(ids.INVENTORY) and not target_bag:is(ids.INVENTORY) then
        if not inventory_bag:has_free_slot() then
            message(string.format(
                "Unable to move %d %s from %s to %s. No space in inventory which acts as an intermediate", count,
                item.name, source_bag.name,
                target_bag.name))

            return false
        end

        if not target_bag:has_free_slot() then
            message(string.format("Unable to move %d %s from %s to %s. No space in %s", count,
                item.name, source_bag.name,
                target_bag.name))
            return false
        end

        self:perform_move(item.slot, count, source_bag, inventory_bag)

        if self.dry_run then
            return true
        end

        local moved_item = inventory_bag:get_item(item.id)
        if moved_item == nil then
            message(string.format("Unable to move %d %s from %s to %s. Unable to find item", count,
                item.name, inventory_bag.name,
                target_bag.name))
            return false
        end

        self:perform_move(moved_item.slot, count, inventory_bag, target_bag)

        return true
    end

    return false
end

return Storage
