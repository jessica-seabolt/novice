class_name StatBlock extends Resource
## An entity's starting stats

@export_range(1, 1000) var max_hp: int = 1
@export_range(0, 100) var attack: int = 0
@export_range(0, 100) var defense: int = 0
@export_range(1, 1000) var max_mana: int = 1
## Stat points awarded for defeating this entity
@export_range(0, 100) var stat_point_reward: int = 0
