class_name WeaponSystem
extends Node

const BULLET_SCENE := preload("res://scene/bullet.tscn")

var config: WeaponConfig
var active_synergy_ids: Array[StringName] = []
var runtime_damage: int = -1
var runtime_entries: Array[Dictionary] = []
var character_damage_bonus: int = 0
var character_fire_interval_multiplier: float = 1.0
var character_projectile_bonus: int = 0

func apply_synergy_stats(stats: Dictionary) -> void:
	active_synergy_ids.clear()
	for synergy_id in stats.get("active_synergies", []):
		active_synergy_ids.append(synergy_id)
	config = config.duplicate(true) if config != null else null
	if config == null:
		return
	config.damage = int(stats.get("damage", config.damage))
	config.projectile_count = int(stats.get("projectile_count", config.projectile_count))
	config.fire_interval = float(stats.get("fire_interval", config.fire_interval))

func setup(weapon_config: WeaponConfig) -> void:
	config = weapon_config
	setup_loadout([weapon_config], {weapon_config.id: 1} if weapon_config != null else {})

func setup_loadout(weapon_configs: Array[WeaponConfig], levels: Dictionary, modifiers: Dictionary = {}) -> void:
	runtime_entries.clear()
	character_damage_bonus = int(modifiers.get("damage_bonus", 0))
	character_fire_interval_multiplier = maxf(float(modifiers.get("fire_interval_multiplier", 1.0)), 0.01)
	character_projectile_bonus = int(modifiers.get("projectile_count_bonus", 0))
	active_synergy_ids.clear()
	for id in modifiers.get("active_synergies", []): active_synergy_ids.append(StringName(id))
	var seen: Dictionary = {}
	for weapon_config in weapon_configs:
		if weapon_config == null or weapon_config.id == &"" or seen.has(weapon_config.id):
			continue
		if not levels.has(weapon_config.id):
			continue
		var level := int(levels[weapon_config.id])
		var stats := _resolve_runtime_stats(weapon_config, level)
		if stats.is_empty():
			continue
		seen[weapon_config.id] = true
		runtime_entries.append({"weapon_id": weapon_config.id, "config": weapon_config, "level": level, "cooldown_left": 0.0, "stats": stats})
	config = runtime_entries[0]["config"] if not runtime_entries.is_empty() else null

func refresh_modifiers(modifiers: Dictionary) -> void:
	character_damage_bonus = int(modifiers.get("damage_bonus", character_damage_bonus))
	character_fire_interval_multiplier = maxf(float(modifiers.get("fire_interval_multiplier", character_fire_interval_multiplier)), 0.01)
	character_projectile_bonus = int(modifiers.get("projectile_count_bonus", character_projectile_bonus))
	for entry in runtime_entries:
		entry["stats"] = _resolve_runtime_stats(entry["config"], entry["level"])

func advance_and_fire(delta: float, origin: Vector2, direction: Vector2, parent: Node, can_spawn: Callable) -> int:
	var total := 0
	for entry in runtime_entries:
		entry["cooldown_left"] = maxf(float(entry["cooldown_left"]) - maxf(delta, 0.0), 0.0)
		if direction == Vector2.ZERO or float(entry["cooldown_left"]) > 0.0: continue
		var spawned := _fire_stats(entry["stats"], origin, direction, parent, can_spawn)
		if spawned > 0:
			entry["cooldown_left"] = float(entry["stats"]["fire_interval"])
			total += spawned
	return total

func _resolve_runtime_stats(weapon_config: WeaponConfig, level: int) -> Dictionary:
	if weapon_config == null:
		return {}
	var stats := weapon_config.resolved_stats_for_level(level, GameSession.MAX_WEAPON_LEVEL)
	if stats.is_empty():
		return {}
	stats["damage"] = maxi(int(stats["damage"]) + character_damage_bonus, 1)
	stats["fire_interval"] = maxf(float(stats["fire_interval"]) * character_fire_interval_multiplier, 0.01)
	stats["projectile_count"] = clampi(int(stats["projectile_count"]) + character_projectile_bonus, 1, 32)
	return stats

func set_runtime_damage(value: int) -> void:
	runtime_damage = maxi(value, 1)

func get_fire_interval() -> float:
	return float(runtime_entries[0]["stats"]["fire_interval"]) if not runtime_entries.is_empty() else 0.18

func fire(origin: Vector2, direction: Vector2, parent: Node, can_spawn: Callable) -> int:
	if parent == null or direction == Vector2.ZERO or runtime_entries.is_empty():
		return 0
	var stats: Dictionary = runtime_entries[0]["stats"].duplicate(true)
	if runtime_damage > 0:
		stats["damage"] = runtime_damage
	return _fire_stats(stats, origin, direction, parent, can_spawn)

func _fire_stats(stats: Dictionary, origin: Vector2, direction: Vector2, parent: Node, can_spawn: Callable) -> int:
	if parent == null or direction == Vector2.ZERO: return 0
	var count := int(stats["projectile_count"])
	var spread := deg_to_rad(float(stats["spread_degrees"]))
	var spawned := 0
	for index in count:
		var offset := 0.0 if count == 1 else lerpf(-spread, spread, float(index) / float(count - 1))
		var shot_direction := direction.normalized().rotated(offset)
		if not can_spawn.call(shot_direction):
			continue
		var bullet := BULLET_SCENE.instantiate() as Bullet
		if bullet == null:
			continue
		bullet.top_level = true
		bullet.setup(shot_direction)
		bullet.setup_weapon_stats(int(stats["damage"]), int(stats["piercing"]), float(stats["projectile_speed"]), float(stats["range"]))
		bullet.set_meta("weapon_id", stats["id"])
		parent.add_child(bullet)
		bullet.global_position = origin
		spawned += 1
	return spawned
