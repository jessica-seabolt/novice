class_name Spellbook extends Node
## The spells an entity knows, and casting them

signal requested(spell: Spell)

## Known by everyone
const BASIC: Spell = preload("res://entity/spells/sp_basic.tres")

var spells: Array[Spell] = []

@onready var _entity: Entity = get_parent() as Entity


## Null if the entity can't cast
static func of(entity: Entity) -> Spellbook:
    return entity.get_node_or_null("Spellbook") as Spellbook


# Learning spells leaves the stat block alone
func _ready() -> void:
    spells.assign(Stats.of(_entity).stat_block.spells)


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
        _affect(spell, target)


func _affect(spell: Spell, target: Entity) -> void:
    var target_stats: Stats = Stats.of(target)
    if target_stats == null:
        return
    var rng: RandomNumberGenerator = _entity.floor_state.rng
    match spell.effect:
        Spell.Effect.DAMAGE:
            var attack: int = Stats.of(_entity).stat_block.attack
            var defense: int = target_stats.stat_block.defense
            target_stats.take_damage(Dice.roll_damage(spell.power, attack, defense, rng))
        Spell.Effect.HEAL:
            target_stats.heal(Dice.roll_exploding(spell.power, rng))
