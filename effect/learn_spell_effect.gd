class_name LearnSpellEffect extends Effect
## Teaches a spell, or strengthens it if it's already known

@export var spell: Spell


func apply(_source: Entity, target: Entity) -> void:
    Spellbook.of(target).learn(spell)


func can_apply(target: Entity) -> bool:
    var spellbook: Spellbook = Spellbook.of(target)
    return spellbook != null and spellbook.can_learn(spell)
