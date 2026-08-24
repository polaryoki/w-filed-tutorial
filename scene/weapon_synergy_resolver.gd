class_name WeaponSynergyResolver
extends RefCounted

static func resolve(weapon_configs: Array[Resource], synergies: Array[Resource]) -> Dictionary:
	var tags: Array[StringName] = []
	for weapon in weapon_configs:
		if weapon == null:
			continue
		for tag in weapon.get("tags"):
			if tag not in tags:
				tags.append(tag)
	var active: Array[StringName] = []
	var stats: Dictionary = {}
	if not weapon_configs.is_empty() and weapon_configs[0] != null:
		var weapon := weapon_configs[0]
		stats = {
			"damage": int(weapon.get("damage")),
			"projectile_count": int(weapon.get("projectile_count")),
			"fire_interval": float(weapon.get("fire_interval")),
		}
	for synergy in synergies:
		if synergy == null:
			continue
		var required_tags: Array = synergy.get("required_tags")
		var matches := true
		for required_tag in required_tags:
			if required_tag not in tags:
				matches = false
				break
		if not matches:
			continue
		active.append(synergy.get("id"))
		stats["damage"] = maxi(int(stats.get("damage", 1)) + int(synergy.get("damage_bonus")), 1)
		stats["projectile_count"] = clampi(int(stats.get("projectile_count", 1)) + int(synergy.get("projectile_count_bonus")), 1, 32)
		stats["fire_interval"] = maxf(float(stats.get("fire_interval", 0.18)) * float(synergy.get("fire_interval_multiplier")), 0.01)
	stats["active_synergies"] = active
	return stats
