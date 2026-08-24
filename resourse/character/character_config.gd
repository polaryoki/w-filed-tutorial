class_name CharacterConfig
extends Resource

@export_group("Identity")
@export var id: StringName = &"gunslinger"
@export var display_name: String = "Gunslinger"
@export_multiline var description: String = "A balanced starter character."

@export_group("Base Attributes")
@export_range(1, 999, 1, "or_greater") var base_health: int = 5
@export_range(1.0, 1000.0, 0.1, "or_greater") var move_speed: float = 120.0
@export_range(0.01, 10.0, 0.01, "or_greater") var fire_interval: float = 0.18
@export_range(0, 999, 1, "or_greater") var damage: int = 1
@export_range(1, 32, 1, "or_greater") var projectile_count: int = 1
@export_range(1.0, 512.0, 0.1, "or_greater") var pickup_range: float = 48.0
@export_range(0.0, 1.0, 0.01) var luck: float = 0.0
@export_range(0, 999, 1, "or_greater") var armor: int = 0
@export_range(0.0, 1.0, 0.01) var critical_chance: float = 0.0

@export_group("Existing Player Defaults")
@export_range(0.0, 10.0, 0.01, "or_greater") var invincibility_duration: float = 1.0
@export_range(0.0, 256.0, 0.1, "or_greater") var bullet_spawn_distance: float = 18.0

@export_group("Run Identity")
@export var starting_weapon: StringName = &"basic"
@export var passive: StringName = &"steady_hand"


func to_base_stats() -> Dictionary:
	return {
		"character_id": id,
		"display_name": display_name,
		"description": description,
		"max_health": base_health,
		"move_speed": move_speed,
		"fire_interval": fire_interval,
		"damage": damage,
		"projectile_count": projectile_count,
		"pickup_range": pickup_range,
		"luck": luck,
		"armor": armor,
		"critical_chance": critical_chance,
		"invincibility_duration": invincibility_duration,
		"bullet_spawn_distance": bullet_spawn_distance,
		"starting_weapon": starting_weapon,
		"passive": passive,
		"starting_coins": 0,
	}
