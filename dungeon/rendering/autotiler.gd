class_name Autotiler extends RefCounted
## Picks tiles from the TileSet's terrain peering bits
## A set side must be that terrain; an empty side must be anything but the tile's own
## Each neighbourhood is scored once and cached

const TERRAIN_SET: int = 0
const REWARD: int = 3
const PENALTY: int = -10
# Rule for a side that must be anything but the tile's own terrain
const NOT_OWN: int = -1
const NEIGHBOURS: Array[TileSet.CellNeighbor] = [
    TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
    TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
    TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
    TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
    TileSet.CELL_NEIGHBOR_LEFT_SIDE,
    TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
    TileSet.CELL_NEIGHBOR_TOP_SIDE,
    TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
]
# Cell offsets for NEIGHBOURS, in the same order
const OFFSETS: Array[Vector2i] = [
    Vector2i(1, 0),
    Vector2i(1, 1),
    Vector2i(0, 1),
    Vector2i(-1, 1),
    Vector2i(-1, 0),
    Vector2i(-1, -1),
    Vector2i(0, -1),
    Vector2i(1, -1),
]
const SIDES: Array[TileSet.CellNeighbor] = [
    TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
    TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
    TileSet.CELL_NEIGHBOR_LEFT_SIDE,
    TileSet.CELL_NEIGHBOR_TOP_SIDE,
]
# Each corner with the two sides it sits between
const CORNER_SIDES: Dictionary = {
    TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER: [
        TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
    ],
    TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER: [
        TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE,
    ],
    TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER: [
        TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE,
    ],
    TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER: [
        TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
    ],
}


## "terrains" holds one terrain index per cell of the rect, row by row
## Neighbours outside the rect count as outside
static func paint(
    layer: TileMapLayer,
    terrains: PackedInt32Array,
    origin: Vector2i,
    size: Vector2i,
    outside: int
) -> void:
    var candidates: Array = _candidates_by_terrain(layer.tile_set)
    var best_by_pattern: Dictionary = {}
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()

    for y: int in range(size.y):
        for x: int in range(size.x):
            var own: int = terrains[y * size.x + x]
            var around: PackedInt32Array = _neighbour_terrains(terrains, size, x, y, outside)

            var key: int = own
            for t: int in around:
                key = key * 8 + t + 1

            if not best_by_pattern.has(key):
                best_by_pattern[key] = _best_candidates(candidates[own], own, around)

            var cell: Vector2i = origin + Vector2i(x, y)
            var choice: Array = _pick(best_by_pattern[key], cell, rng)
            if not choice.is_empty():
                layer.set_cell(cell, choice[0], choice[1], choice[2])


# Every terrain tile as [source_id, coord, alt_id, rules, probability], grouped by terrain
static func _candidates_by_terrain(ts: TileSet) -> Array:
    var tiles: Array = []
    var shaped: Dictionary = {}
    for s: int in range(ts.get_source_count()):
        var source_id: int = ts.get_source_id(s)
        var source: TileSetAtlasSource = ts.get_source(source_id) as TileSetAtlasSource
        if source == null:
            continue
        for t: int in range(source.get_tiles_count()):
            var coord: Vector2i = source.get_tile_id(t)
            for a: int in range(source.get_alternative_tiles_count(coord)):
                var alt_id: int = source.get_alternative_tile_id(coord, a)
                var td: TileData = source.get_tile_data(coord, alt_id)
                if td.terrain_set != TERRAIN_SET or td.terrain < 0:
                    continue
                tiles.append([source_id, coord, alt_id, td])
                if _has_peering_bits(td):
                    shaped[td.terrain] = true

    var result: Array = []
    for _i: int in range(ts.get_terrains_count(TERRAIN_SET)):
        result.append([])
    for tile: Array in tiles:
        var td: TileData = tile[3]
        var rules: Dictionary = _rules_for(td) if shaped.has(td.terrain) else {}
        result[td.terrain].append([tile[0], tile[1], tile[2], rules, td.probability])
    return result


static func _has_peering_bits(td: TileData) -> bool:
    for neighbour: TileSet.CellNeighbor in NEIGHBOURS:
        if td.get_terrain_peering_bit(neighbour) >= 0:
            return true
    return false


# Corners only matter if both their sides match the tile's own terrain
static func _rules_for(td: TileData) -> Dictionary:
    var rules: Dictionary = {}
    for side: TileSet.CellNeighbor in SIDES:
        var bit: int = td.get_terrain_peering_bit(side)
        rules[side] = bit if bit >= 0 else NOT_OWN

    for corner: TileSet.CellNeighbor in CORNER_SIDES:
        var bit: int = td.get_terrain_peering_bit(corner)
        if bit >= 0:
            rules[corner] = bit
            continue
        var connects: bool = true
        for side: TileSet.CellNeighbor in CORNER_SIDES[corner]:
            if td.get_terrain_peering_bit(side) != td.terrain:
                connects = false
        if connects:
            rules[corner] = NOT_OWN
    return rules


static func _neighbour_terrains(
    terrains: PackedInt32Array, size: Vector2i, x: int, y: int, outside: int
) -> PackedInt32Array:
    var result: PackedInt32Array = PackedInt32Array()
    result.resize(OFFSETS.size())
    for i: int in range(OFFSETS.size()):
        var nx: int = x + OFFSETS[i].x
        var ny: int = y + OFFSETS[i].y
        var inside: bool = nx >= 0 and ny >= 0 and nx < size.x and ny < size.y
        result[i] = terrains[ny * size.x + nx] if inside else outside
    return result


# +REWARD per satisfied rule, PENALTY per broken one
static func _best_candidates(tiles: Array, own: int, around: PackedInt32Array) -> Array:
    var terrain_at: Dictionary = {}
    for i: int in range(NEIGHBOURS.size()):
        terrain_at[NEIGHBOURS[i]] = around[i]

    var best_score: int = -1000
    var best: Array = []
    for tile: Array in tiles:
        var score: int = 0
        var rules: Dictionary = tile[3]
        for neighbour: int in rules:
            var rule: int = rules[neighbour]
            var there: int = terrain_at[neighbour]
            var satisfied: bool = there != own if rule == NOT_OWN else there == rule
            score += REWARD if satisfied else PENALTY
        if score > best_score:
            best_score = score
            best = [tile]
        elif score == best_score:
            best.append(tile)
    return best


# Weighted pick, seeded by position
static func _pick(choices: Array, cell: Vector2i, rng: RandomNumberGenerator) -> Array:
    if choices.is_empty():
        return []
    rng.seed = hash(cell)
    if choices.size() == 1:
        return choices[0]

    var weight: float = 0.0
    for choice: Array in choices:
        weight += choice[4]
    if weight == 0.0:
        return choices[rng.randi() % choices.size()]

    var roll: float = rng.randf() * weight
    for choice: Array in choices:
        if roll < choice[4]:
            return choice
        roll -= choice[4]
    return choices.back()
