class_name Stats extends Node
## An entity's current stats

signal changed
signal damaged(amount: int)

## Turns without taking damage before stepping heals (needs tuning lol)
const REGEN_DELAY: int = 5

@export var stat_block: StatBlock

var hp: int
var mana: int
var stat_points: int = 0

var _turns_since_damage: int = 0

@onready var _entity: Entity = get_parent() as Entity


## Null if the entity has no stats
static func of(entity: Entity) -> Stats:
    return entity.get_node_or_null("Stats") as Stats


func _ready() -> void:
    hp = stat_block.max_hp
    mana = stat_block.max_mana
    _entity.stepped.connect(_on_stepped)
    _entity.turn_taken.connect(_on_turn_taken)


func take_damage(amount: int) -> void:
    if hp == 0:
        return
    hp = maxi(0, hp - amount)
    _turns_since_damage = 0
    changed.emit()
    damaged.emit(amount)
    SignalBus.entity_damaged.emit(_entity, amount)
    if hp == 0:
        SignalBus.entity_defeated.emit(_entity)


func heal(amount: int) -> void:
    var healed: int = mini(amount, stat_block.max_hp - hp)
    if hp == 0 or healed <= 0:
        return
    hp += healed
    changed.emit()
    SignalBus.entity_healed.emit(_entity, healed)


func restore() -> void:
    hp = stat_block.max_hp
    mana = stat_block.max_mana
    changed.emit()


func _on_stepped() -> void:
    if _turns_since_damage >= REGEN_DELAY and hp < stat_block.max_hp:
        hp += 1
        changed.emit()


func _on_turn_taken() -> void:
    _turns_since_damage += 1
