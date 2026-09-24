class_name SpawnGenerator extends RefCounted
## Decides where things start on a floor


## Picks a random room, then a random reachable tile in it
static func generate(ctx: GenerationContext) -> void:
    var room: DungeonRoom = ctx.rooms[ctx.rng.randi_range(0, ctx.rooms.size() - 1)]

    var tiles: Array[Vector2i] = []
    for p: Vector2i in ctx.reachable_tiles:
        if ctx.grid.get_tile(p).room_id == room.id:
            tiles.append(p)

    ctx.player_spawn = tiles[ctx.rng.randi_range(0, tiles.size() - 1)]
