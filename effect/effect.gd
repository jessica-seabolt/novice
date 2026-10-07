class_name Effect extends Resource
## Something a spell or item does to an entity


func apply(_source: Entity, _target: Entity) -> void:
    pass


## Ensures mobs don't waste turns
func is_useful(_target: Entity) -> bool:
    return true
