extends Resource
class_name WaveConfig

@export var id: StringName = &"wave"
@export_range(1, 999, 1, "or_greater") var wave_number: int = 1
@export_range(0.1, 3600.0, 0.1, "or_greater") var duration: float = 30.0
@export_range(0, 10000, 1, "or_greater") var spawn_budget: int = 10
@export_range(0.05, 60.0, 0.05, "or_greater") var spawn_interval: float = 1.0
@export_range(1, 1000, 1, "or_greater") var simultaneous_cap: int = 10
@export var enemy_entries: Array[Dictionary] = []
@export_range(0, 9999, 1, "or_greater") var completion_coins: int = 0
@export var boss_config: Resource


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("wave id must not be empty")
	if wave_number < 1:
		errors.append("wave number must be at least 1")
	if duration <= 0.0:
		errors.append("duration must be positive")
	if spawn_budget < 0:
		errors.append("spawn budget must not be negative")
	if spawn_interval <= 0.0:
		errors.append("spawn interval must be positive")
	if simultaneous_cap < 1:
		errors.append("simultaneous cap must be at least 1")
	if completion_coins < 0:
		errors.append("completion coins must not be negative")
	if spawn_budget > 0 and enemy_entries.is_empty():
		errors.append("a wave with spawn budget needs enemy entries")
	for index in enemy_entries.size():
		var entry := enemy_entries[index]
		if entry.get("enemy_config") == null:
			errors.append("enemy entry %d has no config" % index)
		if float(entry.get("weight", 0.0)) <= 0.0:
			errors.append("enemy entry %d weight must be positive" % index)
	return errors


func is_valid() -> bool:
	return validation_errors().is_empty()
