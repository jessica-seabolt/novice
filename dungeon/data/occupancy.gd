class_name Occupancy extends RefCounted
## Tracks which entity stands on which tile

var _entities: Dictionary = {}


func is_occupied(p: Vector2i) -> bool:
    return _entities.has(p)


## Null if the tile is empty
func get_entity(p: Vector2i) -> Entity:
    return _entities.get(p)


func place(entity: Entity, p: Vector2i) -> void:
    _entities[p] = entity


func remove(p: Vector2i) -> void:
    _entities.erase(p)


func move(entity: Entity, from: Vector2i, to: Vector2i) -> void:
    _entities.erase(from)
    _entities[to] = entity
