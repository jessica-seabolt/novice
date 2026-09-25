class_name AimOverlay extends Node2D
## While aim is held, shows the grid and the line of tiles the player is facing

const GRID_COLOR: Color = Color(1.0, 1.0, 1.0, 0.15)
const LINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.5)

# What was last drawn, so it only redraws when something changes
var _drawn_position: Vector2i
var _drawn_facing: Vector2i

@onready var _entity: Entity = get_parent() as Entity


func _ready() -> void:
    # Drawn in the floor's space
    top_level = true
    z_index = 1
    visible = false


func _process(_delta: float) -> void:
    var aiming: bool = _entity.floor_state != null and Input.is_action_pressed(&"aim")
    var changed: bool = (
        _entity.grid_position != _drawn_position or _entity.facing != _drawn_facing
    )
    if aiming and (not visible or changed):
        _drawn_position = _entity.grid_position
        _drawn_facing = _entity.facing
        queue_redraw()
    visible = aiming


func _draw() -> void:
    var grid: FloorGrid = _entity.floor_state.grid
    var first: Rect2 = _entity.tile_rect(Vector2i.ZERO)
    var origin: Vector2 = first.position
    var size: Vector2 = first.size
    var far: Vector2 = origin + size * Vector2(grid.width, grid.height)

    var lines: PackedVector2Array = PackedVector2Array()
    for x: int in range(grid.width + 1):
        var line_x: float = origin.x + size.x * x
        lines.append(Vector2(line_x, origin.y))
        lines.append(Vector2(line_x, far.y))
    for y: int in range(grid.height + 1):
        var line_y: float = origin.y + size.y * y
        lines.append(Vector2(origin.x, line_y))
        lines.append(Vector2(far.x, line_y))
    draw_multiline(lines, GRID_COLOR, 1.0)

    var p: Vector2i = _entity.grid_position + _entity.facing
    while grid.is_in_bounds(p) and not grid.is_wall(p):
        draw_rect(_entity.tile_rect(p), LINE_COLOR, false, 2.0)
        p += _entity.facing
