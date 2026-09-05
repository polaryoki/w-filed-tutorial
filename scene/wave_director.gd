extends RefCounted
class_name WaveDirector

signal spawn_requested(enemy_config: Resource)
signal progress_changed(snapshot: Dictionary)
signal wave_completed(snapshot: Dictionary)

var config: Resource
var time_left: float = 0.0
var remaining_budget: int = 0
var spawned_count: int = 0
var defeated_count: int = 0
var alive_count: int = 0
var _spawn_elapsed: float = 0.0
var _completed: bool = false
var _round_scale: float = 1.0


func configure(wave_config: Resource) -> bool:
	if wave_config == null or not wave_config.is_valid():
		return false
	config = wave_config
	_round_scale = 1.0 + maxf(float(config.wave_number - 1), 0.0) * 0.12
	time_left = config.duration
	remaining_budget = config.spawn_budget
	spawned_count = 0
	defeated_count = 0
	alive_count = 0
	_spawn_elapsed = config.spawn_interval
	_completed = false
	progress_changed.emit(snapshot())
	return true


func advance(delta: float, rng: RandomNumberGenerator = null) -> void:
	if config == null or _completed or delta <= 0.0:
		return
	time_left = maxf(time_left - delta, 0.0)
	_spawn_elapsed += delta
	var interval := maxf(float(config.spawn_interval) / (1.0 + maxf(float(config.wave_number - 1), 0.0) * 0.08), 0.1)
	while _spawn_elapsed >= interval and can_spawn():
		_spawn_elapsed -= interval
		var enemy_config := pick_enemy(rng)
		if enemy_config == null:
			break
		spawn_requested.emit(enemy_config)
		# The budget is committed only after Game confirms construction.
		break
	progress_changed.emit(snapshot())
	if time_left <= 0.0:
		_completed = true
		wave_completed.emit(snapshot())


func can_spawn() -> bool:
	return config != null and not _completed and alive_count < config.simultaneous_cap


func notify_enemy_spawned() -> bool:
	if not can_spawn():
		return false
	remaining_budget -= 1
	spawned_count += 1
	alive_count += 1
	progress_changed.emit(snapshot())
	return true


func notify_enemy_defeated() -> bool:
	if alive_count <= 0:
		return false
	alive_count -= 1
	defeated_count += 1
	progress_changed.emit(snapshot())
	return true


func pick_enemy(rng: RandomNumberGenerator = null) -> Resource:
	if config == null or config.enemy_entries.is_empty():
		return null
	var total_weight := 0.0
	for entry in config.enemy_entries:
		var enemy: Resource = entry.get("enemy_config")
		var threat := float(entry.get("threat", 0.0))
		if threat <= 0.0 and enemy != null: threat = float(enemy.get("enemy_type"))
		total_weight += float(entry.get("weight", 0.0)) * (1.0 + maxf(float(config.wave_number - 1), 0.0) * 0.15 * threat)
	if total_weight <= 0.0:
		return null
	var roll := (rng.randf() if rng != null else randf()) * total_weight
	for entry in config.enemy_entries:
		var enemy: Resource = entry.get("enemy_config")
		var threat := float(entry.get("threat", 0.0))
		if threat <= 0.0 and enemy != null: threat = float(enemy.get("enemy_type"))
		roll -= float(entry.get("weight", 0.0)) * (1.0 + maxf(float(config.wave_number - 1), 0.0) * 0.15 * threat)
		if roll <= 0.0:
			return entry.get("enemy_config") as Resource
	return config.enemy_entries.back().get("enemy_config") as Resource


func snapshot() -> Dictionary:
	return {
		"wave_number": config.wave_number if config != null else 0,
		"time_left": time_left,
		"remaining_budget": remaining_budget,
		"spawned_count": spawned_count,
		"defeated_count": defeated_count,
		"alive_count": alive_count,
		"completed": _completed,
	}
