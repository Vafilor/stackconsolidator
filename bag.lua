local constants = require("constants")
local inventories = constants.inventories
local Item = require("item")

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
end

---@return boolean
function Bag:is(id)
    return self.id == id
end

---@return boolean
function Bag:has_free_slot()
    return self.space > 0
end

---@return Item?
function Bag:get_item(id)
    local bag = windower.ffxi.get_items(self.name)
    if not bag then
        return nil
    end

    for _, item in ipairs(bag) do
        if item.id == id then
            return Item:new(item.id, item.slot, item.count, self.id)
        end
    end

    return nil
end

return Bag
