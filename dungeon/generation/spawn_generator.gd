class_name SpawnGenerator extends RefCounted
## Decides where things start on a floor

const NO_TILE: Vector2i = Vector2i(-1, -1)


## The player, stairs and mobs go on reachable room tiles; stairs never go in a doorway
static func generate(ctx: GenerationContext) -> void:
    ctx.player_spawn = _random_room_tile(ctx, ctx.reachable_tiles, [])

    var excluded: Array[Vector2i] = _doorways(ctx)
    excluded.append(ctx.player_spawn)
    var stairs: Vector2i = _random_room_tile(ctx, ctx.reachable_tiles, excluded)
    if stairs == NO_TILE:
        push_error("SpawnGenerator found no free tile for the stairs")
        return
    ctx.grid.get_tile(stairs).feature = DungeonTile.Feature.STAIRS

    # Mobs may start on stairs or in doorways
    ctx.mob_spawns = _pick_spawns(
        ctx,
        ctx.config.mob_count_min,
        ctx.config.mob_count_max,
        ctx.reachable_tiles,
        ctx.player_spawn
    )

    # Items may spawn on any room tile that isn't taken by stairs
    ctx.item_spawns = _pick_spawns(
        ctx, ctx.config.item_count_min, ctx.config.item_count_max, _room_tiles(ctx), stairs
    )


# Between min and max tiles, never on excluded or each other; fewer if the rooms run out
static func _pick_spawns(
    ctx: GenerationContext,
    count_min: int,
    count_max: int,
    candidates: Array[Vector2i],
    excluded: Vector2i
) -> Array[Vector2i]:
    var spawns: Array[Vector2i] = []
    var taken: Array[Vector2i] = [excluded]
    for _i: int in range(ctx.rng.randi_range(count_min, count_max)):
        var tile: Vector2i = _random_room_tile(ctx, candidates, taken)
        if tile == NO_TILE:
            break
        spawns.append(tile)
        taken.append(tile)
    return spawns


# A random room first, so big rooms don't get everything; NO_TILE if no room has a free tile
static func _random_room_tile(
    ctx: GenerationContext, candidates: Array[Vector2i], excluded: Array[Vector2i]
) -> Vector2i:
    var start: int = ctx.rng.randi_range(0, ctx.rooms.size() - 1)
    for i: int in range(ctx.rooms.size()):
        var room: DungeonRoom = ctx.rooms[(start + i) % ctx.rooms.size()]
        var tiles: Array[Vector2i] = []
        for p: Vector2i in candidates:
            if ctx.grid.get_tile(p).room_id == room.id and p not in excluded:
                tiles.append(p)
        if not tiles.is_empty():
            return tiles[ctx.rng.randi_range(0, tiles.size() - 1)]
    return NO_TILE


# Every room floor tile, whether or not it can be walked to
static func _room_tiles(ctx: GenerationContext) -> Array[Vector2i]:
    var tiles: Array[Vector2i] = []
    for room: DungeonRoom in ctx.rooms:
        for y: int in range(room.area.position.y, room.area.end.y):
            for x: int in range(room.area.position.x, room.area.end.x):
                var p: Vector2i = Vector2i(x, y)
                if ctx.grid.get_tile(p).room_id == room.id and ctx.grid.is_ground(p):
                    tiles.append(p)
    return tiles


static func _doorways(ctx: GenerationContext) -> Array[Vector2i]:
    var doorways: Array[Vector2i] = []
    for p: Vector2i in ctx.reachable_tiles:
        if ctx.grid.is_doorway(p):
            doorways.append(p)
    return doorways
