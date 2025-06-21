_addon.name = 'StackConsolidator'
_addon.author = 'Vafilor'
_addon.version = '1.1'
_addon.commands = { 'stack', 'list' }
_addon.windower = '4'

local Storage = require("storage")
local message = require("message")

local Spells = require("spells")
local Jobs = require("jobs")


require("logger")


---@param items Item[]
---@return table<integer, Item>
local function group_items_by_id(items)
    local grouped = {}
    for _, item in ipairs(items) do
        if not grouped[item.id] then
            grouped[item.id] = {}
        end
        table.insert(grouped[item.id], item)
    end
    return grouped
end

---@return Item[]
local function find_merge_candidates(group)
    local partials = {}
    for _, item in ipairs(group) do
        if item.count < item.max_stack then
            table.insert(partials, item)
        end
    end
    return partials
end

-- The part moves all items to maximze stacks.
-- If you have 50 iron arrows in mog safe and 30 in mog safe 2, and 55 in inventory,
-- It will move 49 to mog safe and 6 to mog safe 2.
-- It does not attempt to organize like items together.
-- However, it does skip moving things to the player inventory.
local function stack_items(dry_run)
    local inventory = Storage:new(dry_run)

    message("Starting stacking items")
    local total_moved = 0
    local all_items = inventory:get_all_stackable_items()
    local grouped = group_items_by_id(all_items)

    for _, group in pairs(grouped) do
        local partials = find_merge_candidates(group)
        table.sort(partials, function(a, b)
            -- Put player inventory last
            if a.bag_id == 0 then
                return false
            elseif b.bag_id == 0 then
                return true
            end

            return a.count > b.count
        end)

        while #partials > 1 do
            ---@type Item
            local target = table.remove(partials, 1)

            ---@type Item
            local donor = table.remove(partials)

            local move_count = math.min(donor.count, target.max_stack - target.count)

            local moved = inventory:move(donor, move_count, target.bag_id)
            if moved then
                total_moved = total_moved + 1
            end

            if not dry_run and moved then
                coroutine.sleep(1)
            end

            target.count = target.count + move_count
            donor.count = donor.count - move_count

            if target.count < target.max_stack then
                table.insert(partials, 1, target)
            end

            if donor.count > 0 then
                table.insert(partials, donor)
            end
        end
    end

    message(string.format("Done. Moved %d items", total_moved))
end

local function print_stats()
    message("        Stats      ")
    local inventory = Storage:new(false)

    for _, inv in pairs(inventory.inventory) do
        message(string.format("%-10s %4s %4s", inv.name, tostring(inv.count), tostring(inv.max)))
    end
end

---@param flag string
---@param job_name string?
local function list_items_with_flag_or_category(flag, job_name)
    local job_id = nil

    if flag == "Scroll" then
        Jobs.initialize()
        Spells.load_cache()

        if job_name then
            job_id = Jobs.get_id_for_name(job_name)
        end
    end

    local inventory = Storage:new(true)

    for _, item in pairs(inventory:get_all_items()) do
        local valid = item:has_flag(flag) or item:has_category(flag)
        if valid and job_id ~= nil then
            local spell = Spells.get_for_name(item.name)

            if spell then
                valid = Spells.can_learn(spell, job_id)
            else
                -- We're looking for a specific job
                valid = false
            end
        end

        if valid then
            message(inventory.inventory[item.bag_id].name .. ": " .. item.name)
        end
    end

    message("Done")
end

windower.register_event('addon command', function(cmd, ...)
    message(cmd)

    local args = T { ... }

    local real_run = args:contains("--run")

    if cmd == 'items' then
        coroutine.schedule(function()
            stack_items(not real_run)
        end, 0)
    elseif cmd == "stats" then
        print_stats()
    elseif cmd == "list" then
        if args[1] == nil then
            message("Need a flag or category.")
            message("//inv list Scroll")
            message("//inv list Weapon")
            message("If using Scroll, you can provide a Job after that to restrict Scrolls learnable by that job")
            message("//inv list Scroll whm")
        else
            coroutine.schedule(function()
                list_items_with_flag_or_category(args[1], args[2])
            end, 0)
        end
    end
end)
