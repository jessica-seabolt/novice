class_name CombatSounds extends Node
## Plays combat sound effects

const DAMAGE_SOUND: AudioStream = preload("res://audio/sfx/sfx_damage.ogg")


func _ready() -> void:
    SignalBus.entity_damaged.connect(_on_entity_damaged)


func _on_entity_damaged(_entity: Entity, _amount: int) -> void:
    Sfx.play(DAMAGE_SOUND)
