# NoVice GDScript Style Guide


## Naming

- snake_case for variables, functions, signals, and file names
- PascalCase for class names, enums, and nodes
- CONSTANT_CASE for constants and enum members
- Private members and functions prefixed with _
- Signals are named as past-tense events: `room_generated`, `floor_completed`, not `generate_room` or `on_floor_complete`
- Boolean variables/functions read as yes/no questions: `is_walkable`, `has_trap`, `can_spawn_here`
- Avoid abbreviations unless they're standard (`pos`, `id`, etc. are fine; `rm_cfg` is not)

## Privacy

- Default everything to private
- If a variable is only internal (e.g. `_rng`, `_room_rects`), keep it private
- Only use public methods to access or mutate private data

## Architecture

- Favor composition over inheritance
- Prefer small, focused classes with a single job
- Functions do one task
- Avoid god objects
- Data-holding classes (`DungeonTile`, `DungeonGrid`) should be dumb where possible
- Configurations should be a Resource

## Typing

- Use static typing everywhere unless untyped is necessary
- Avoid type inference
- Avoid :=
- Type function returns explicitly, including -> void for functions with no return value
- Always specify namespace, even within the owning class (`SectorLayout.Orientation`, not `Orientation`)

## Comments

- Only comment non-obvious implementation details or doc comments
- No comment is better than an obvious one
- Keep comments concise and specific
- Use ## for documentation meant to surface in tooltips or generated docs
- Use # for internal implementation notes
- Trail a comment to the right of the line it describes if it's short
- Place a comment one line above the code it describes if it's long or multiple lines
- No period at the end of a comment

## Organization

- One class per file
- File name matches the class

- Inside a file, order top to bottom:
    01. @tool, @icon, @static_unload
    02. class_name / extends
    03. ## doc comment

    04. signals
    05. enums
    06. constants
    07. static variables
    08. @export variables
    09. remaining regular variables
    10. @onready variables

    11. _static_init()
    12. remaining static methods
    13. overridden built-in virtual methods:
        1. _init()
        2. _enter_tree()
        3. _ready()
        4. _process()
        5. _physics_process()
        6. remaining virtual methods
    14. overridden custom methods
    15. remaining methods
    16. inner classes

- Class methods and variables follow this order:
    01. public
    02. private

## Signals and Globals

- Prefer signals for "something happened" communication
- Avoid globals when possible
- Send signals through a global SignalBus to keep code decoupled

## Enums

- Prefer enums over raw strings/ints for anything with a fixed, known set of states
- Prefer bitmasks when different states can be true or false simultaneously
- Always use trailing commas on enums

## Misc

- Guard clauses over deep nesting
- Return/continue early when possible and avoid if/else return statements
- Use ternary statements (y if x else z) for simple if/else statements
- Use match with enums
- Magic numbers should be named constants
- Prefer class_name over preloading for game-specific objects
- Keep lines under 100 characters
