class_name BasicSpell extends RefCounted
## Free spell that hits the entity the caster is facing

const POWER: int = 1
## Seconds a cast takes, so attacks play out one at a time
const DURATION: float = 0.3


static func cast(caster: Entity) -> void:
    var state: FloorState = caster.floor_state
    if MoveRules.cuts_corner(state.grid, caster.grid_position, caster.facing):
        return

    var target: Entity = state.occupancy.get_entity(caster.grid_position + caster.facing)
    if target == null:
        return
    var caster_stats: Stats = Stats.of(caster)
    var target_stats: Stats = Stats.of(target)
    if caster_stats == null or target_stats == null:
        return

    var damage: int = Dice.roll_damage(
        POWER, caster_stats.stat_block.attack, target_stats.stat_block.defense, state.rng
    )
    target_stats.take_damage(damage)
