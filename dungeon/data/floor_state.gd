class_name FloorState extends RefCounted
## What entities need to know about the current floor

var grid: FloorGrid
var rooms: Array[DungeonRoom]
var reachable_tiles: Array[Vector2i]
var rng: RandomNumberGenerator
var occupancy: Occupancy = Occupancy.new()
## Slide time for this turn, set by the player so everything moves at their pace
var step_duration: float = 0.15
## Shared 8-direction pathfinder
var pathfinder: AStarGrid2D
var player: Entity


# Walls and water are solid; entities are checked as each step is taken
static func _build_pathfinder(floor_grid: FloorGrid) -> AStarGrid2D:
    var astar: AStarGrid2D = AStarGrid2D.new()
    astar.region = Rect2i(0, 0, floor_grid.width, floor_grid.height)
    astar.cell_size = Vector2(1, 1)
    astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
    astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
    astar.update()

    for y: int in range(floor_grid.height):
        for x: int in range(floor_grid.width):
            var p: Vector2i = Vector2i(x, y)
            if not floor_grid.is_ground(p):
                astar.set_point_solid(p, true)

    return astar


func _init(
    floor_grid: FloorGrid,
    floor_rooms: Array[DungeonRoom],
    floor_reachable_tiles: Array[Vector2i],
    floor_rng: RandomNumberGenerator
) -> void:
    grid = floor_grid
    rooms = floor_rooms
    reachable_tiles = floor_reachable_tiles
    rng = floor_rng
    pathfinder = _build_pathfinder(floor_grid)
