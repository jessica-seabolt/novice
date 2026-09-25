class_name TurnSystem extends RefCounted
## Decides who acts next, and asks each actor to take its turn

signal actor_acted(actor: Entity)

var _actors: Array[Entity] = []
var _running: bool = false


func add_actor(actor: Entity) -> void:
    _actors.append(actor)


func remove_actor(actor: Entity) -> void:
    _actors.erase(actor)


## Runs until stop() is called
func run() -> void:
    if _actors.is_empty():
        return
    _running = true
    while _running:
        # A copy, since actors can be removed mid-round
        for actor: Entity in _actors.duplicate():
            if not _actors.has(actor):
                continue
            await actor.take_turn()
            actor_acted.emit(actor)
            if not _running:
                return


## Takes effect once the current turn ends
func stop() -> void:
    _running = false
