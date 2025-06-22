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

require("strings")
local constants = require("constants")
local res_items = require('resources').items
require("logger")


-- Copied from resources.
local crystals = {
    [4096] = { id = 4096, en = "Fire Crystal", ja = "炎のクリスタル", enl = "fire crystal", jal = "炎のクリスタル", cast_time = 0, category = "Usable", flags = 516, stack = 12, targets = 1, type = 8 },
    [4097] = { id = 4097, en = "Ice Crystal", ja = "氷のクリスタル", enl = "ice crystal", jal = "氷のクリスタル", cast_time = 0, category = "Usable", flags = 516, stack = 12, targets = 1, type = 8 },
    [4098] = { id = 4098, en = "Wind Crystal", ja = "風のクリスタル", enl = "wind crystal", jal = "風のクリスタル", cast_time = 0, category = "Usable", flags = 516, stack = 12, targets = 1, type = 8 },
    [4099] = { id = 4099, en = "Earth Crystal", ja = "土のクリスタル", enl = "earth crystal", jal = "土のクリスタル", cast_time = 0, category = "Usable", flags = 516, stack = 12, targets = 1, type = 8 },
    [4100] = { id = 4100, en = "Lightng. Crystal", ja = "雷のクリスタル", enl = "lightning crystal", jal = "雷のクリスタル", cast_time = 0, category = "Usable", flags = 516, stack = 12, targets = 1, type = 8 },
    [4101] = { id = 4101, en = "Water Crystal", ja = "水のクリスタル", enl = "water crystal", jal = "水のクリスタル", cast_time = 0, category = "Usable", flags = 516, stack = 12, targets = 1, type = 8 },
    [4102] = { id = 4102, en = "Light Crystal", ja = "光のクリスタル", enl = "light crystal", jal = "光のクリスタル", cast_time = 0, category = "Usable", flags = 516, stack = 12, targets = 1, type = 8 },
    [4103] = { id = 4103, en = "Dark Crystal", ja = "闇のクリスタル", enl = "dark crystal", jal = "闇のクリスタル", cast_time = 0, category = "Usable", flags = 516, stack = 12, targets = 1, type = 8 },
    [4104] = { id = 4104, en = "Fire Cluster", ja = "炎の塊", enl = "fire cluster", jal = "炎の塊", cast_time = 1, category = "Usable", flags = 1548, stack = 12, targets = 1, type = 7 },
    [4105] = { id = 4105, en = "Ice Cluster", ja = "氷の塊", enl = "ice cluster", jal = "氷の塊", cast_time = 1, category = "Usable", flags = 1548, stack = 12, targets = 1, type = 7 },
    [4106] = { id = 4106, en = "Wind Cluster", ja = "風の塊", enl = "wind cluster", jal = "風の塊", cast_time = 1, category = "Usable", flags = 1548, stack = 12, targets = 1, type = 7 },
    [4107] = { id = 4107, en = "Earth Cluster", ja = "土の塊", enl = "earth cluster", jal = "土の塊", cast_time = 1, category = "Usable", flags = 1548, stack = 12, targets = 1, type = 7 },
    [4108] = { id = 4108, en = "Lightning Cluster", ja = "雷の塊", enl = "lightning cluster", jal = "雷の塊", cast_time = 1, category = "Usable", flags = 1548, stack = 12, targets = 1, type = 7 },
    [4109] = { id = 4109, en = "Water Cluster", ja = "水の塊", enl = "water cluster", jal = "水の塊", cast_time = 1, category = "Usable", flags = 1548, stack = 12, targets = 1, type = 7 },
    [4110] = { id = 4110, en = "Light Cluster", ja = "光の塊", enl = "light cluster", jal = "光の塊", cast_time = 1, category = "Usable", flags = 1548, stack = 12, targets = 1, type = 7 },
    [4111] = { id = 4111, en = "Dark Cluster", ja = "闇の塊", enl = "dark cluster", jal = "闇の塊", cast_time = 1, category = "Usable", flags = 1548, stack = 12, targets = 1, type = 7 }
}


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

---@return boolean
function Item:is_furniture()
    -- 12 seems to be Pots, 10 is other furniture
    return self.res.type == 10 or self.res.type == 12
end

---@return boolean
function Item:is_crystal()
    return crystals[self.id] ~= nil
end

---@return boolean
function Item:is_equpiment()
    return self.res.category == "Armor" or self.res.category == "Armor"
end

---@param linkshell_slot integer? The slot the player has their linkshell in, if any. Obtained from windower.ffxi.get_player().linkshell_slot
---@param player_equipment table<string, integer> obtained from windower.ffxi.get_items("equipment")
---@return boolean
function Item:is_moveable(linkshell_slot, player_equipment)
    -- If it is in your Mog Safe 1 or 2 and furniture, it could be laid out in your house
    -- It's hard to tell if it is, so we say all furniture is not movable there
    if self:is_furniture() and (self.bag_id == constants.id.SAFE or self.bag_id == constants.id.SAFE_2) then
        return false
    end

    -- If it is not in your inventory otherwise, it is most likely movable.
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
