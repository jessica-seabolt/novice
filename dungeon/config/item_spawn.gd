class_name ItemSpawn extends Resource
## An item a dungeon can drop, and how often compared to the others

@export var item: ItemData
@export_range(1, 1000) var weight: int = 1
## How many lie in one pile, up to the item's stack limit
@export_range(1, 99) var count_min: int = 1
@export_range(1, 99) var count_max: int = 1
