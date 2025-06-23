--[[Copyright © 2025, Vafilor
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.--]]

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
---@field linkshell_slot integer
---@field player_equipment table
---@field debug boolean
Storage = {}

---@param in_mog_house boolean if false, restricts the inventories to those available outside the mog house. Otherwise all of them.
---@return Storage
function Storage:new(in_mog_house)
    local obj = {
        -- TODO rename these to bags
        inventory = {},
        sleep_between_move_and_sort = 1,
        sleep_after_sort = 1,
        dry_run = false,
        debug = false,
        in_mog_house = in_mog_house,
        linkshell_slot = windower.ffxi.get_player().linkshell_slot,
        player_equipment = windower.ffxi.get_items("equipment"),
        temp_prefix = "   "
    }

    for _, inv in pairs(inventories) do
        if not inv.mog_house_only or (obj.in_mog_house and inv.mog_house_only) then
            obj.inventory[inv.id] = Bag:new(inv.id)
        end
    end

    setmetatable(obj, self)
    self.__index = self

    return obj
end

--- Gets items from all inventories that can be stacked.
---@return Item[]
function Storage:get_all_stackable_items()
    local all = {}
    for _, inv in pairs(self.inventory) do
        local inv_items = windower.ffxi.get_items(inv.id)
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

--- Gets all items from all of your avaiable inventories
---@return Item[]
function Storage:get_all_items()
    local all = {}
    for _, inv in pairs(self.inventory) do
        local inv_items = windower.ffxi.get_items(inv.id)
        if not inv_items then
            log("Skipping inaccessible bag: " .. inv.name)
        else
            for _, item in ipairs(inv_items) do
                if item.id and item.id ~= 0 then
                    table.insert(all, Item:new(item.id, item.slot, item.count, inv.id))
                end
            end
        end
    end

    return all
end

---@param exclude_bag_ids table?
---@param min_space integer
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

---@param item Item
---@param count integer
---@param source_bag Bag
---@param target_bag Bag
---@param prefix string? debug message to prefix, if any
function Storage:perform_move(item, count, source_bag, target_bag, prefix)
    if self.debug then
        if prefix == nil then
            prefix = ""
        end
        message(string.format("%sMoving %d %s from %s to %s", prefix, count, item.name, source_bag.name, target_bag.name))
    end

    if self.dry_run then
        return
    end

    local packet = packets.new('outgoing', 0x029, {
        ["Count"] = count,
        ["Bag"] = source_bag.id,
        ["Target Bag"] = target_bag.id,
        ["Current Index"] = item.slot,
        ["Target Index"] = 0x52
    })

    packets.inject(packet)

    coroutine.sleep(self.sleep_between_move_and_sort)

    target_bag:server_sort()

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
    if self.dry_run then
        return true
    end

    local temp_moves = {}

    -- Move to inventory first
    if not source_bag:is(ids.INVENTORY) then
        if not inventory_bag:has_free_slot() then
            local cache_bag = self:get_cache_bag({ ids.INVENTORY }, 1)
            if not cache_bag then
                if self.debug then
                    message(
                        "Temporarily moving to inventory, inventory has no free slot and no suitable bag found to move to")
                end
                return false
            end

            local random_item = inventory_bag:get_random_movable_item(self.linkshell_slot, self.player_equipment)
            if not random_item then
                if self.debug then
                    message("Unable to get a movable item from the inventory to temporarily move")
                end
                return false
            end

            table.insert(temp_moves, {
                item = random_item,
                from_bag = inventory_bag,
                to_bag = cache_bag
            })
            self:perform_move(random_item, random_item.count, inventory_bag, cache_bag, self.temp_prefix)
        end

        self:perform_move(item, count, source_bag, inventory_bag, self.temp_prefix)
    end

    -- At this point, we are moving from the inventory to a target bag

    -- Here we need to make sure the target bag has a slot
    if not target_bag:has_free_slot() then
        if not inventory_bag:has_free_slot() then
            local cache_bag = self:get_cache_bag({ ids.INVENTORY }, 1)
            if not cache_bag then
                if self.debug then
                    message(target_bag.name .. " has no free slot, neither does inventory and no suitable space found")
                end
                return false
            end

            local random_item = inventory_bag:get_random_movable_item(self.linkshell_slot, self.player_equipment,
                item.id)
            if not random_item then
                if self.debug then
                    message(target_bag.name ..
                        " has no space, neither does inventory. Unable to get a movable item from the inventory.")
                end
                return false
            end

            table.insert(temp_moves, {
                item = random_item,
                from_bag = inventory_bag,
                to_bag = cache_bag
            })
            self:perform_move(random_item, random_item.count, inventory_bag, cache_bag, self.temp_prefix)
        end

        -- move a random item to the inventory
        local random_item = target_bag:get_random_movable_item(self.linkshell_slot, self.player_equipment)
        if not random_item then
            message("Unable to get a movable item from the target bag " .. target_bag.name)
            return false
        end

        table.insert(temp_moves, {
            item = random_item,
            from_bag = target_bag,
            to_bag = inventory_bag
        })
        self:perform_move(random_item, random_item.count, target_bag, inventory_bag, self.temp_prefix)
    end


    -- We need to get the slot the item is now in
    local item_in_inventory = inventory_bag:get_item(item.id, item.count)
    if not item_in_inventory then
        if self.debug then
            message("Item should have been moved to inventory, but it is not found.")
        end
        return false
    end

    self:perform_move(item_in_inventory, item_in_inventory.count, inventory_bag, target_bag, self.temp_prefix)

    local unwind_moves = #temp_moves
    if self.debug and unwind_moves ~= 0 then
        message(self.temp_prefix .. "Unwinding")
    end

    -- Now unwind the moves
    while #temp_moves > 0 do
        local last_move = table.remove(temp_moves)

        local item_in_target = last_move.to_bag:get_item(last_move.item.id)
        if not item_in_target then
            if self.debug then
                message(last_move.item.name .. " should have been moved to target, but it is not found.")
            end
            return false
        end

        self:perform_move(item_in_target, item_in_target.count, last_move.to_bag,
            last_move.from_bag, self.temp_prefix .. self.temp_prefix)
    end


    return true
end

return Storage
