class_name Stats extends Node
## An entity's current stats

signal changed
signal damaged(amount: int)

## Stats that points can be spent on
enum Stat {
    ATTACK,
    DEFENSE,
}

## In the order of Stats.Stat
const STAT_NAMES: Array[String] = ["Attack", "Defense"]
const STAT_DESCRIPTIONS: Array[String] = [
    "Adds to the damage your spells deal.",
    "Takes away from the damage you take.",
]

## Turns without taking damage before stepping heals
const REGEN_DELAY: int = 5

@export var stat_block: StatBlock

var hp: int
var mana: int
var attack: int
var defense: int
var stat_points: int = 0

var _turns_since_damage: int = 0

@onready var _entity: Entity = get_parent() as Entity


## Null if the entity has no stats
static func of(entity: Entity) -> Stats:
    return entity.get_node_or_null("Stats") as Stats


func _ready() -> void:
    hp = stat_block.max_hp
    mana = stat_block.max_mana
    attack = stat_block.attack
    defense = stat_block.defense
    _entity.stepped.connect(_on_stepped)
    _entity.turn_taken.connect(_on_turn_taken)


func take_damage(amount: int) -> void:
    if hp == 0:
        return
    hp = maxi(0, hp - amount)
    _turns_since_damage = 0
    changed.emit()
    # Announced before anything reacts, like a held item healing
    SignalBus.entity_damaged.emit(_entity, amount)
    damaged.emit(amount)
    if hp == 0:
        SignalBus.entity_defeated.emit(_entity)


func heal(amount: int) -> void:
    var healed: int = mini(amount, stat_block.max_hp - hp)
    if hp == 0 or healed <= 0:
        return
    hp += healed
    changed.emit()
    SignalBus.entity_healed.emit(_entity, healed)


func restore_mana(amount: int) -> void:
    var restored: int = mini(amount, stat_block.max_mana - mana)
    if restored <= 0:
        return
    mana += restored
    changed.emit()
    SignalBus.mana_restored.emit(_entity, restored)


func spend_mana(amount: int) -> void:
    mana = maxi(0, mana - amount)
    changed.emit()


func get_stat(stat: Stats.Stat) -> int:
    match stat:
        Stats.Stat.ATTACK:
            return attack
        Stats.Stat.DEFENSE:
            return defense
    return 0


func add_stat_points(amount: int) -> void:
    stat_points += amount
    changed.emit()


func get_base(stat: Stats.Stat) -> int:
    match stat:
        Stats.Stat.ATTACK:
            return stat_block.attack
        Stats.Stat.DEFENSE:
            return stat_block.defense
    return 0


## Points spent on a stat, above its stat block value
func get_points_in(stat: Stats.Stat) -> int:
    return get_stat(stat) - get_base(stat)


## Every point earned, spent or not
func get_total_points() -> int:
    var total: int = stat_points
    for stat: int in range(STAT_NAMES.size()):
        total += get_points_in(stat as Stats.Stat)
    return total


## Spends points afresh, as many in each stat as given, by Stats.Stat
func allocate(points: Array[int]) -> void:
    var total: int = get_total_points()
    var spent: int = 0
    for points_in: int in points:
        spent += points_in
    assert(spent <= total, "More points allocated than earned")
    attack = stat_block.attack + points[Stats.Stat.ATTACK]
    defense = stat_block.defense + points[Stats.Stat.DEFENSE]
    stat_points = total - spent
    changed.emit()


## Back to the stat block, as at the start of a run
func restore() -> void:
    hp = stat_block.max_hp
    mana = stat_block.max_mana
    attack = stat_block.attack
    defense = stat_block.defense
    stat_points = 0
    changed.emit()


func _on_stepped() -> void:
    if _turns_since_damage >= REGEN_DELAY and hp < stat_block.max_hp:
        hp += 1
        changed.emit()


func _on_turn_taken() -> void:
    _turns_since_damage += 1
