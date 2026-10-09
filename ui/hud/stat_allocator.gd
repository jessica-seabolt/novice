class_name StatAllocator extends Control
## Moves stat points between stats with − and + buttons, then confirms; used on levelling
## up and for respeccing from the stats menu. What the highlighted row does sits beside it

signal opened
signal closed
signal finished(confirmed: bool)

const MINUS_TEXTURE: Texture2D = preload("res://graphics/ui/minus.png")
const PLUS_TEXTURE: Texture2D = preload("res://graphics/ui/plus.png")
## Where the cursor's centre sits, from the window's left edge
const CURSOR_X: float = 12.0
const NAME_WIDTH: float = 44.0
const VALUE_WIDTH: float = 16.0
const DESCRIPTION_WIDTH: float = 88.0
## Pixels between the description box's frame and its text
const PADDING: Vector2 = Vector2(8.0, 7.0)
## Between the two boxes
const GAP: float = 4.0

var _stats: Stats
var _experience: Experience
var _levelled_up: bool
# Points put into each stat so far, by Stats.Stat; nothing changes until confirmed
var _points: Array[int] = []
var _total: int
# A stat's row, or one past the last stat for Confirm
var _index: int = 0
var _values: Array[Label] = []
var _minus_buttons: Array[TextureButton] = []
var _plus_buttons: Array[TextureButton] = []
var _names: Array[Label] = []

@onready var _panel: Control = $Panel
@onready var _content: MarginContainer = $Panel/Content
@onready var _rows: VBoxContainer = $Panel/Content/Rows
@onready var _title: Label = $Panel/Content/Rows/Title
@onready var _points_left: Label = $Panel/Content/Rows/Points
@onready var _grid: GridContainer = $Panel/Content/Rows/Stats
@onready var _confirm: Button = $Panel/Content/Rows/Confirm
@onready var _cursor: Sprite2D = $Panel/Cursor
@onready var _info: Control = $Info
@onready var _description: Label = $Info/Description


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    hide()
    for stat: int in range(Stats.STAT_NAMES.size()):
        _add_row(stat)
    _make_flat(_confirm)
    _confirm.pressed.connect(_on_confirm_pressed)
    _rows.sort_children.connect(_place_cursor)


func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed(&"move_up", true):
        _move(-1)
    elif event.is_action_pressed(&"move_down", true):
        _move(1)
    elif event.is_action_pressed(&"move_left", true):
        _adjust(_index, -1)
    elif event.is_action_pressed(&"move_right", true):
        _adjust(_index, 1)
    elif event.is_action_pressed(&"menu_confirm"):
        if _index == _points.size():
            _try_confirm()
        else:
            _adjust(_index, 1)
    elif event.is_action_pressed(&"menu_cancel"):
        cancel()
    else:
        return
    get_viewport().set_input_as_handled()


## True if confirmed; on levelling up there's no backing out
func edit(stats: Stats, experience: Experience, levelled_up: bool) -> bool:
    _stats = stats
    _experience = experience
    _levelled_up = levelled_up
    _total = stats.get_total_points()
    _points.clear()
    for stat: int in range(Stats.STAT_NAMES.size()):
        _points.append(stats.get_points_in(stat as Stats.Stat))
    _index = 0
    _refresh()
    show()
    opened.emit()
    return await finished


## Throws away any changes; does nothing on levelling up
func cancel() -> void:
    if visible and not _levelled_up:
        _close(false)


func _add_row(stat: int) -> void:
    var name_label: Label = Label.new()
    name_label.text = Stats.STAT_NAMES[stat]
    name_label.custom_minimum_size.x = NAME_WIDTH
    var minus: TextureButton = _make_button(MINUS_TEXTURE, stat, -1)
    var value: Label = Label.new()
    value.custom_minimum_size.x = VALUE_WIDTH
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var plus: TextureButton = _make_button(PLUS_TEXTURE, stat, 1)
    for child: Control in [name_label, minus, value, plus]:
        _grid.add_child(child)
    _names.append(name_label)
    _minus_buttons.append(minus)
    _values.append(value)
    _plus_buttons.append(plus)


