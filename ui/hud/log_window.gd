class_name LogWindow extends Control
## Every message this run, scrollable, pausing the game while open

signal opened
signal closed

## Pixels scrolled per second with the directions
const SCROLL_SPEED: float = 60.0
## Pixels scrolled per mouse wheel notch
const WHEEL_STEP: float = 24.0
## How quickly wheel scrolling glides to its target
const SMOOTHING: float = 15.0

var _scroll: float = 0.0
var _target: float = 0.0

@onready var _scroll_container: ScrollContainer = $Scroll
@onready var _text: Label = $Scroll/Text


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    hide()
    # Caught before the container's own wheel scrolling
    _scroll_container.gui_input.connect(_on_wheel.bind(_scroll_container))
    var bar: VScrollBar = _scroll_container.get_v_scroll_bar()
    bar.gui_input.connect(_on_wheel.bind(bar))


func _process(delta: float) -> void:
    if not visible:
        return
    # Dragging the tab or clicking the track moves the scroll directly
    if _scroll_container.scroll_vertical != roundi(_scroll):
        _scroll = _scroll_container.scroll_vertical
        _target = _scroll

    var direction: float = Input.get_axis(&"move_up", &"move_down")
    if direction != 0.0:
        _target = clampf(_target + direction * SCROLL_SPEED * delta, 0.0, _max_scroll())
        _scroll = _target
    else:
        _scroll = lerpf(_scroll, _target, 1.0 - exp(-SMOOTHING * delta))
        if absf(_target - _scroll) < 1.0:
            _scroll = _target
    _scroll_container.scroll_vertical = roundi(_scroll)


func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed(&"toggle_log"):
        return
    get_viewport().set_input_as_handled()
    if visible:
        close()
    else:
        open()


func open() -> void:
    show()
    get_tree().paused = true
    opened.emit()
    _scroll_to_end.call_deferred()


func close() -> void:
    hide()
    get_tree().paused = false
    closed.emit()


func set_lines(lines: Array[String]) -> void:
    _text.text = "\n".join(lines)


func _on_wheel(event: InputEvent, source: Control) -> void:
    var button: InputEventMouseButton = event as InputEventMouseButton
    if button == null or not button.pressed:
        return
    var notches: float = button.factor if button.factor > 0.0 else 1.0
    if button.button_index == MOUSE_BUTTON_WHEEL_UP:
        _target -= WHEEL_STEP * notches
    elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        _target += WHEEL_STEP * notches
    else:
        return
    _target = clampf(_target, 0.0, _max_scroll())
    source.accept_event()


func _max_scroll() -> float:
    var bar: VScrollBar = _scroll_container.get_v_scroll_bar()
    return maxf(0.0, bar.max_value - bar.page)


func _scroll_to_end() -> void:
    _scroll_container.scroll_vertical = roundi(_max_scroll())
    _scroll = _scroll_container.scroll_vertical
    _target = _scroll
