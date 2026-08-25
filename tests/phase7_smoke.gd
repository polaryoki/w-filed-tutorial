extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var boss_config = load("res://resourse/config/boss_outlaw.tres")
	var scatter = load("res://resourse/weapon/weapon_scatter.tres")
	if boss_config == null or boss_config.max_health <= 0 or boss_config.reward_coins <= 0:
		failures.append("boss balance resource invalid")
	if scatter == null or scatter.projectile_count < 2 or scatter.spread_degrees <= 0.0:
		failures.append("weapon balance resource invalid")
	if not ResourceLoader.exists("res://scene/game.tscn") or not ResourceLoader.exists("res://scene/shop.tscn"):
		failures.append("core scenes missing")
	if failures.is_empty():
		print("Phase 7 smoke passed")
	else:
		for failure in failures: push_error(failure)
	quit(1 if not failures.is_empty() else 0)
