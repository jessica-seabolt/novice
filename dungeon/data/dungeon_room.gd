class_name DungeonRoom extends RefCounted

var id: int
var area: Rect2i

func _init(room_id: int, room_area: Rect2i) -> void:
    id = room_id
    area = room_area


func get_center() -> Vector2i:
    return Vector2i(
        area.position.x + floori(area.size.x / 2.0),
        area.position.y + floori(area.size.y / 2.0)
    )
