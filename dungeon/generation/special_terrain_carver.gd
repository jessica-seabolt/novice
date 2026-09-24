class_name SpecialTerrainCarver extends RefCounted
## Carves lakes and rivers into the floor as SPECIAL_TERRAIN

## A lake's starting spread chance
const LAKE_SPREAD_BASE: float = 0.93
## How much a lake's spread chance decreases with distance
const LAKE_SPREAD_FALLOFF: float = 0.06
## The maximum radius a lake can grow to
const LAKE_RADIUS_MAX: int = 15

## Minimum and maximum straight segment lengths for river generation
const RIVER_STRAIGHT_MIN: int = 1
const RIVER_STRAIGHT_MAX: int = 10

## How close to a side wall a river steers away, and how far off-center before it steers back
const RIVER_EDGE_MARGIN: int = 5
const RIVER_CENTER_BIAS: int = 3

## Direction weights when a river turns; in every case vertical + left + right must sum to 1.0
const RIVER_WEIGHT_VERTICAL: float = 0.4
const RIVER_WEIGHT_SIDE: float = 0.3
const RIVER_WEIGHT_TOWARD_WALL: float = 0.1
const RIVER_WEIGHT_AWAY_FROM_WALL: float = 0.5
const RIVER_WEIGHT_TOWARD_CENTER: float = 0.35
const RIVER_WEIGHT_AWAY_FROM_CENTER: float = 0.25


## Grows a lake outward from start, painting only wall tiles
## Spread chance shrinks with distance, so edges come out ragged rather than diamond-shaped
static func carve_lake(grid: FloorGrid, start: Vector2i, rng: RandomNumberGenerator) -> void:
    var radius: int = rng.randi_range(1, LAKE_RADIUS_MAX)
    var queue: Array[Vector2i] = [start]
    var distances: Array[int] = [0]
    var visited: Dictionary = {start: true}
    var head: int = 0

    while head < queue.size():
        var p: Vector2i = queue[head]
        var d: int = distances[head]
        head += 1

        if grid.is_wall(p):
            grid.set_tile_type(p, DungeonTile.TileType.SPECIAL_TERRAIN)

        if d >= radius:
            continue

        for direction: Vector2i in FloorGrid.CARDINALS:
            var neighbour: Vector2i = p + direction
            if grid.is_border(neighbour) or visited.has(neighbour):
                continue

            # A failed roll stays unvisited so another side can still reach it later
            if rng.randf() > LAKE_SPREAD_BASE - LAKE_SPREAD_FALLOFF * d:
                continue

            visited[neighbour] = true
            queue.append(neighbour)
            distances.append(d + 1)


## Carves a river into the grid as SPECIAL_TERRAIN
static func carve_river(
    grid: FloorGrid,
    start: Vector2i,
    heading: Vector2i,
    rng: RandomNumberGenerator
) -> void:
    _carve_river_tile(grid, start)

    var p: Vector2i = start
    var direction: Vector2i = heading
    var straight: int = 0
    var turn_after: int = rng.randi_range(RIVER_STRAIGHT_MIN, RIVER_STRAIGHT_MAX)

    for _step: int in range(grid.width * grid.height):
        if straight >= turn_after:
            direction = _pick_river_direction(grid, p, heading, rng)
            straight = 0
            turn_after = rng.randi_range(RIVER_STRAIGHT_MIN, RIVER_STRAIGHT_MAX)

        var next: Vector2i = p + direction

        if grid.is_border(next):
            # River is running vertically and hit the border, stop
            if direction == heading:
                return

            # River is running horizontally and hit the border, check if it can move vertically
            direction = heading
            straight = 0
            next = p + heading

            # River still hits border vertically, stop
            if grid.is_border(next):
                return

        _carve_river_tile(grid, next)
        p = next
        straight += 1


static func _carve_river_tile(grid: FloorGrid, p: Vector2i) -> void:
    # Hallways never get carved
    if grid.is_hallway(p):
        return

    grid.set_tile_type(p, DungeonTile.TileType.SPECIAL_TERRAIN)


# Sideways drift steers away from nearby walls and back toward center
static func _pick_river_direction(
    grid: FloorGrid, p: Vector2i, heading: Vector2i, rng: RandomNumberGenerator
) -> Vector2i:
    var border: int = FloorGrid.BORDER_SIZE
    var to_left: int = p.x - border
    var to_right: int = (grid.width - 1 - border) - p.x

    # Weights always sum to 1.0, so right gets whatever vertical and left leave over
    var left: float = RIVER_WEIGHT_SIDE
    if to_left < RIVER_EDGE_MARGIN:
        left = RIVER_WEIGHT_TOWARD_WALL
    elif to_right < RIVER_EDGE_MARGIN:
        left = RIVER_WEIGHT_AWAY_FROM_WALL
    elif to_left > to_right + RIVER_CENTER_BIAS:
        # More room on the left, so lean left to drift back toward center
        left = RIVER_WEIGHT_TOWARD_CENTER
    elif to_right > to_left + RIVER_CENTER_BIAS:
        left = RIVER_WEIGHT_AWAY_FROM_CENTER

    var roll: float = rng.randf()
    if roll < RIVER_WEIGHT_VERTICAL:
        return heading
    if roll < RIVER_WEIGHT_VERTICAL + left:
        return Vector2i.LEFT
    return Vector2i.RIGHT
