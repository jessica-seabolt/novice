class_name MobSpawn extends Resource
## A mob a dungeon can spawn, and how often compared to the others

@export var mob: MobData
@export_range(1, 1000) var weight: int = 1
