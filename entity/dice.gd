class_name Dice extends RefCounted
## Static class to handle rolling


## Rolls damage with exploding dice
static func roll_damage(power: int, attack: int, defense: int, rng: RandomNumberGenerator) -> int:
    return maxi(1, Dice.roll_exploding(power, rng) + attack - defense)


## Rolls dice with exploding 6s
static func roll_exploding(count: int, rng: RandomNumberGenerator) -> int:
    var total: int = 0
    var explosions: int = 0

    for _die: int in range(count):
        var result: int = rng.randi_range(1, 6)
        total += result

        if result == 6:
            explosions += 1

    if explosions > 0:
        total += roll_exploding(explosions, rng)

    return total


## An index into weights, picked in proportion to its weight
static func pick_weighted(weights: Array[int], rng: RandomNumberGenerator) -> int:
    var total: int = 0
    for weight: int in weights:
        total += weight
    var roll: int = rng.randi_range(1, total)
    for i: int in range(weights.size()):
        roll -= weights[i]
        if roll <= 0:
            return i
    return weights.size() - 1
