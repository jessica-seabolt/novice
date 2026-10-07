class_name Spellbook extends Node
## The spells an entity knows, and casting them

signal changed
signal requested(spell: Spell)

## Known by everyone
const BASIC: Spell = preload("res://entity/spells/spell_basic.tres")
## One per casting button
const MAX_SPELLS: int = 4

var spells: Array[Spell] = []
# Each original spell's copy in spells, which strengthening changes
var _copies: Dictionary[Spell, Spell] = {}

@onready var _entity: Entity = get_parent() as Entity


## Null if the entity can't cast
static func of(entity: Entity) -> Spellbook:
    return entity.get_node_or_null("Spellbook") as Spellbook


func _ready() -> void:
    reset()


## Back to the stat block's spells, forgetting what was learned
func reset() -> void:
    spells.clear()
    _copies.clear()
    for spell: Spell in Stats.of(_entity).stat_block.spells:
        _add_copy(spell)
    changed.emit()


func can_learn(spell: Spell) -> bool:
    return _copies.has(spell) or spells.size() < MAX_SPELLS


## A spell already known gets an extra die instead
func learn(spell: Spell) -> void:
    if _copies.has(spell):
        for effect: Effect in _copies[spell].effects:
            effect.strengthen()
        SignalBus.spell_strengthened.emit(_entity, _copies[spell])
        return
    _add_copy(spell)
    changed.emit()
    SignalBus.spell_learned.emit(_entity, spell)


func can_cast(spell: Spell) -> bool:
    return Stats.of(_entity).mana >= spell.cost


## Refused without enough mana
func request(spell: Spell) -> void:
    if not can_cast(spell):
        SignalBus.cast_refused.emit(_entity, spell)
        return
    requested.emit(spell)


## Returns once the cast plays out
func cast(spell: Spell) -> void:
    var state: FloorState = _entity.floor_state
    await state.wait_for_slides()
    _entity.hold(Spell.DURATION)
    Stats.of(_entity).spend_mana(spell.cost)
    var here: Vector2i = _entity.grid_position
    var tiles: Array[Vector2i] = SpellArea.tiles(spell, state, here, _entity.facing)
    var targets: Array[Entity] = SpellArea.targets(spell, _entity, _entity.facing)
    SignalBus.spell_cast.emit(_entity, spell, tiles)
    for target: Entity in targets:
        for effect: Effect in spell.effects:
            effect.apply(_entity, target)


func _add_copy(spell: Spell) -> void:
    var copy: Spell = spell.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)
    _copies[spell] = copy
    spells.append(copy)
