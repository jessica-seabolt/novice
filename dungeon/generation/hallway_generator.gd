class_name HallwayGenerator extends RefCounted
## Decides which rooms get linked by hallways

enum Style {
    DIRECT, ## The shortest set of hallways that still links every room
    SNAKE, ## Like DIRECT, but each hallway winds through random waypoints
    CHAIN, ## A nearest-neighbour path linking every room in sequence
    CIRCUIT, ## Like CHAIN, but the last room links back to the first
    WEB, ## Every room links to the room nearest the grid's center
    BORDER, ## Every room links to a ring just inside the border
    RANDOM, ## Resolves to one of the other styles at random
}

const RANDOMIZABLE_STYLES: Array[HallwayGenerator.Style] = [
    HallwayGenerator.Style.DIRECT,
    HallwayGenerator.Style.SNAKE,
    HallwayGenerator.Style.CHAIN,
    HallwayGenerator.Style.CIRCUIT,
    HallwayGenerator.Style.WEB,
    HallwayGenerator.Style.BORDER,
]

## Closest unlinked pairs an extra loop picks from
const LOOP_CANDIDATES: int = 3
## Tries to place a dead end before giving up
const DEAD_END_ATTEMPTS: int = 20


## Links every room using the config's hallway style
static func generate(ctx: GenerationContext) -> void:
    if ctx.rooms.size() <= 1:
        return

    HallwayCarver.build_astar(ctx)

    # Each style picks the pairs, then they're all carved
    var style: HallwayGenerator.Style = resolve_style(ctx.config.hallway_style, ctx.rng)
    var pairs: Array[Vector2i] = []
    match style:
        HallwayGenerator.Style.DIRECT, HallwayGenerator.Style.SNAKE:
            pairs = _spanning_tree_pairs(ctx.rooms)
        HallwayGenerator.Style.CHAIN:
            pairs = _chain_pairs(ctx)
        HallwayGenerator.Style.CIRCUIT:
            pairs = _circuit_pairs(ctx)
        HallwayGenerator.Style.WEB:
            pairs = _web_pairs(ctx)
        HallwayGenerator.Style.BORDER:
            pairs = _border(ctx)
        _: # Should never occur
            push_error("Invalid hallway style passed to HallwayGenerator")

    for pair: Vector2i in pairs:
        _carve_pair(ctx, pair, style)

    _add_extras(ctx, pairs, style)


## Resolves RANDOM into a concrete style
static func resolve_style(
    style: HallwayGenerator.Style, rng: RandomNumberGenerator
) -> HallwayGenerator.Style:
    if style != HallwayGenerator.Style.RANDOM:
        return style
    var index: int = rng.randi_range(0, RANDOMIZABLE_STYLES.size() - 1)
    return RANDOMIZABLE_STYLES[index]


# Minimum spanning tree over room distances
static func _spanning_tree_pairs(rooms: Array[DungeonRoom]) -> Array[Vector2i]:
    var groups: Array[int] = []
    for i: int in range(rooms.size()):
        groups.append(i)

    var pairs: Array[Vector2i] = []

    for pair: Vector2i in _pairs_by_distance(rooms):
        # A tree of n rooms has n - 1 links
        if pairs.size() == rooms.size() - 1:
            break

        var group_a: int = groups[pair.x]
        var group_b: int = groups[pair.y]
        if group_a == group_b:
            continue

        pairs.append(pair)
        _merge_groups(groups, group_a, group_b)

    return pairs


static func _chain_pairs(ctx: GenerationContext) -> Array[Vector2i]:
    return _pairs_in_order(_nearest_neighbour_random_start(ctx))


static func _circuit_pairs(ctx: GenerationContext) -> Array[Vector2i]:
    var order: Array[int] = _nearest_neighbour_random_start(ctx)
    var pairs: Array[Vector2i] = _pairs_in_order(order)

    # Two rooms are already a circuit
    if order.size() > 2:
        pairs.append(_pair(order[order.size() - 1], order[0]))

    return pairs


static func _web_pairs(ctx: GenerationContext) -> Array[Vector2i]:
    var hub: int = _centermost_room(ctx)
    var pairs: Array[Vector2i] = []

    for i: int in range(ctx.rooms.size()):
        if i == hub:
            continue
        pairs.append(_pair(i, hub))

    return pairs


# Carves the ring itself; falls back to web pairs if it can't
static func _border(ctx: GenerationContext) -> Array[Vector2i]:
    var ring: Array[Vector2i] = HallwayCarver.carve_ring(ctx)
    if ring.is_empty():
        return _web_pairs(ctx)

    for room: DungeonRoom in ctx.rooms:
        HallwayCarver.carve_to_ring(ctx, room, ring)

    var no_pairs: Array[Vector2i] = []
    return no_pairs


static func _carve_pair(
    ctx: GenerationContext, pair: Vector2i, style: HallwayGenerator.Style
) -> void:
    var room_a: DungeonRoom = ctx.rooms[pair.x]
    var room_b: DungeonRoom = ctx.rooms[pair.y]
    if style == HallwayGenerator.Style.SNAKE:
        HallwayCarver.carve_snake_between(ctx, room_a, room_b)
    else:
        HallwayCarver.carve_between(ctx, room_a, room_b)


