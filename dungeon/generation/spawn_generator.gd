class_name SpawnGenerator extends RefCounted
## Decides where things start on a floor


const NO_TILE: Vector2i = Vector2i(-1, -1)


## Places the player and the stairs, each on a reachable tile in a random room
static func generate(ctx: GenerationContext) -> void:
    ctx.player_spawn = _random_room_tile(ctx, [])
    var stairs: Vector2i = _random_room_tile(ctx, [ctx.player_spawn])
    if stairs == NO_TILE:
        push_error("SpawnGenerator found no free tile for the stairs")
        return
    ctx.grid.get_tile(stairs).feature = DungeonTile.Feature.STAIRS


# A random reachable tile in a random room, skipping taken tiles
# Rooms with nothing free are passed over, trying the rest in order from a random start
static func _random_room_tile(ctx: GenerationContext, taken: Array[Vector2i]) -> Vector2i:
    var start: int = ctx.rng.randi_range(0, ctx.rooms.size() - 1)
    for i: int in range(ctx.rooms.size()):
        var room: DungeonRoom = ctx.rooms[(start + i) % ctx.rooms.size()]
        var tiles: Array[Vector2i] = []
        for p: Vector2i in ctx.reachable_tiles:
            if ctx.grid.get_tile(p).room_id == room.id and p not in taken:
                tiles.append(p)
        if not tiles.is_empty():
            return tiles[ctx.rng.randi_range(0, tiles.size() - 1)]
    return NO_TILE
