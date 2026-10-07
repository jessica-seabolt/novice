class_name SpellArea extends RefCounted
## The tiles a spell covers and who it affects, from where its caster stands and faces

## Clockwise from up
const DIRECTIONS: Array[Vector2i] = [
    Vector2i(0, -1),
    Vector2i(1, -1),
    Vector2i(1, 0),
    Vector2i(1, 1),
    Vector2i(0, 1),
    Vector2i(-1, 1),
    Vector2i(-1, 0),
    Vector2i(-1, -1),
]


static func tiles(
    spell: Spell, state: FloorState, from: Vector2i, facing: Vector2i
) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    match spell.shape:
        Spell.Shape.SELF:
            result.append(from)
        Spell.Shape.FRONT:
            result = _neighbours(state, from, [facing])
        Spell.Shape.SPREAD:
            result = _neighbours(state, from, [_turn(facing, -1), facing, _turn(facing, 1)])
        Spell.Shape.ADJACENT:
            result = _neighbours(state, from, SpellArea.DIRECTIONS)
        Spell.Shape.LINE:
            result = _line(state, from, facing, spell.reach)
        Spell.Shape.ROOM:
            result = Sight.visible_tiles(state, from)
    return result


static func targets(spell: Spell, caster: Entity, facing: Vector2i) -> Array[Entity]:
    var state: FloorState = caster.floor_state
    var result: Array[Entity] = []
    for p: Vector2i in tiles(spell, state, caster.grid_position, facing):
        var entity: Entity = state.occupancy.get_entity(p)
        if entity == null:
            continue
        if caster.is_foe(entity) == (spell.targets == Spell.Targets.FOES):
            result.append(entity)
    return result


static func _neighbours(
    state: FloorState, from: Vector2i, directions: Array[Vector2i]
) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for direction: Vector2i in directions:
        var to: Vector2i = from + direction
        if not state.grid.is_wall(to) and not MoveRules.cuts_corner(state.grid, from, direction):
            result.append(to)
    return result


# Stops at walls and at the first entity
static func _line(
    state: FloorState, from: Vector2i, direction: Vector2i, reach: int
) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var p: Vector2i = from
    for _i: int in range(reach):
        if MoveRules.cuts_corner(state.grid, p, direction):
            break
        p += direction
        if state.grid.is_wall(p):
            break
        result.append(p)
        if state.occupancy.is_occupied(p):
            break
    return result


# Eighth turns, negative is anticlockwise
static func _turn(direction: Vector2i, steps: int) -> Vector2i:
    var index: int = SpellArea.DIRECTIONS.find(direction)
    return SpellArea.DIRECTIONS[posmod(index + steps, SpellArea.DIRECTIONS.size())]