func _make_button(texture: Texture2D, stat: int, step: int) -> TextureButton:
    var button: TextureButton = TextureButton.new()
    button.texture_normal = texture
    button.focus_mode = Control.FOCUS_NONE
    button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    button.pressed.connect(_on_step_pressed.bind(stat, step))
    return button


# No padding or focus box, and white like other text
func _make_flat(button: Button) -> void:
    var empty: StyleBoxEmpty = StyleBoxEmpty.new()
    for style: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
        button.add_theme_stylebox_override(style, empty)
    for color: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
        button.add_theme_color_override(color, Color.WHITE)
    button.add_theme_color_override(&"font_disabled_color", SelectionMenu.DISABLED_COLOR)
    button.focus_mode = Control.FOCUS_NONE


func _points_unspent() -> int:
    var spent: int = 0
    for points: int in _points:
        spent += points
    return _total - spent


func _adjust(stat: int, step: int) -> void:
    if stat >= _points.size():
        return
    var can_move: bool = (
        _points[stat] > 0 if step < 0 else _points_unspent() > 0
    )
    if not can_move:
        Sfx.play(SelectionMenu.BAD_SOUND)
        return
    _points[stat] += step
    Sfx.play(SelectionMenu.NAVIGATE_SOUND)
    _refresh()


func _move(step: int) -> void:
    _index = posmod(_index + step, _points.size() + 1)
    Sfx.play(SelectionMenu.NAVIGATE_SOUND)
    _refresh()


func _try_confirm() -> void:
    if _points_unspent() > 0:
        Sfx.play(SelectionMenu.BAD_SOUND)
        return
    Sfx.play(SelectionMenu.SELECT_SOUND)
    _stats.allocate(_points)
    _close(true)


func _close(confirmed: bool) -> void:
    hide()
    closed.emit()
    finished.emit(confirmed)


func _refresh() -> void:
    _title.text = (
        "Level %d!" % _experience.level
        if _levelled_up
        else "Level %d   %d/%d XP" % [
            _experience.level, _experience.xp, _experience.xp_to_next_level()
        ]
    )
    var unspent: int = _points_unspent()
    _points_left.text = "%d points left" % unspent
    for stat: int in range(_points.size()):
        var value: int = _stats.get_base(stat as Stats.Stat) + _points[stat]
        _values[stat].text = str(value)
        _set_usable(_minus_buttons[stat], _points[stat] > 0)
        _set_usable(_plus_buttons[stat], unspent > 0)
    _confirm.disabled = unspent > 0

    if _index < _points.size():
        _description.text = Stats.STAT_DESCRIPTIONS[_index]
    elif unspent > 0:
        _description.text = "Spend every point to confirm."
    else:
        _description.text = "Keep these stats."

    _layout()
    _place_cursor()


# The stats on the left and the description on the right
func _layout() -> void:
    _panel.size = _content.get_combined_minimum_size()
    _description.position = PADDING
    _description.size.x = DESCRIPTION_WIDTH
    var line_height: int = (
        _description.get_line_height() + _description.get_theme_constant(&"line_spacing")
    )
    _description.size.y = _description.get_line_count() * line_height
    var info_height: float = _description.size.y + PADDING.y * 2.0
    var height: float = maxf(_panel.size.y, info_height)
    _panel.size.y = height
    _info.size = Vector2(DESCRIPTION_WIDTH + PADDING.x * 2.0, height)
    var width: float = _panel.size.x + GAP + _info.size.x
    var corner: Vector2 = ((size - Vector2(width, height)) / 2.0).floor()
    _panel.position = corner
    _info.position = corner + Vector2(_panel.size.x + GAP, 0.0)


func _set_usable(button: TextureButton, usable: bool) -> void:
    button.disabled = not usable
    button.self_modulate = Color.WHITE if usable else SelectionMenu.DISABLED_COLOR


func _place_cursor() -> void:
    var target: Control = _confirm if _index == _points.size() else _names[_index]
    var top: Vector2 = _content.position + _rows.position + target.position
    if target != _confirm:
        top += _grid.position
    _cursor.position = Vector2(CURSOR_X, roundf(top.y + target.size.y / 2.0))


func _on_step_pressed(stat: int, step: int) -> void:
    _index = stat
    _adjust(stat, step)


func _on_confirm_pressed() -> void:
    _index = _points.size()
    _try_confirm()
