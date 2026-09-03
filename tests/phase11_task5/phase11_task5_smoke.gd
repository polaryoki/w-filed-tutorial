extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var s = get_root().get_node("GameSession")
	s.reset_run(); s.current_coins = 100
	var inv: Array[Dictionary] = [
		{"slot_index": 0, "offer_id": &"weapon:scatter", "offer_type": &"weapon", "content_id": &"scatter", "price": 12, "locked": false, "rarity": 0, "weight": 1.0},
		{"slot_index": 1, "offer_id": &"relic:rapid_chamber", "offer_type": &"relic", "content_id": &"rapid_chamber", "price": 8, "locked": true, "rarity": 0, "weight": 1.0},
		{}
	]
	s.shop_inventory = inv
	var before: Array[Dictionary] = s.get_shop_inventory_snapshot()
	_expect(s.try_purchase_shop_offer(0, &"weapon:scatter"), "weapon purchase")
	_expect(s.current_coins == 88 and &"scatter" in s.equipped_weapon_ids and s.get_weapon_upgrade_level(&"scatter") == 1, "weapon state")
	_expect(s.shop_inventory[1] == before[1] and not s.shop_inventory[0].get("locked", false), "other slot and refill lock")
	var snap: Array[Dictionary] = s.get_shop_inventory_snapshot(); snap[1] = {}; _expect(not s.shop_inventory[1].is_empty(), "defensive snapshot")
	var state := [s.current_coins, s.get_shop_inventory_snapshot(), s.get_equipped_weapon_ids(), s.get_weapon_upgrade_levels(), s.owned_relics.duplicate(), s.shop_reroll_count]
	_expect(not s.try_purchase_shop_offer(1, &"bad"), "stale rejection"); _expect(state == [s.current_coins, s.get_shop_inventory_snapshot(), s.get_equipped_weapon_ids(), s.get_weapon_upgrade_levels(), s.owned_relics, s.shop_reroll_count], "stale no-op")
	var relic_id: StringName = s.shop_inventory[1].get("offer_id", &"")
	_expect(s.try_purchase_shop_offer(1, relic_id), "locked relic purchase")
	_expect(s.current_coins == 80 and s.has_relic("rapid_chamber"), "relic state")
	var duplicate_slot := -1
	for i in s.shop_inventory.size():
		if not s.shop_inventory[i].is_empty() and s.shop_inventory[i].get("offer_type") == &"weapon" and s.shop_inventory[i].get("content_id") == &"scatter": duplicate_slot = i
	if duplicate_slot >= 0:
		var oid: StringName = s.shop_inventory[duplicate_slot].offer_id; var level: int = s.get_weapon_upgrade_level(&"scatter"); s.current_coins = 100
		_expect(s.try_purchase_shop_offer(duplicate_slot, oid), "duplicate upgrade"); _expect(s.get_weapon_upgrade_level(&"scatter") == level + 1 and s.equipped_weapon_ids.count(&"scatter") == 1, "duplicate semantics")
	s.reset_run(); _expect(s.shop_inventory.is_empty() and s.owned_relics.is_empty() and s.get_weapon_upgrade_levels() == {&"basic": 1}, "reset state")
	_finish()

func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)

func _finish() -> void:
	for f in failures: push_error(f)
	print("Phase 11 Task 5 smoke passed" if failures.is_empty() else "Phase 11 Task 5 smoke failed")
	quit(0 if failures.is_empty() else 1)
