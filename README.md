# Stackconsolidator

FFXI addon to help manage your inventory and bags.

# Installation

Copy the `stackconsolidator` folder into your window addons folder.
Then run ```//lua load stackconsolidator``` when in the game.

This addon is built for the English version, let me know if you are interested in other languages and I'll look into adding support.

# Commands

## stack

Organizes your available bags by moving items around so that items are as stacked as possible.
This command is area sensitive. So if you are in your mog house, it will consider all bags available - mog safe, locker, etc.

If you are not in your mog house, it will only consider 
* Inventory
* Satchel
* Sack
* Case

NOTE: If you are in an area with moogles like Mhaura, that is NOT considered to be in a mog house. So you don't have access to your safe, etc.

Wardrobes are currently ignored.

### Examples

See what would be moved.

```
//inv stack --dry-run
```


Actually move things.
```
//inv stack
```

Print more details about what's going on
```
//inv stack --debug
```


### Details

This command will move lower stacked items to higher stacked. So if you have 8 moat carps in your Safe and 3 in your locker, it will move from locker to safe.

This command tries to be "realistic" so there is a second delay between each item move and sorting of the inventory, mimicking a human being's speed. This means it can be a bit slow for large amounts of items.

Further, if it moves an item from Sack to Locker, it will first move it to the inventory. 
The command attempts to be "smart" by temporarily moving items. To see this, add --debug. 

For example:

Safe 80 slots
 * 5 Moat Carp

Locker 80 slots
 * 2 Moat Carp

 Inventory 80 slots
  * No Moat Carp

Sack 79 slots

1. Temporarily move a random item from Inventory to Sack to create space
2. Move 2 Moat Carp from Locker to Inventory
3. Temporarily move a random item from Inventory to Locker to create space
4. Move a random item from Safe to Inventory
5. Move 2 Moat carp from Inventory to Safe
-- Unwind temporary moves
6. Move random item from Locker back to Inventory
7. Move random item back from Sack to Inventory


NOTE: temporarily moving items is not perfect. It depends on knowing what item is movable. This can be a little tricky.
All furniture inside the safes are ignored because its hard to tell if its used in your house or not. 
Linkshells are ignored if they are currently equipped.
Weapons/Armor are ignored if they are equipped.

## list

Lists various items by category or type.

### Examples


List all items that are at max stack, ignoring stacks of 1.

```
//inv list stacks
```

List all scrolls

```
//inv list Scroll
```

List all scrolls learnable by a White Mage

```
//inv list Scroll whm
```

## suggest

Makes suggestions on how to save space. 

Right now it suggests moving Crystals to Ephemeral moogles and equipment to wardrobes. 
The offending items are listed.

### Examples

See what would be moved.

```
//inv suggest
```

## find

Finds items matching a name and lists where they are.

```
//inv find fire crystal
```
