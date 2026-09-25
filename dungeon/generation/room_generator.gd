class_name RoomGenerator extends RefCounted
## Decides how many rooms to place and where

const MAX_PLACEMENT_ATTEMPTS: int = 10


## Falls back to one big room if any sector couldn't fit one
static func generate(ctx: GenerationContext) -> void:
    # Resolved once so every call below agrees
    var orientation: SectorLayout.Orientation = SectorLayout.resolve_orientation(
        ctx.config.orientation, ctx.rng
    )

    var target_count: int = ctx.rng.randi_range(
        ctx.config.room_count_min, ctx.config.room_count_max
    )
    var sectors: Vector2i = SectorLayout.sector_grid_size(target_count, orientation)
    var valid_sectors: Array[Vector2i] = SectorLayout.valid_sectors(target_count, orientation)

    for sector: Vector2i in valid_sectors:
        for _attempt: int in range(MAX_PLACEMENT_ATTEMPTS):
            var rect: Rect2i = RoomShapes.generate(sectors.x, sectors.y, sector, ctx)
            if not _respects_gap(ctx.rooms, rect):
                continue
            RoomCarver.carve_room(ctx.grid, ctx.make_room(rect))
            break

    if ctx.rooms.size() < valid_sectors.size():
        _generate_fallback_room(ctx)
    else:
        RoomCombiner.combine_rooms(ctx)


# One room filling the whole interior
static func _generate_fallback_room(ctx: GenerationContext) -> void:
    ctx.grid.reset()
    ctx.reset_rooms()

    RoomCarver.carve_room(ctx.grid, ctx.make_room(ctx.grid.get_interior()))


static func _respects_gap(rooms: Array[DungeonRoom], rect: Rect2i) -> bool:
    for room: DungeonRoom in rooms:
        if room.area.grow(RoomShapes.ROOM_GAP).intersects(rect):
            return false
    return true
