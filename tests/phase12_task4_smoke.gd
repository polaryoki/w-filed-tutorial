extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var s = root.get_node("GameSession"); s.reset_run()
	var base: Dictionary = s.get_final_stat_sheet()
	s.pending_level_ups = 1; s.current_upgrade_offer_ids.clear(); s.current_upgrade_offer_ids.append(&"move_speed")
	_expect(s.apply_level_upgrade(&"move_speed") != null, "XP upgrade applies")
	var upgraded: Dictionary = s.get_final_stat_sheet(); _expect(float(upgraded.move_speed) > float(base.move_speed), "upgrade changes final sheet")
	s.reset_run(); s.current_coins = 100; s.ensure_shop_inventory()
	var relic_slot := -1
	for i in s.shop_inventory.size():
		if not s.shop_inventory[i].is_empty() and s.shop_inventory[i].offer_type == &"relic": relic_slot = i; break
	if relic_slot < 0:
		var ids: Array = s.RELIC_OPTIONS.map(func(r): return StringName(r.id)); s.shop_inventory[0] = {"slot_index":0,"offer_id":StringName("relic:%s" % ids[0]),"offer_type":&"relic","content_id":ids[0],"price":5,"locked":false}
		relic_slot = 0
	var offer_id: StringName = s.shop_inventory[relic_slot].offer_id
	var before_coins: int = s.current_coins; _expect(s.try_purchase_shop_offer(relic_slot, offer_id), "shop relic purchase applies")
	_expect(s.current_coins < before_coins and s.get_final_stat_sheet() != base, "shop relic changes final sheet")
	var coins_after: int = s.current_coins; _expect(not s.try_purchase_shop_offer(relic_slot, offer_id) and s.current_coins == coins_after, "duplicate purchase atomic")
	s.reset_run(); s.add_relic("brittle_core"); var brittle: Dictionary = s.get_final_stat_sheet(); _expect(float(brittle.move_speed) < float(base.move_speed), "negative tradeoff applies")
	for f in failures: push_error(f)
	print("Phase 12 Task 4 smoke passed" if failures.is_empty() else "Phase 12 Task 4 smoke failed"); quit(0 if failures.is_empty() else 1)
func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)
