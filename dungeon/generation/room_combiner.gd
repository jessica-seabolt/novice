class_name RoomCombiner extends RefCounted
## Merges rooms with their closest neighbour, based on the config's combination chance


## Rolls each room's chance to swallow its closest neighbour into one bigger room
static func combine_rooms(ctx: GenerationContext) -> void:
    for room: DungeonRoom in ctx.rooms.duplicate():
        if not ctx.rooms.has(room) or room.has_merged:
            continue
        if ctx.rng.randf() >= ctx.config.room_combination_chance:
            continue

        var neighbour: DungeonRoom = _closest_room(ctx.rooms, room)
        if neighbour != null:
            _try_combine(ctx, room, neighbour)


# The nearest other unmerged room to "from", or null if there isn't one
static func _closest_room(rooms: Array[DungeonRoom], from: DungeonRoom) -> DungeonRoom:
    var closest: DungeonRoom = null
    var closest_distance: int = -1

    for room: DungeonRoom in rooms:
        if room == from or room.has_merged:
            continue
        var distance: int = _room_distance(from, room)
        if closest_distance == -1 or distance < closest_distance:
            closest_distance = distance
            closest = room

    return closest


static func _room_distance(a: DungeonRoom, b: DungeonRoom) -> int:
    var a_center: Vector2i = a.get_center()
    var b_center: Vector2i = b.get_center()
    return absi(a_center.x - b_center.x) + absi(a_center.y - b_center.y)


# Swallows "neighbour" into "first" unless it would touch a third room
static func _try_combine(
    ctx: GenerationContext, first: DungeonRoom, neighbour: DungeonRoom
) -> void:
    var merged_area: Rect2i = first.area.merge(neighbour.area)

    for room: DungeonRoom in ctx.rooms:
        if room == first or room == neighbour:
            continue
        if room.area.grow(RoomShapes.ROOM_GAP).intersects(merged_area):
            return

    first.area = merged_area
    first.has_merged = true
    ctx.rooms.erase(neighbour)
    RoomCarver.carve_room(ctx.grid, first)
