class_name SectorLayout extends RefCounted
## Decides how many sectors a floor is divided into and which are valid

enum Orientation {
    STANDARD, ## Default orientation, one room per sector
    CHECKERBOARD, ## Alternate sectors are valid, creating a checkerboard pattern
    PLUS, ## Use the middle row and column for sectors, creating a plus shape
    CROSS, ## Use the diagonals of the grid for sectors, creating a cross shape
    CIRCLE, ## Make a single ring of sectors
    HUB, ## Use the center sector for a hub room, with other rooms around it
    SWIRL, ## Make a spiral of sectors
    RANDOM, ## Resolves to one of the other orientations at random
}

const CHECKERBOARD_MULTIPLIER: int = 2
const SWIRL_ANGLE_STEP: float = PI / 32.0
const MAX_SWIRL_STEPS: int = 10000
const SWIRL_RADIUS_MULTIPLIER: float = 0.5

const RANDOMIZABLE_ORIENTATIONS: Array[SectorLayout.Orientation] = [
    SectorLayout.Orientation.STANDARD,
    SectorLayout.Orientation.CHECKERBOARD,
    SectorLayout.Orientation.PLUS,
    SectorLayout.Orientation.CROSS,
    SectorLayout.Orientation.CIRCLE,
    SectorLayout.Orientation.HUB,
    SectorLayout.Orientation.SWIRL,
]


## Resolves RANDOM into a concrete orientation
static func resolve_orientation(
    orientation: SectorLayout.Orientation, rng: RandomNumberGenerator
) -> SectorLayout.Orientation:
    if orientation != SectorLayout.Orientation.RANDOM:
        return orientation
    var index: int = rng.randi_range(0, RANDOMIZABLE_ORIENTATIONS.size() - 1)
    return RANDOMIZABLE_ORIENTATIONS[index]


static func valid_sectors(
    target_rooms: int, orientation: SectorLayout.Orientation
) -> Array[Vector2i]:

    # Swirl precomputes valid sectors as an array so _is_valid doesn't apply
    if orientation == SectorLayout.Orientation.SWIRL:
        return _swirl_sectors(target_rooms)

    var grid_size: Vector2i = sector_grid_size(target_rooms, orientation)
    var valid: Array[Vector2i] = []

    for y: int in range(grid_size.y):
        for x: int in range(grid_size.x):
            var sector: Vector2i = Vector2i(x, y)
            if _is_valid(sector, orientation, grid_size, target_rooms):
                valid.append(sector)

    return valid


static func sector_grid_size(target_rooms: int, orientation: SectorLayout.Orientation) -> Vector2i:
    var total_sectors: int = _total_sectors(target_rooms, orientation)
    var sectors_across: int = ceil(sqrt(float(total_sectors)))
    var sectors_down: int = ceil(float(total_sectors) / float(sectors_across))
    return Vector2i(sectors_across, sectors_down)


static func _total_sectors(target_rooms: int, orientation: SectorLayout.Orientation) -> int:
    match orientation:
        SectorLayout.Orientation.CHECKERBOARD:
            # Twice as many sectors as there are rooms to make a checkerboard pattern
            return target_rooms * CHECKERBOARD_MULTIPLIER
        SectorLayout.Orientation.PLUS, SectorLayout.Orientation.CROSS:
            # Make the grid square by rounding up to the nearest perfect square
            var side: int = ceili(sqrt(float(target_rooms)))
            return side * side
        SectorLayout.Orientation.CIRCLE, SectorLayout.Orientation.HUB:
            # side >= 2 * radius + 1 to fit the circumference in the grid
            var radius: int = _get_radius_for_circle(target_rooms)
            var side: int = 2 * radius + 1
            return side * side
        SectorLayout.Orientation.SWIRL:
            var offsets: Array[Vector2i] = _swirl_offsets(target_rooms)
            var side: int = 2 * _swirl_extent(offsets) + 1
            return side * side
        _:
            # For other orientations, the number of sectors = the number of rooms
            return target_rooms


