local res_items = require('resources').items
local constants = require("constants")
local inventories = constants.inventories

Bag = {}

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

function Bag:is(id)
    return self.id == id
end

function Bag:has_free_slot()
    return self.space > 0
end

function Bag:get_item(id)
    local bag = windower.ffxi.get_items(self.name)
    if not bag then
        return nil
    end

    for i, item in ipairs(bag) do
        if item.id == id then
            local res = res_items[item.id]
            return {
                item_id = item.id,
                count = item.count,
                slot = i,
                bag = self.id,
                bag_name = self.name,
                max_stack = res.stack
            }
        end
    end

    return nil
end

return Bag
