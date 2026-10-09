class_name StatBlock extends Resource
## An entity's starting stats and spells

@export_range(1, 1000) var max_hp: int = 1
@export_range(0, 100) var attack: int = 0
@export_range(0, 100) var defense: int = 0
@export_range(1, 1000) var max_mana: int = 1
## XP the player earns for defeating this entity
@export_range(0, 1000) var xp_reward: int = 0
## Up to four, one per casting button (change later?)
@export var spells: Array[Spell] = []