static func _is_valid(
    sector: Vector2i,
    orientation: SectorLayout.Orientation,
    dims: Vector2i,
    target_rooms: int
) -> bool:
    match orientation:
        SectorLayout.Orientation.CHECKERBOARD:
            # Alternate sectors to create a checkerboard pattern
            return (sector.x + sector.y) % CHECKERBOARD_MULTIPLIER == 0
        SectorLayout.Orientation.PLUS:
            # Divide the dimensions to get middle row and column
            var mid_row: int = floori(float(dims.y) / 2.0)
            var mid_col: int = floori(float(dims.x) / 2.0)
            return sector.y == mid_row or sector.x == mid_col
        SectorLayout.Orientation.CROSS:
            # Uses the formula for each diagonal of a square: y = x and y = -x + (n - 1)
            return sector.y == sector.x or sector.y == -sector.x + (dims.x - 1)
        SectorLayout.Orientation.CIRCLE:
            # A sector on the ring is one whose distance from center rounds to the radius
            var ring: int = _get_distance_from_center(sector, dims)
            return ring == _get_radius_for_circle(target_rooms)
        SectorLayout.Orientation.HUB:
            # Same ring as CIRCLE, plus the exact center sector for the hub room
            var ring: int = _get_distance_from_center(sector, dims)
            return ring == _get_radius_for_circle(target_rooms) or ring == 0
        SectorLayout.Orientation.SWIRL:
            # Swirl should never call this function so this is an error
            push_error("Invalid call to _is_valid for SWIRL orientation")
            return false
        _:
            return true


static func _get_distance_from_center(sector: Vector2i, dims: Vector2i) -> int:
    var center: Vector2 = Vector2(float(dims.x - 1) / 2.0, float(dims.y - 1) / 2.0)
    return roundi(sector.distance_to(center))


static func _get_radius_for_circle(target_rooms: int) -> int:
    # C = 2 * pi * r, so r = C / (2 * pi) where C is the number of rooms
    return roundi(target_rooms / TAU)


# Walks an Archimedean spiral outward from the center, collecting sectors in visiting order.
# Radius grows with theta rather than being fixed per orientation, so most angle-steps near
# the center revisit an already-seen sector; those are skipped until the radius grows enough
# to reach a new one. SWIRL_RADIUS_MULTIPLIER slows that growth so the spiral winds through
# multiple loops instead of exhausting its budget on the first one
static func _swirl_offsets(target_rooms: int) -> Array[Vector2i]:
    var offsets: Array[Vector2i] = []
    var seen: Dictionary = {}
    var theta: float = 0.0
    var steps: int = 0

    while offsets.size() < target_rooms and steps < MAX_SWIRL_STEPS:
        var radius: float = (theta / TAU) * SWIRL_RADIUS_MULTIPLIER
        var offset: Vector2i = Vector2i(roundi(radius * cos(theta)), roundi(radius * sin(theta)))

        # Skip sectors already reached; only a growing radius produces a genuinely new one
        if not seen.has(offset):
            seen[offset] = true
            offsets.append(offset)

        theta += SWIRL_ANGLE_STEP
        steps += 1

    return offsets


static func _swirl_extent(offsets: Array[Vector2i]) -> int:
    var extent: int = 0
    for offset: Vector2i in offsets:
        extent = maxi(extent, maxi(absi(offset.x), absi(offset.y)))
    return extent


static func _swirl_sectors(target_rooms: int) -> Array[Vector2i]:
    var offsets: Array[Vector2i] = _swirl_offsets(target_rooms)
    var extent: int = _swirl_extent(offsets)

    # Offsets are center-relative (can be negative); shift them onto real grid coordinates
    var center: Vector2i = Vector2i(extent, extent)
    var sectors: Array[Vector2i] = []
    for offset: Vector2i in offsets:
        sectors.append(offset + center)

    return sectors
