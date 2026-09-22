class_name DungeonRoom extends RefCounted
## Represents a single room in the dungeon, with an ID and a rectangular area

var id: int
var area: Rect2i

## Prevents a room from merging more than once
var has_merged: bool = false


func _init(room_id: int, room_area: Rect2i) -> void:
    id = room_id
    area = room_area


func get_center() -> Vector2i:
    return Vector2i(
        area.position.x + floori(area.size.x / 2.0),
        area.position.y + floori(area.size.y / 2.0)
    )
