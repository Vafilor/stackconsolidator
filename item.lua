require("strings")
local constants = require("constants")
local res_items = require('resources').items

---@class Item
---@field id integer
---@field slot integer
---@field bag_id integer
---@field count integer
---@field name string
---@field max_stack integer
---@field res table
Item = {}

---@return Item
function Item:new(id, slot, count, bag_id)
    local obj = {
        id = id,
        slot = slot,
        bag_id = bag_id,
        count = count
    }

    if res_items[id] then
        local res = res_items[id]
        obj.name = res.name or ("ItemID " .. tostring(id))
        obj.max_stack = res.stack
        obj.res = res
    end

    setmetatable(obj, self)
    self.__index = self

    return obj
end

---@param linkshell_slot integer? The slot the player has their linkshell in, if any. Obtained from windower.ffxi.get_player().linkshell_slot
---@param player_equipment table<string, integer> obtained from windower.ffxi.get_items("equipment")
---@return boolean
function Item:is_moveable(linkshell_slot, player_equipment)
    -- If it is not in your inventory, it is movable.
    if self.bag_id ~= constants.id.INVENTORY then
        return true
    end

    -- Non-movable items include equipped items and equipped linkpearls
    if self.slot == linkshell_slot then
        return false
    end

    for _, slot_name in pairs(constants.equipment.slot_names) do
        local slot_bag_name = slot_name .. "_bag"
        -- The equipment is in the inventory in the slot this piece occupies, so its not movable
        if player_equipment[slot_bag_name] == 0 and player_equipment[slot_name] == self.slot then
            return false
        end
    end

    return true
end

---@param flag string
---@return boolean True if the item has the input flag
function Item:has_flag(flag)
    for res_flag, _ in pairs(self.res.flags) do
        if res_flag == flag then
            return true
        end
    end

    return false
end

---@param category string
---@return boolean True if the item has the input category
function Item:has_category(category)
    return self.res.category:lower() == category:lower()
end

return Item
