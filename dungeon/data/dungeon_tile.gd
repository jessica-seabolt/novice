class_name DungeonTile extends RefCounted
## Represents a single tile in the dungeon, with a type and a room id
## Room id of -1 means it is not part of a DungeonRoom

enum TileType {
    WALL,
    GROUND,
    SPECIAL_TERRAIN,
}

var tile_type: TileType = TileType.WALL
var room_id: int = -1
var is_stairs: bool = false


func reset() -> void:
    tile_type = TileType.WALL
    room_id = -1
    is_stairs = false
