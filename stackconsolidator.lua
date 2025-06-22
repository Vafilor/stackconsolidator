_addon.name = 'StackConsolidator'
_addon.author = 'Vafilor'
_addon.version = '1.1'
_addon.commands = { 'stack', 'list', 'find', 'suggest' }
_addon.windower = '4'

local Storage = require("storage")
local message = require("message")

local Spells = require("spells")
local Jobs = require("jobs")
local res_bags = require("resources").bags
local res_items = require("resources").items

require("strings")
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
local function stack_items(dry_run, debug)
    local inventory = Storage:new(windower.ffxi.get_info().mog_house)
    inventory.dry_run = dry_run
    inventory.debug = debug

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
    local inventory = Storage:new(true)

    for _, inv in pairs(inventory.inventory) do
        message(string.format("%-10s %4s %4s", inv.name, tostring(inv.count), tostring(inv.max)))
    end
end

local function list_item_stacks()
    for _, bag in pairs(res_bags) do
        local items = windower.ffxi.get_items(bag.id)
        if not items then
            message("Skipping inaccessible bag: " .. bag.name)
        else
            for _, item in ipairs(items) do
                print(item.count)
                -- Don't list items that have a stack of 1
                if item.count > 1 then
                    local res_item = res_items[item.id]
                    if res_item ~= nil and res_item.stack == item.count then
                        message(string.format("%d %s in %s slot: %d", item.count, res_item.name, bag.name, item.slot))
                    end
                end
            end
        end
    end

    message("Done")
end

---@param flag string
---@param job_name string?
local function list_items(flag, job_name)
    if flag:lower() == "stacks" then
        list_item_stacks()
        return
    end
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
            message(inventory.inventory[item.bag_id].name .. ": " .. item.name .. " slot " .. tostring(item.slot))
        end
    end

    message("Done")
end

local function make_suggestions()
    local inventory = Storage:new(true)

    local crystals = {}
    local equipment = {}

    for _, item in pairs(inventory:get_all_items()) do
        if item:is_crystal() then
            table.insert(crystals, item)
        elseif item:is_equpiment() then
            table.insert(equipment, item)
        end
    end

    if #crystals > 0 then
        message("Give Crystals / Crystal clusters to Ephemeral Moogle")
        for _, item in pairs(crystals) do
            message(string.format("  %2d %s in %s slot %d", item.count, item.name, inventory.inventory[item.bag_id].name,
                item.slot))
        end
    end

    if #equipment > 0 then
        message("Move equipment to Mog Wardrobe")
        for _, item in pairs(equipment) do
            message(string.format("   %s in %s slot %d", item.name, inventory.inventory[item.bag_id].name,
                item.slot))
        end
    end

    message("Done")
end

-- Looks through all inventories and prints all items that have a name similar to the given name. Case insensitive
---@param name string
local function find_items(name)
    local lower_name = name:lower()
    for _, bag in pairs(res_bags) do
        local items = windower.ffxi.get_items(bag.id)
        if not items then
            message("Skipping inaccessible bag: " .. bag.name)
        else
            for _, item in ipairs(items) do
                local res_item = res_items[item.id]
                if res_item ~= nil and res_item.name:lower():contains(lower_name) then
                    message(string.format("%s in %s slot: %d", res_item.name, bag.name, item.slot))
                end
            end
        end
    end
end

windower.register_event('addon command', function(cmd, ...)
    message(cmd)

    local args = T { ... }

    if cmd == 'items' then
        local dry_run = args:contains("--dry-run")
        local debug = args:contains("--debug")
        coroutine.schedule(function()
            stack_items(dry_run, debug)
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
                list_items(args[1], args[2])
            end, 0)
        end
    elseif cmd == "suggest" then
        coroutine.schedule(make_suggestions, 0)
    elseif cmd == "find" then
        if args[1] == nil then
            message("Need an item name")
            message("//inv find fire crystal")
        else
            coroutine.schedule(function()
                find_items(args:concat(" "))
            end, 0)
        end
    end
end)
