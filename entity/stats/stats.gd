class_name Stats extends Node
## An entity's current stats

## Turns without taking damage before stepping heals
const REGEN_DELAY: int = 5

@export var stat_block: StatBlock

var hp: int
var stat_points: int = 0

var _turns_since_damage: int = 0

@onready var _entity: Entity = get_parent() as Entity


func _ready() -> void:
    hp = stat_block.max_hp
    _entity.stepped.connect(_on_stepped)
    _entity.turn_taken.connect(_on_turn_taken)


## Null if the entity has no stats
static func of(entity: Entity) -> Stats:
    return entity.get_node_or_null("Stats") as Stats


func take_damage(amount: int) -> void:
    if hp == 0:
        return
    hp = maxi(0, hp - amount)
    _turns_since_damage = 0
    SignalBus.entity_damaged.emit(_entity, amount)
    if hp == 0:
        SignalBus.entity_defeated.emit(_entity)


func restore() -> void:
    hp = stat_block.max_hp


func _on_stepped() -> void:
    if _turns_since_damage >= REGEN_DELAY:
        hp = mini(stat_block.max_hp, hp + 1)


func _on_turn_taken() -> void:
    _turns_since_damage += 1
