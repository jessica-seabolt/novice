class_name DungeonConfig extends Resource
## Holds configuration for dungeon generation, including room sizes, counts, and layout

## Portion of FloorGrid's max width/height to actually use for this floor
## 1.0 means use the full grid, 0.5 means use half the grid, etc.
@export_range(0.0, 1.0, 0.01) var grid_usage: float = 1.0

## Min and max number of rooms to try placing on this floor
@export_range(1, 30) var room_count_min: int = 1
@export_range(1, 30) var room_count_max: int = 10

## How this dungeon's sectors should be laid out; see SectorLayout for details
@export var orientation: SectorLayout.Orientation = SectorLayout.Orientation.STANDARD

## Min and max room width/height in tiles
@export_range(3, 54) var room_width_min: int = 4
@export_range(3, 54) var room_width_max: int = 12
@export_range(3, 54) var room_height_min: int = 5
@export_range(3, 54) var room_height_max: int = 12

## Chance that neighbouring rooms merge together
@export_range(0.0, 1.0, 0.01) var room_combination_chance: float = 0.1

## Min and max number of lakes to try generating on this floor
@export_range(0, 10) var lake_count_min: int = 0
@export_range(0, 10) var lake_count_max: int = 0

## Min and max number of rivers to try generating on this floor
@export_range(0, 10) var river_count_min: int = 0
@export_range(0, 10) var river_count_max: int = 0
