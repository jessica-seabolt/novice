class_name SpellFlash extends Node2D
## Briefly lights up the tiles a spell covers

const DAMAGE_COLOR: Color = Color(1.0, 0.85, 0.5, 0.5)
const SUPPORT_COLOR: Color = Color(0.5, 1.0, 0.6, 0.5)


func _ready() -> void:
    z_index = 1
    process_mode = Node.PROCESS_MODE_ALWAYS
    SignalBus.spell_cast.connect(_on_spell_cast)


func _on_spell_cast(caster: Entity, spell: Spell, tiles: Array[Vector2i]) -> void:
    var flash: Node2D = Node2D.new()
    var targets_allies: bool = spell.targets == Spell.Targets.ALLIES
    var color: Color = SUPPORT_COLOR if targets_allies else DAMAGE_COLOR
    for p: Vector2i in tiles:
        var rect: Rect2 = caster.tile_rect(p)
        var tile: ColorRect = ColorRect.new()
        tile.color = color
        tile.position = rect.position
        tile.size = rect.size
        tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
        flash.add_child(tile)
    add_child(flash)

    var tween: Tween = flash.create_tween()
    tween.tween_property(flash, "modulate:a", 0.0, Spell.DURATION)
    tween.tween_callback(flash.queue_free)
