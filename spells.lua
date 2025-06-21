local res_spells = require('resources').spells

Spells = {
    cache = nil
}

function Spells.load_cache()
    if Spells.cache ~= nil then
        return
    end

    local cache = {}
    for _, spell in pairs(res_spells) do
        cache[spell.name] = spell
    end

    Spells.cache = cache
end

---@param name string
---@return table
function Spells.get_for_name(name)
    return Spells.cache[name]
end

---@param job_id integer
---@return boolean
function Spells.can_learn(spell, job_id)
    return spell.levels[job_id] ~= nil
end

return Spells
