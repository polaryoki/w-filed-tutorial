class_name WeaponConfig
extends Resource

enum ShopRarity {
	COMMON,
	UNCOMMON,
	RARE,
}

@export var id: StringName = &"basic"
@export var display_name: String = "Basic Weapon"
@export var rarity: ShopRarity = ShopRarity.COMMON
@export_range(0.01, 1000.0, 0.01, "or_greater") var shop_weight: float = 1.0
@export_range(1, 999, 1) var damage: int = 1
@export_range(0.01, 10.0, 0.01) var fire_interval: float = 0.18
@export_range(1, 32, 1) var projectile_count: int = 1
@export_range(0.0, 180.0, 0.1) var spread_degrees: float = 0.0
@export_range(1.0, 2000.0, 1.0) var projectile_speed: float = 320.0
@export_range(1.0, 2000.0, 1.0) var range: float = 640.0
@export_range(1, 32, 1) var piercing: int = 1
@export var tags: Array[StringName] = []
# Legacy static field retained for Resource compatibility. Current-run levels
# are owned by GameSession and are supplied explicitly to the resolver below.
@export_range(1, 99, 1) var upgrade_level: int = 1
@export_range(0, 999, 1) var damage_per_level: int = 1
@export_range(0.01, 1.0, 0.01) var fire_interval_per_level: float = 0.92

func resolved_stats() -> Dictionary:
	return {
		"id": id,
		"damage": maxi(damage, 1),
		"fire_interval": maxf(fire_interval, 0.01),
		"projectile_count": clampi(projectile_count, 1, 32),
		"spread_degrees": clampf(spread_degrees, 0.0, 180.0),
		"projectile_speed": maxf(projectile_speed, 1.0),
		"range": maxf(range, 1.0),
		"piercing": clampi(piercing, 1, 32),
		"tags": tags.duplicate(),
		"upgrade_level": 1,
	}

func resolved_stats_for_level(level: int, maximum_level: int) -> Dictionary:
	if maximum_level < 1:
		push_error("Cannot resolve weapon stats with an invalid maximum level: %d" % maximum_level)
		return {}
	if level < 1 or level > maximum_level:
		push_error("Cannot resolve weapon %s at invalid level %d" % [id, level])
		return {}
	if damage_per_level < 0:
		push_error("Weapon %s has invalid damage growth: %d" % [id, damage_per_level])
		return {}
	if fire_interval_per_level <= 0.0 or fire_interval_per_level > 1.0:
		push_error("Weapon %s has invalid fire interval growth: %s" % [id, fire_interval_per_level])
		return {}

	var stats := resolved_stats()
	stats["upgrade_level"] = level
	stats["damage"] = maxi(int(stats["damage"]) + damage_per_level * (level - 1), 1)
	stats["fire_interval"] = maxf(
		float(stats["fire_interval"]) * pow(fire_interval_per_level, level - 1),
		0.01
	)
	return stats
