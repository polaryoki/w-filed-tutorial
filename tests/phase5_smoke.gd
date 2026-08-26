extends SceneTree

const BossConfigScript = preload("res://resourse/config/boss_config.gd")
const BossScript = preload("res://scene/boss.gd")

var failures: Array[String] = []
var defeated_count := 0

func _initialize() -> void:
	var config = load("res://resourse/config/boss_outlaw.tres")
	if config == null: failures.append("BossConfig resource failed to load")
	else:
		if config.phase_for_health(70) != 0: failures.append("phase 1 threshold incorrect")
		if config.phase_for_health(50) != 1: failures.append("phase 2 threshold incorrect")
		if config.phase_for_health(10) != 2: failures.append("phase 3 threshold incorrect")
	var boss = BossScript.new()
	get_root().add_child(boss)
	boss.call("setup", config)
	boss.defeated.connect(func(_reward: int): defeated_count += 1)
	boss.call("apply_damage", 40)
	if boss.current_phase != 1: failures.append("damage did not advance boss phase")
	boss.call("apply_damage", 60)
	boss.call("apply_damage", 1)
	if defeated_count != 1: failures.append("boss defeat reward must emit once")
	if failures.is_empty(): print("Phase 5 smoke passed")
	else:
		for failure in failures: push_error(failure)
	quit(1 if not failures.is_empty() else 0)
