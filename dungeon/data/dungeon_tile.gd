class_name DungeonTile extends RefCounted
## Represents a single tile in the dungeon, with a type, a room id, and a feature like stairs
## Room id of -1 means it is not part of a DungeonRoom

enum TileType {
    WALL,
    GROUND,
    SPECIAL_TERRAIN,
}

enum Feature {
    NONE,
    STAIRS,
}

var tile_type: DungeonTile.TileType = DungeonTile.TileType.WALL
var room_id: int = -1
var feature: DungeonTile.Feature = DungeonTile.Feature.NONE


func reset() -> void:
    tile_type = DungeonTile.TileType.WALL
    room_id = -1
    feature = DungeonTile.Feature.NONE
