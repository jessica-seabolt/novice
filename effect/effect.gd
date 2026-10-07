class_name Effect extends Resource
## Something a spell or item does to an entity


func apply(_source: Entity, _target: Entity) -> void:
    pass


## Ensures mobs don't waste turns
func is_useful(_target: Entity) -> bool:
    return true


## Whether it can be applied at all, like a scroll with no room to learn its spell
func can_apply(_target: Entity) -> bool:
    return true


## Adds a die, for effects that roll
func strengthen() -> void:
    pass
