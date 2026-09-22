class_name GenerationContext extends RefCounted
## Holds state information for dungeon generation

var grid: FloorGrid
var config: DungeonConfig
var rng: RandomNumberGenerator
var rooms: Array[DungeonRoom]
var astar: AStarGrid2D

var _next_room_id: int


func _init(floor_grid: FloorGrid, floor_config: DungeonConfig) -> void:
    grid = floor_grid
    config = floor_config
    rng = RandomNumberGenerator.new()
    rng.randomize()


func make_room(area: Rect2i) -> DungeonRoom:
    var room: DungeonRoom = DungeonRoom.new(_next_room_id, area)
    rooms.append(room)
    _next_room_id += 1
    return room


## Clears any rooms placed so far
func reset_rooms() -> void:
    rooms.clear()
    _next_room_id = 0
