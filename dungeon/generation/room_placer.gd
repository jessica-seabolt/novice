class_name RoomPlacer extends RefCounted
## Places rooms in the floor grid

const MAX_PLACEMENT_ATTEMPTS: int = 10


static func place(ctx: GenerationContext) -> void:
    # Determine how many rooms to place and how to divide the dungeon into sectors
    var target_count: int = ctx.rng.randi_range(
        ctx.config.room_count_min, ctx.config.room_count_max
    )
    var sectors: Vector2i = RoomShapes.sector_grid_size(target_count)

    # Assign rooms to sectors and place them
    for i: int in range(target_count):
        var sector: Vector2i = Vector2i(i % sectors.x, floori(float(i) / float(sectors.x)))

        for _attempt: int in range(MAX_PLACEMENT_ATTEMPTS):
            var rect: Rect2i = RoomShapes.generate(sectors.x, sectors.y, sector, ctx)
            if not _respects_gap(ctx.rooms, rect):
                continue
            _stamp(ctx.grid, ctx.make_room(rect))
            break


static func _respects_gap(rooms: Array[DungeonRoom], rect: Rect2i) -> bool:
    for room: DungeonRoom in rooms:
        if room.area.grow(RoomShapes.ROOM_GAP).intersects(rect):
            return false
    return true


static func _stamp(grid: FloorGrid, room: DungeonRoom) -> void:
    for y: int in range(room.area.position.y, room.area.end.y):
        for x: int in range(room.area.position.x, room.area.end.x):
            var p: Vector2i = Vector2i(x, y)
            grid.get_tile(p).room_id = room.id
            grid.set_tile_type(p, DungeonTile.TileType.GROUND)
