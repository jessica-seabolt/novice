class_name GenerationContext extends RefCounted
## Holds state information for dungeon generation

var grid: FloorGrid
var config: DungeonConfig
var rng: RandomNumberGenerator
var rooms: Array[DungeonRoom]
var astar: AStarGrid2D

var _next_room_id: int


func make_room(area: Rect2i) -> DungeonRoom:
    var room: DungeonRoom = DungeonRoom.new(_next_room_id, area)
    rooms.append(room)
    _next_room_id += 1
    return room


func _init(floor_grid: FloorGrid, floor_config: DungeonConfig) -> void:
    grid = floor_grid
    config = floor_config
    rng = RandomNumberGenerator.new()
    rng.randomize()
