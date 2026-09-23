class_name RoomCarver extends RefCounted
## Carves rooms into the floor as ground


## Writes a room's area into the grid as ground, tagged with its id
static func carve_room(grid: FloorGrid, room: DungeonRoom) -> void:
    for y: int in range(room.area.position.y, room.area.end.y):
        for x: int in range(room.area.position.x, room.area.end.x):
            var p: Vector2i = Vector2i(x, y)
            grid.get_tile(p).room_id = room.id
            grid.set_tile_type(p, DungeonTile.TileType.GROUND)
