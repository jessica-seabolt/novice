class_name Dice extends RefCounted
## Static class to handle rolling


static func roll_damage(power: int, attack: int, defense: int, rng: RandomNumberGenerator) -> int:
    return maxi(1, Dice.roll_exploding(power, rng) + attack - defense)


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
