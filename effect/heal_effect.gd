class_name HealEffect extends Effect
## Restores HP

@export_range(1, 1000) var amount: int = 1


func apply(_source: Entity, target: Entity) -> void:
    Stats.of(target).heal(amount)


func is_useful(target: Entity) -> bool:
    var stats: Stats = Stats.of(target)
    return stats.hp < stats.stat_block.max_hp
