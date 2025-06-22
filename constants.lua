local id = {
    INVENTORY = 0,
    SAFE = 1,
    STORAGE = 2,
    LOCKER = 4,
    SATCHEL = 5,
    SACK = 6,
    CASE = 7,
    SAFE_2 = 9
}

local inventories = {
    [id.INVENTORY] = { id = id.INVENTORY, name = 'inventory', mog_house_only = false },
    [id.SAFE] = { id = id.SAFE, name = 'safe', mog_house_only = true },
    [id.STORAGE] = { id = id.STORAGE, name = 'storage', mog_house_only = true },
    [id.LOCKER] = { id = id.LOCKER, name = 'locker', mog_house_only = true },
    [id.SATCHEL] = { id = id.SATCHEL, name = 'satchel', mog_house_only = false },
    [id.SACK] = { id = id.SACK, name = 'sack', mog_house_only = false },
    [id.CASE] = { id = id.CASE, name = 'case', mog_house_only = false },
    [id.SAFE_2] = { id = id.SAFE_2, name = 'safe2', mog_house_only = true }
}

local equipment = {
    -- Arranged from equipment menu, starting top left
    slot_names = {
        "main", "sub", "range", "ammo",
        "head", "neck", "left_ear", "right_ear",
        "body", "hands", "left_ring", "right_ring",
        "back", "waist", "legs", "feet"
    }
}

local constants = {
    id = id,
    inventories = inventories,
    equipment = equipment
}

return constants
