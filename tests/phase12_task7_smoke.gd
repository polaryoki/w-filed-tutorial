extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = root.get_node("GameSession")
	session.reset_run()
	var base: Dictionary = session.get_final_stat_sheet()
	var base_damage := int(base.get("damage", 0))
	var base_health := int(base.get("max_health", 0))
	var shop_scene: PackedScene = load("res://scene/shop.tscn")
	var shop := shop_scene.instantiate()
	root.add_child(shop)
	await process_frame
	session.ensure_shop_inventory()
	_expect(session.get_shop_inventory_snapshot().size() == session.SHOP_INVENTORY_SIZE, "Shop remains snapshot-driven")
	_expect(session.get_final_stat_sheet() == base, "baseline sheet is deterministic")
	_expect(session.add_relic("glass_cannon"), "baseline tradeoff relic applies")
	var relic_sheet: Dictionary = session.get_final_stat_sheet()
	_expect(int(relic_sheet.damage) > base_damage and int(relic_sheet.max_health) < base_health, "relic changes final stats")
	var player_scene: PackedScene = load("res://scene/player.tscn")
	var player: Node = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	_expect(is_equal_approx(float(player.move_speed), float(relic_sheet.move_speed)), "Player consumes final sheet")
	var weapon_system: WeaponSystem = player.weapon_system
	_expect(weapon_system != null and weapon_system.runtime_entries.size() > 0, "WeaponSystem runtime entry exists")
	if weapon_system != null and not weapon_system.runtime_entries.is_empty():
		var combat_damage := int(weapon_system.runtime_entries[0].stats.damage)
		print("Phase 12 Task 7 baseline: damage=%d max_health=%d relic_damage=%d runtime_damage=%d" % [base_damage, base_health, int(relic_sheet.damage), combat_damage])
		_expect(combat_damage == int(relic_sheet.damage), "combat output matches final damage")
	player.queue_free()
	shop.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("Phase 12 Task 7 smoke passed" if failures.is_empty() else "Phase 12 Task 7 smoke failed")
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
