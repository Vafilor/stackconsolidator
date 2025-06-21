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
    [id.INVENTORY] = { id = id.INVENTORY, name = 'inventory' },
    [id.SAFE] = { id = id.SAFE, name = 'safe' },
    [id.STORAGE] = { id = id.STORAGE, name = 'storage' },
    [id.LOCKER] = { id = id.LOCKER, name = 'locker' },
    [id.SATCHEL] = { id = id.SATCHEL, name = 'satchel' },
    [id.SACK] = { id = id.SACK, name = 'sack' },
    [id.CASE] = { id = id.CASE, name = 'case' },
    [id.SAFE_2] = { id = id.SAFE_2, name = 'safe2' }
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
