class_name Experience extends Node
## Levels earned with XP, each giving stat points; only the player levels up

signal changed

## XP from level 1 to 2; each level after needs this much more than the last
const BASE_XP: int = 10
const POINTS_PER_LEVEL: int = 5

var level: int = 1
## Towards the next level
var xp: int = 0

@onready var _entity: Entity = get_parent() as Entity


## Null if the entity doesn't level up
static func of(entity: Entity) -> Experience:
    return entity.get_node_or_null("Experience") as Experience


func xp_to_next_level() -> int:
    return BASE_XP * level


## Enough XP can level up more than once
func gain(amount: int) -> void:
    if amount <= 0:
        return
    xp += amount
    SignalBus.xp_gained.emit(_entity, amount)
    while xp >= xp_to_next_level():
        xp -= xp_to_next_level()
        level += 1
        Stats.of(_entity).add_stat_points(POINTS_PER_LEVEL)
        SignalBus.leveled_up.emit(_entity, level)
    changed.emit()


## Back to level 1, as at the start of a run
func reset() -> void:
    level = 1
    xp = 0
    changed.emit()
