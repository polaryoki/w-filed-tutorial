class_name WeaponSynergyConfig
extends Resource

@export var id: StringName = &"kinetic_pair"
@export var display_name: String = "Kinetic Pair"
@export_multiline var description: String = "Two kinetic weapons fire faster."
@export var required_tags: Array[StringName] = [&"kinetic", &"starter"]
@export_range(0.01, 10.0, 0.01) var fire_interval_multiplier: float = 0.9
@export_range(0, 999, 1) var damage_bonus: int = 0
@export_range(0, 32, 1) var projectile_count_bonus: int = 0

func applies_to_tags(tags: Array[StringName]) -> bool:
	for required_tag in required_tags:
		if required_tag not in tags:
			return false
	return true

func apply(stats: Dictionary) -> Dictionary:
	var result := stats.duplicate(true)
	result["damage"] = maxi(int(result.get("damage", 1)) + damage_bonus, 1)
	result["projectile_count"] = clampi(int(result.get("projectile_count", 1)) + projectile_count_bonus, 1, 32)
	result["fire_interval"] = maxf(float(result.get("fire_interval", 0.18)) * fire_interval_multiplier, 0.01)
	return result
