class_name HealEffect extends Effect
## Restores HP

## Dice rolled
@export_range(1, 10) var power: int = 1


func apply(source: Entity, target: Entity) -> void:
    Stats.of(target).heal(Dice.roll_exploding(power, source.floor_state.rng))


func is_useful(target: Entity) -> bool:
    var stats: Stats = Stats.of(target)
    return stats.hp < stats.stat_block.max_hp


func strengthen() -> void:
    power += 1
