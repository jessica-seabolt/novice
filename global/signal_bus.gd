extends Node
## A central hub for emitting and connecting to game signals


signal entity_damaged(entity: Entity, amount: int)
signal entity_defeated(entity: Entity)
signal entity_healed(entity: Entity, amount: int)
signal spell_cast(caster: Entity, spell: Spell, tiles: Array[Vector2i])
signal cast_refused(caster: Entity, spell: Spell)
