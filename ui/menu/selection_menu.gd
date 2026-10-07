class_name SelectionMenu extends Control
## A framed list of options with a cursor, sized to fit, that handles its own input;
## the cursor skips greyed-out options

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
## The cursor's index when every option is greyed out
const NO_SELECTION: int = -1
## Icons sit in a square this many pixels wide, so names line up
const ICON_SIZE: int = 16
const ICON_GAP: int = 4
## Pixels per second a long highlighted name scrolls
const SCROLL_SPEED: float = 24.0
## Seconds a scrolling name rests at each end
const SCROLL_PAUSE: float = 0.8

## Longer names are cut short, and scroll while highlighted; 0 for no limit
@export var max_text_width: int = 0
## Pixels between rows
@export var row_gap: int = 4

var _enabled: Array[bool] = []
var _index: int = 0
var _labels: Array[Label] = []
# Each label's width with nothing cut off
var _full_widths: Array[float] = []
# Seconds since the highlighted name started scrolling
var _scroll_time: float = 0.0

@onready var _content: MarginContainer = $Content
@onready var _rows: VBoxContainer = $Content/Rows
@onready var _cursor: Sprite2D = $Cursor


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rows.add_theme_constant_override(&"separation", row_gap)
    hide()


func _process(delta: float) -> void:
    _cursor.visible = _index != NO_SELECTION
    if not visible or _index == NO_SELECTION:
        return
    var row: Control = _rows.get_child(_index) as Control
    var centre_y: float = _content.position.y + _rows.position.y + row.position.y + row.size.y / 2.0
    _cursor.position = Vector2(CURSOR_X, roundf(centre_y))
    _scroll_time += delta
    _scroll_highlighted()


func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed(&"move_up", true):
        _move(-1)
    elif event.is_action_pressed(&"move_down", true):
        _move(1)
    elif event.is_action_pressed(&"menu_confirm"):
        _confirm()
    elif event.is_action_pressed(&"menu_cancel"):
        cancelled.emit()
    else:
        return
    get_viewport().set_input_as_handled()


## Unavailable options are greyed out; the cursor starts on the first available one
func set_items(
    texts: Array[String], enabled: Array[bool] = [], icons: Array[Texture2D] = []
) -> void:
    for row: Node in _rows.get_children():
        _rows.remove_child(row)
        row.queue_free()
    _enabled.clear()
    _labels.clear()
    _full_widths.clear()

    for i: int in range(texts.size()):
        var icon: Texture2D = icons[i] if i < icons.size() else null
        _add_row(texts[i], icon, i)
        _enabled.append(true)
    if not enabled.is_empty():
        set_enabled(enabled)

    select_first()
    size = _content.get_combined_minimum_size()


## Keeps the cursor where it was, unless that option is now greyed out
func set_enabled(enabled: Array[bool]) -> void:
    _enabled = enabled.duplicate()
    for i: int in range(_labels.size()):
        if _enabled[i]:
            _labels[i].remove_theme_color_override(&"font_color")
        else:
            _labels[i].add_theme_color_override(&"font_color", DISABLED_COLOR)
    if _index == NO_SELECTION or _index >= _enabled.size() or not _enabled[_index]:
        select_first()


func select_first() -> void:
    _highlight(_enabled.find(true))


## Keeps the cursor where it was
func open() -> void:
    show()
    opened.emit()
    if _index != NO_SELECTION:
        highlighted.emit(_index)


func close() -> void:
    hide()
    closed.emit()


# A row is an optional icon, then the text in a box that cuts it short
func _add_row(text: String, icon: Texture2D, index: int) -> void:
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override(&"separation", ICON_GAP)
    row.mouse_filter = Control.MOUSE_FILTER_STOP
    row.mouse_entered.connect(_hover.bind(index))
    row.gui_input.connect(_on_row_input.bind(index))
    _rows.add_child(row)

    if icon != null:
        var icon_box: Control = Control.new()
        icon_box.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
        icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var image: TextureRect = TextureRect.new()
        image.texture = icon
        image.mouse_filter = Control.MOUSE_FILTER_IGNORE
        # Whole pixels, so odd-sized icons aren't drawn half a pixel off
        var gap: Vector2i = Vector2i(ICON_SIZE, ICON_SIZE) - Vector2i(icon.get_size())
        @warning_ignore("integer_division")
        image.position = Vector2(gap / 2)
        icon_box.add_child(image)
        row.add_child(icon_box)

    var clip: Control = Control.new()
    clip.clip_contents = true
    clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(clip)
    var label: Label = Label.new()
    label.text = text
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip.add_child(label)

    var full: Vector2 = label.get_combined_minimum_size()
    var width: float = full.x if max_text_width == 0 else minf(full.x, max_text_width)
    clip.custom_minimum_size = Vector2(width, full.y)
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    label.size = Vector2(width, full.y)
    _labels.append(label)
    _full_widths.append(full.x)


func _highlight(index: int) -> void:
    if _index != NO_SELECTION and _index < _labels.size():
        _rest_label(_index)
    _index = index
    _scroll_time = 0.0


func _rest_label(index: int) -> void:
    var label: Label = _labels[index]
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    label.size.x = label.get_parent_control().custom_minimum_size.x
    label.position.x = 0.0


# Rests at the start, slides to the end, rests, then starts over
func _scroll_highlighted() -> void:
    var label: Label = _labels[_index]
    var shown: float = label.get_parent_control().custom_minimum_size.x
    var overflow: float = _full_widths[_index] - shown
    if overflow <= 0.0:
        return
    label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
    label.size.x = _full_widths[_index]
    var cycle: float = overflow / SCROLL_SPEED + SCROLL_PAUSE * 2.0
    var t: float = fmod(_scroll_time, cycle)
    label.position.x = -roundf(clampf((t - SCROLL_PAUSE) * SCROLL_SPEED, 0.0, overflow))


func _move(step: int) -> void:
    if _index == NO_SELECTION:
        return
    var next: int = _index
    for _i: int in range(_enabled.size()):
        next = posmod(next + step, _enabled.size())
        if _enabled[next]:
            break
    if next == _index:
        return
    _highlight(next)
    Sfx.play(NAVIGATE_SOUND)
    highlighted.emit(_index)


func _confirm() -> void:
    if _index == NO_SELECTION:
        return
    Sfx.play(SELECT_SOUND)
    chosen.emit(_index)


func _hover(index: int) -> void:
    if visible and index != _index and _enabled[index]:
        _highlight(index)
        Sfx.play(NAVIGATE_SOUND)
        highlighted.emit(_index)


func _on_row_input(event: InputEvent, index: int) -> void:
    var click: InputEventMouseButton = event as InputEventMouseButton
    var is_left_click: bool = (
        click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT
    )
    if not is_left_click or not _enabled[index]:
        return
    _highlight(index)
    _confirm()
    accept_event()