# Extra loops and dead ends beyond the style's own
static func _add_extras(
    ctx: GenerationContext, pairs: Array[Vector2i], style: HallwayGenerator.Style
) -> void:
    var count: int = ctx.rng.randi_range(
        ctx.config.extra_hallway_count_min, ctx.config.extra_hallway_count_max
    )
    var by_distance: Array[Vector2i] = _pairs_by_distance(ctx.rooms)
    var hallway_tiles: Array[Vector2i] = _hallway_tiles(ctx.grid)

    for _extra: int in range(count):
        if ctx.rng.randf() < ctx.config.dead_end_chance:
            _add_dead_end(ctx, hallway_tiles)
            continue

        # The closest few pairs that aren't linked yet
        var candidates: Array[Vector2i] = []
        for pair: Vector2i in by_distance:
            if candidates.size() == LOOP_CANDIDATES:
                break
            if pair not in pairs:
                candidates.append(pair)

        # Every pair is already linked
        if candidates.is_empty():
            return

        var pair: Vector2i = candidates[ctx.rng.randi_range(0, candidates.size() - 1)]
        _carve_pair(ctx, pair, style)
        pairs.append(pair)


static func _add_dead_end(ctx: GenerationContext, hallway_tiles: Array[Vector2i]) -> void:
    if hallway_tiles.is_empty():
        return

    for _attempt: int in range(DEAD_END_ATTEMPTS):
        var p: Vector2i = hallway_tiles[ctx.rng.randi_range(0, hallway_tiles.size() - 1)]

        if HallwayCarver.carve_dead_end(ctx, p):
            return


static func _hallway_tiles(grid: FloorGrid) -> Array[Vector2i]:
    var tiles: Array[Vector2i] = []

    for y: int in range(grid.height):
        for x: int in range(grid.width):
            var p: Vector2i = Vector2i(x, y)
            if grid.is_hallway(p):
                tiles.append(p)

    return tiles


# Smaller index first, so each pair has one form
static func _pair(a: int, b: int) -> Vector2i:
    return Vector2i(mini(a, b), maxi(a, b))


# Every pair of rooms once, closest first
static func _pairs_by_distance(rooms: Array[DungeonRoom]) -> Array[Vector2i]:
    var pairs: Array[Vector2i] = []

    for i: int in range(rooms.size()):
        for j: int in range(i + 1, rooms.size()):
            pairs.append(Vector2i(i, j))

    pairs.sort_custom(func(p: Vector2i, q: Vector2i) -> bool:
        return _distance(rooms, p.x, p.y) < _distance(rooms, q.x, q.y)
    )

    return pairs


static func _merge_groups(groups: Array[int], keep: int, replace: int) -> void:
    for i: int in range(groups.size()):
        if groups[i] == replace:
            groups[i] = keep


static func _pairs_in_order(order: Array[int]) -> Array[Vector2i]:
    var pairs: Array[Vector2i] = []
    for i: int in range(order.size() - 1):
        pairs.append(_pair(order[i], order[i + 1]))
    return pairs


static func _nearest_neighbour_random_start(ctx: GenerationContext) -> Array[int]:
    var start: int = ctx.rng.randi_range(0, ctx.rooms.size() - 1)
    return _nearest_neighbour_order(ctx.rooms, start)


static func _nearest_neighbour_order(rooms: Array[DungeonRoom], start: int) -> Array[int]:
    var visited: Array[bool] = []
    visited.resize(rooms.size())
    visited.fill(false)

    var order: Array[int] = []
    var current: int = start
    visited[current] = true
    order.append(current)

    for _step: int in range(rooms.size() - 1):
        var nearest: int = _nearest_unvisited(rooms, visited, current)
        visited[nearest] = true
        order.append(nearest)
        current = nearest

    return order


static func _nearest_unvisited(rooms: Array[DungeonRoom], visited: Array[bool], from: int) -> int:
    var best: int = -1
    var best_distance: int = -1

    for i: int in range(rooms.size()):
        if visited[i]:
            continue
        var distance: int = _distance(rooms, from, i)
        if best_distance == -1 or distance < best_distance:
            best_distance = distance
            best = i

    return best


static func _centermost_room(ctx: GenerationContext) -> int:
    var center: Vector2i = Vector2i(floori(ctx.grid.width / 2.0), floori(ctx.grid.height / 2.0))
    var best: int = -1
    var best_distance: int = -1

    for i: int in range(ctx.rooms.size()):
        var distance: int = _manhattan(ctx.rooms[i].get_center(), center)
        if best_distance == -1 or distance < best_distance:
            best_distance = distance
            best = i

    return best


static func _distance(rooms: Array[DungeonRoom], a_idx: int, b_idx: int) -> int:
    return _manhattan(rooms[a_idx].get_center(), rooms[b_idx].get_center())


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)
