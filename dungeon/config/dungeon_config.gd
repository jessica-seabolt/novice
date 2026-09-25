class_name DungeonConfig extends Resource
## Settings for generating a dungeon's floors

enum StairDirection {
    UP, ## Dungeon uses regular floors
    DOWN, ## Dungeon uses basement floors
}

## Portion of FloorGrid's max size to use
@export_range(0.0, 1.0, 0.01) var grid_usage: float = 1.0

## Min and max rooms per floor
@export_range(1, 30) var room_count_min: int = 1
@export_range(1, 30) var room_count_max: int = 10

## How rooms are arranged across the floor
@export var orientation: SectorLayout.Orientation = SectorLayout.Orientation.STANDARD

## Min and max room width/height in tiles
@export_range(3, 54) var room_width_min: int = 4
@export_range(3, 54) var room_width_max: int = 12
@export_range(3, 54) var room_height_min: int = 5
@export_range(3, 54) var room_height_max: int = 12

## Chance that neighbouring rooms merge together
@export_range(0.0, 1.0, 0.01) var room_combination_chance: float = 0.1

## Style of hallways to generate
@export var hallway_style: HallwayGenerator.Style = HallwayGenerator.Style.DIRECT

## Min and max extra hallways beyond the style's own
@export_range(0, 30) var extra_hallway_count_min: int = 0
@export_range(0, 30) var extra_hallway_count_max: int = 0

## Chance an extra hallway leads to a dead end
@export_range(0.0, 1.0, 0.01) var dead_end_chance: float = 0.0

## Min and max lakes per floor
@export_range(0, 10) var lake_count_min: int = 0
@export_range(0, 10) var lake_count_max: int = 0

## Min and max rivers per floor
@export_range(0, 10) var river_count_min: int = 0
@export_range(0, 10) var river_count_max: int = 0

## Whether this dungeon's stairs lead up or down
@export var stair_direction: DungeonConfig.StairDirection = DungeonConfig.StairDirection.DOWN

## How many floors this dungeon has
@export_range(1, 99) var floor_count: int = 10

## Min and max mobs per floor
@export_range(0, 100) var mob_count_min: int = 0
@export_range(0, 100) var mob_count_max: int = 0
