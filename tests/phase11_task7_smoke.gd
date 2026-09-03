extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var s = root.get_node("GameSession"); var shop_scene: PackedScene = load("res://scene/shop.tscn"); s.reset_run(); s.current_coins = 100
	s.ensure_shop_inventory(); var initial: Array = s.get_shop_inventory_snapshot()
	initial[0]["locked"] = true
	var scene: Control = shop_scene.instantiate(); root.add_child(scene); await process_frame
	_expect(scene.slot_items.get_child_count() == 3, "three rows after reload")
	s.set_shop_offer_locked(0, StringName(s.get_shop_inventory_snapshot()[0].get("offer_id", "")), true)
	var persisted: Array = s.get_shop_inventory_snapshot(); scene.queue_free(); await process_frame
	var reload: Control = shop_scene.instantiate(); root.add_child(reload); await process_frame
	_expect(s.get_shop_inventory_snapshot() == persisted, "reload preserves run inventory")
	s.reset_run(); _expect(s.get_shop_inventory_snapshot().size() == 0 and s.shop_reroll_count == 0 and s.get_shop_reroll_price() == 5, "reset clears shop state")
	var after: Array = s.get_shop_inventory_snapshot(); _expect(after != persisted, "new run clears old state")
	var coins: int = s.current_coins; var bad: bool = s.try_purchase_shop_offer(-1, &"bad", null); _expect(not bad and s.current_coins == coins, "invalid purchase atomic")
	for f in failures: push_error(f)
	print("Phase 11 Task 7 smoke passed" if failures.is_empty() else "Phase 11 Task 7 smoke failed"); quit(0 if failures.is_empty() else 1)
func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)
