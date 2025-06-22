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

local constants = require("constants")
local Item = require("item")
local packets = require("packets")
local inventories = constants.inventories
require("logger")


---@class Bag
---@field id integer
---@field name string
---@field count integer
---@field max integer
---@field space integer
Bag = {}

---@return Bag
function Bag:new(id)
    local obj = {
        id = id,
        name = inventories[id].name,
        count = 0,
        max = 0,
        space = 0
    }

    local bag = windower.ffxi.get_items(obj.name)
    if bag then
        obj.count = bag.count
        obj.max = bag.max
        obj.space = bag.max - bag.count
        obj.bag = bag
    end

    setmetatable(obj, self)
    self.__index = self

    return obj
end

function Bag:reload()
    local bag = windower.ffxi.get_items(self.name)
    if not bag then
        return
    end

    self.count = bag.count
    self.max = bag.max
    self.space = bag.max - bag.count
    self.bag = bag
end

---@return boolean
function Bag:is(id)
    return self.id == id
end

---@return boolean
function Bag:has_free_slot()
    return self.space > 0
end

---@param id integer
---@param count integer?
---@return Item?
function Bag:get_item(id, count)
    if not self.bag then
        return nil
    end

    for _, item in ipairs(self.bag) do
        if item.id == id and (count == nil or item.count == count) then
            return Item:new(item.id, item.slot, item.count, self.id)
        end
    end

    return nil
end

---@param linkshell_slot integer? The slot the player has their linkshell in, if any. Obtained from windower.ffxi.get_player().linkshell_slot
---@param player_equipment table<string, integer> obtained from windower.ffxi.get_items("equipment")
---@param exclude_id integer? If provided, the bag will skip items with this id
---@return Item?
function Bag:get_random_movable_item(linkshell_slot, player_equipment, exclude_id)
    for _, bag_item in pairs(self.bag) do
        if bag_item.id ~= exclude_id then
            local item = Item:new(bag_item.id, bag_item.slot, bag_item.count, self.id)
            if item:is_moveable(linkshell_slot, player_equipment) then
                return item
            end
        end
    end

    return nil
end

-- Sends a packet to sort the bag
function Bag:server_sort()
    local packet = packets.new('outgoing', 0x03A, {
        ["Bag"] = self.id,
        ["_unknown1"] = 0,
        ["_unknown2"] = 0
    })

    packets.inject(packet)
end

return Bag
