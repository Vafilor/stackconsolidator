local res_jobs = require('resources').jobs
require("strings")

Jobs = { cache = nil }

function Jobs.initialize()
    if Jobs.cache ~= nil then
        return
    end

    local cache = {}
    for _, job in pairs(res_jobs) do
        cache[job.en:lower()] = job.id
        cache[job.ens:lower()] = job.id
    end

    cache["puppetmaster"] = cache["monipulator"]
    cache["pup"] = cache["monipulator"]

    Jobs.cache = cache
end

---@param name string
---@return integer
function Jobs.get_id_for_name(name)
    return Jobs.cache[name:lower()]
end

return Jobs
