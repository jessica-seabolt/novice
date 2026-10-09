class_name DamageEffect extends Effect
## Rolls damage from the source's attack against the target's defense

## Dice rolled
@export_range(1, 10) var power: int = 1


func apply(source: Entity, target: Entity) -> void:
    var attack: int = Stats.of(source).attack
    var target_stats: Stats = Stats.of(target)
    var defense: int = target_stats.defense
    var rng: RandomNumberGenerator = source.floor_state.rng
    target_stats.take_damage(Dice.roll_damage(power, attack, defense, rng))


func strengthen() -> void:
    power += 1
