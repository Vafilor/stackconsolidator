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
