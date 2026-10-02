class_name SelectionMenu extends Control
## A framed list of options with a cursor, sized to fit, that handles its own input

signal opened
signal closed
signal highlighted(index: int)
signal chosen(index: int)
signal cancelled

const NAVIGATE_SOUND: AudioStream = preload("res://audio/sfx/sfx_menu_navigate.ogg")
const SELECT_SOUND: AudioStream = preload("res://audio/sfx/sfx_menu_select.ogg")
const BAD_SOUND: AudioStream = preload("res://audio/sfx/sfx_menu_bad_selection.ogg")
const DISABLED_COLOR: Color = Color(0.5, 0.5, 0.5)
## Where the cursor's centre sits, from the menu's left edge
const CURSOR_X: float = 12.0

var _enabled: Array[bool] = []
var _index: int = 0

@onready var _content: MarginContainer = $Content
@onready var _rows: VBoxContainer = $Content/Rows
@onready var _cursor: Sprite2D = $Cursor


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    hide()


func _process(_delta: float) -> void:
    if not visible or _rows.get_child_count() == 0:
        return
    var row: Label = _rows.get_child(_index) as Label
    var centre_y: float = _content.position.y + _rows.position.y + row.position.y + row.size.y / 2.0
    _cursor.position = Vector2(CURSOR_X, roundf(centre_y))


func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed(&"move_up", true):
        _move(-1)
    elif event.is_action_pressed(&"move_down", true):
        _move(1)
    elif event.is_action_pressed(&"menu_confirm"):
        _confirm()
    elif event.is_action_pressed(&"menu_cancel") or event.is_action_pressed(&"open_menu"):
        cancelled.emit()
    else:
        return
    get_viewport().set_input_as_handled()


## Unavailable options are greyed out; the cursor starts on the first available one
func set_items(texts: Array[String], enabled: Array[bool] = []) -> void:
    for row: Node in _rows.get_children():
        _rows.remove_child(row)
        row.queue_free()
    _enabled.clear()

    for i: int in range(texts.size()):
        var row: Label = Label.new()
        row.text = texts[i]
        row.mouse_filter = Control.MOUSE_FILTER_STOP
        row.mouse_entered.connect(_hover.bind(i))
        row.gui_input.connect(_on_row_input.bind(i))
        _rows.add_child(row)
        _enabled.append(true)
    if not enabled.is_empty():
        set_enabled(enabled)

    _index = maxi(0, _enabled.find(true))
    size = _content.get_combined_minimum_size()


## Keeps the cursor where it was
func set_enabled(enabled: Array[bool]) -> void:
    _enabled = enabled.duplicate()
    for i: int in range(_rows.get_child_count()):
        var row: Label = _rows.get_child(i) as Label
        if _enabled[i]:
            row.remove_theme_color_override(&"font_color")
        else:
            row.add_theme_color_override(&"font_color", DISABLED_COLOR)


## Keeps the cursor where it was
func open() -> void:
    show()
    opened.emit()
    highlighted.emit(_index)


func close() -> void:
    hide()
    closed.emit()


func _move(step: int) -> void:
    if _enabled.size() <= 1:
        return
    _index = posmod(_index + step, _enabled.size())
    Sfx.play(NAVIGATE_SOUND)
    highlighted.emit(_index)


func _confirm() -> void:
    if not _enabled[_index]:
        Sfx.play(BAD_SOUND)
        return
    Sfx.play(SELECT_SOUND)
    chosen.emit(_index)


func _hover(index: int) -> void:
    if visible and index != _index:
        _index = index
        Sfx.play(NAVIGATE_SOUND)
        highlighted.emit(_index)


func _on_row_input(event: InputEvent, index: int) -> void:
    var click: InputEventMouseButton = event as InputEventMouseButton
    if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
        return
    _index = index
    _confirm()
    accept_event()
