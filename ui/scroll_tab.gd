class_name ScrollTab extends TextureRect
## A fixed-size, draggable scroll tab, since built-in grabbers stretch

@export var scroll: ScrollContainer

var _dragging: bool = false
# Where on the tab it was grabbed
var _grab_offset: float = 0.0


func _process(_delta: float) -> void:
    var bar: VScrollBar = scroll.get_v_scroll_bar()
    visible = bar.visible
    if not visible:
        return
    var track: Rect2 = bar.get_global_rect()
    global_position = Vector2(
        track.position.x, track.position.y + roundf(_ratio(bar) * _travel(bar))
    )


func _gui_input(event: InputEvent) -> void:
    var button: InputEventMouseButton = event as InputEventMouseButton
    if button != null and button.button_index == MOUSE_BUTTON_LEFT:
        _dragging = button.pressed
        _grab_offset = button.global_position.y - global_position.y
        accept_event()
        return

    var motion: InputEventMouseMotion = event as InputEventMouseMotion
    if motion == null or not _dragging:
        return
    var bar: VScrollBar = scroll.get_v_scroll_bar()
    var travel: float = _travel(bar)
    if travel <= 0.0:
        return
    var top: float = motion.global_position.y - _grab_offset - bar.get_global_rect().position.y
    bar.value = clampf(top, 0.0, travel) / travel * (bar.max_value - bar.page)
    accept_event()


func _ratio(bar: VScrollBar) -> float:
    var scroll_range: float = bar.max_value - bar.page
    return 0.0 if scroll_range <= 0.0 else bar.value / scroll_range


func _travel(bar: VScrollBar) -> float:
    return bar.get_global_rect().size.y - size.y
