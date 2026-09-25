class_name SpawnGenerator extends RefCounted
## Decides where things start on a floor

const NO_TILE: Vector2i = Vector2i(-1, -1)


## Places the player, the stairs and the mobs, each on a reachable tile in a random room
## Stairs never go in a doorway
static func generate(ctx: GenerationContext) -> void:
    ctx.player_spawn = _random_room_tile(ctx, [])

    var excluded: Array[Vector2i] = _doorways(ctx)
    excluded.append(ctx.player_spawn)
    var stairs: Vector2i = _random_room_tile(ctx, excluded)
    if stairs == NO_TILE:
        push_error("SpawnGenerator found no free tile for the stairs")
        return
    ctx.grid.get_tile(stairs).feature = DungeonTile.Feature.STAIRS

    var mob_count: int = ctx.rng.randi_range(ctx.config.mob_count_min, ctx.config.mob_count_max)

    # Mobs may start on the stairs or in doorways, just never on the player or each other
    var taken: Array[Vector2i] = [ctx.player_spawn]
    for _i: int in range(mob_count):
        var spawn_tile: Vector2i = _random_room_tile(ctx, taken)
        if spawn_tile == NO_TILE:
            break

        ctx.mob_spawns.append(spawn_tile)
        taken.append(spawn_tile)


# A random reachable tile in a random room, skipping excluded tiles
static func _random_room_tile(ctx: GenerationContext, excluded: Array[Vector2i]) -> Vector2i:
    var start: int = ctx.rng.randi_range(0, ctx.rooms.size() - 1)
    for i: int in range(ctx.rooms.size()):
        var room: DungeonRoom = ctx.rooms[(start + i) % ctx.rooms.size()]
        var tiles: Array[Vector2i] = []
        for p: Vector2i in ctx.reachable_tiles:
            if ctx.grid.get_tile(p).room_id == room.id and p not in excluded:
                tiles.append(p)
        if not tiles.is_empty():
            return tiles[ctx.rng.randi_range(0, tiles.size() - 1)]
    return NO_TILE


static func _doorways(ctx: GenerationContext) -> Array[Vector2i]:
    var doorways: Array[Vector2i] = []
    for p: Vector2i in ctx.reachable_tiles:
        if ctx.grid.is_doorway(p):
            doorways.append(p)
    return doorways
