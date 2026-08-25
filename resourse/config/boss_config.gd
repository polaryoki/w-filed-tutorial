extends Resource
class_name BossConfig

@export var id: StringName = &"outlaw"
@export var display_name: String = "Outlaw Boss"
@export var max_health: int = 100
@export var phase_thresholds: Array[float] = [0.66, 0.33]
@export var attack_modes: Array[StringName] = [&"burst", &"charge", &"burst"]
@export var move_speed: float = 35.0
@export var attack_interval: float = 2.0
@export var telegraph_duration: float = 0.6
@export var reward_coins: int = 25
@export var spawn_round: int = 3
@export var time_limit: float = 60.0

func phase_for_health(current_health: int) -> int:
	var ratio := clampf(float(current_health) / maxf(float(max_health), 1.0), 0.0, 1.0)
	var phase := 0
	for threshold in phase_thresholds:
		if ratio <= threshold:
			phase += 1
	return mini(phase, maxi(attack_modes.size() - 1, 0))
