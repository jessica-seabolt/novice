extends Node
## A central hub for emitting and connecting to game signals

@warning_ignore_start("unused_signal")
signal entity_damaged(entity: Entity, amount: int)
signal entity_defeated(entity: Entity)
signal entity_healed(entity: Entity, amount: int)
signal mana_restored(entity: Entity, amount: int)
signal spell_cast(caster: Entity, spell: Spell, tiles: Array[Vector2i])
signal cast_refused(caster: Entity, spell: Spell)
signal item_picked_up(entity: Entity, stack: ItemStack)
signal no_room_for(entity: Entity, stack: ItemStack)
signal item_used(entity: Entity, item: ItemData)
signal item_dropped(entity: Entity, stack: ItemStack)
signal item_equipped(entity: Entity, stack: ItemStack)
