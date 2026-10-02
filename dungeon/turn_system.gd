class_name TurnSystem extends RefCounted
## Decides who acts next, and asks each actor to take its turn

## Awaited before each actor's turn
var before_turn: Callable

var _actors: Array[Entity] = []
var _running: bool = false
# Lets a stale loop notice a newer run has started
var _generation: int = 0


func add_actor(actor: Entity) -> void:
    _actors.append(actor)


func remove_actor(actor: Entity) -> void:
    _actors.erase(actor)


## Runs until stop() is called
func run() -> void:
    if _actors.is_empty():
        return
    _running = true
    _generation += 1
    var generation: int = _generation
    while _running:
        # A copy, since actors can be removed or freed mid-round
        for entry: Variant in _actors.duplicate():
            if not is_instance_valid(entry) or not _actors.has(entry):
                continue
            var actor: Entity = entry
            if before_turn.is_valid():
                await before_turn.call(actor)
            if generation != _generation or not _running:
                return
            await actor.take_turn()
            if generation != _generation:
                return


## Takes effect once the current turn ends
func stop() -> void:
    _running = false
