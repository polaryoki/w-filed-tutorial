class_name WeaponSystem
extends Node

const BULLET_SCENE := preload("res://scene/bullet.tscn")

var config: WeaponConfig
var active_synergy_ids: Array[StringName] = []

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

func get_fire_interval() -> float:
	return config.resolved_stats()["fire_interval"] if config != null else 0.18

func fire(origin: Vector2, direction: Vector2, parent: Node, can_spawn: Callable) -> int:
	if config == null or parent == null or direction == Vector2.ZERO:
		return 0
	var stats := config.resolved_stats()
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
		parent.add_child(bullet)
		bullet.global_position = origin
		spawned += 1
	return spawned
