class_name DungeonTile extends RefCounted

enum TileType {
    WALL,
    GROUND,
    SPECIAL_TERRAIN
}

var tile_type: TileType = TileType.WALL
var room_id: int = -1
var is_stairs: bool = false
