extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_root().get_node_or_null("GameSession")
	if session == null:
		failures.append("GameSession autoload missing")
	else:
		session.reset_run()
		session.current_coins = 30
	if not session.equip_weapon(&"scatter"):
		failures.append("weapon offer could not be equipped")
	if not session.upgrade_weapon(&"basic", 10):
		failures.append("weapon upgrade failed")
	if session.get_weapon_upgrade_level(&"basic") != 2:
		failures.append("weapon upgrade level incorrect")
	if not session.reroll_shop(5) or session.shop_reroll_count != 1:
		failures.append("reroll transaction failed")
	if session.current_coins != 15:
		failures.append("shop transactions deducted incorrect amount")
	if failures.is_empty():
		print("Phase 6 smoke passed")
	else:
		for failure in failures: push_error(failure)
	quit(1 if not failures.is_empty() else 0)
