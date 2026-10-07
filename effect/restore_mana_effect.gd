class_name RestoreManaEffect extends Effect
## Restores mana

@export_range(1, 1000) var amount: int = 1


func apply(_source: Entity, target: Entity) -> void:
    Stats.of(target).restore_mana(amount)


func is_useful(target: Entity) -> bool:
    var stats: Stats = Stats.of(target)
    return stats.mana < stats.stat_block.max_mana
