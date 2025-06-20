local res_items = require('resources').items

---@class Item
---@field id integer
---@field slot integer
---@field bag_id integer
---@field count integer
---@field name string
---@field max_stack integer
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

return Item
