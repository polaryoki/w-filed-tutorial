class_name WeaponConfig
extends Resource

@export var id: StringName = &"basic"
@export var display_name: String = "Basic Weapon"
@export_range(1, 999, 1) var damage: int = 1
@export_range(0.01, 10.0, 0.01) var fire_interval: float = 0.18
@export_range(1, 32, 1) var projectile_count: int = 1
@export_range(0.0, 180.0, 0.1) var spread_degrees: float = 0.0
@export_range(1.0, 2000.0, 1.0) var projectile_speed: float = 320.0
@export_range(1.0, 2000.0, 1.0) var range: float = 640.0
@export_range(1, 32, 1) var piercing: int = 1
@export var tags: Array[StringName] = []
@export_range(1, 99, 1) var upgrade_level: int = 1

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
		"upgrade_level": maxi(upgrade_level, 1),
	}
