extends SceneTree

var failures: Array[String] = []
var shop_scene: PackedScene

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var s = get_root().get_node("GameSession")
	shop_scene = load("res://scene/shop.tscn") as PackedScene
	s.reset_run(); s.current_coins = 100
	var resources_before := _capture_resources(s)
	s.shop_inventory = ([
		{"offer_id": &"weapon:basic", "offer_type": &"weapon", "content_id": &"basic", "rarity": 0, "price": s.SHOP_WEAPON_UPGRADE_PRICE, "slot_index": 0, "locked": false},
		{"offer_id": &"relic:lucky_start", "offer_type": &"relic", "content_id": &"lucky_start", "rarity": 0, "price": 8, "slot_index": 1, "locked": false}, {},
	] as Array[Dictionary])
	var scene: Control = shop_scene.instantiate(); get_root().add_child(scene); await process_frame
	_expect(scene.slot_items.get_child_count() == 3, "three slot rows")
	var snap: Array = s.get_shop_inventory_snapshot()
	_expect(scene.slot_items.get_child(0).get_child(0).text.contains("Weapon"), "weapon slot visible")
	_expect(scene.slot_items.get_child(0).get_child(0).text.contains("Lv.1"), "weapon level visible")
	_expect(scene.slot_items.get_child(0).get_child(0).text.contains("Price 10"), "weapon snapshot price visible")
	_expect(scene.slot_items.get_child(1).get_child(0).text.contains("Relic"), "relic slot visible")
	_expect(scene.slot_items.get_child(2).get_child(0).text.contains("Unavailable"), "empty slot visible")
	_expect(scene.gold_label.text == "Coins: 100", "coins label synchronized")
	var row0: Node = scene.slot_items.get_child(0); row0.get_child(2).pressed.emit(); await process_frame
	_expect(bool(s.get_shop_inventory_snapshot()[0].locked), "lock operation updates GameSession")
	_expect(scene.slot_items.get_child(0).get_child(2).text == "Unlock", "lock operation updates UI")
	scene.slot_items.get_child(0).get_child(2).pressed.emit(); await process_frame
	_expect(not bool(s.get_shop_inventory_snapshot()[0].locked), "unlock operation updates GameSession")
	var old_offer_id: StringName = snap[0].offer_id; var coins_before: int = s.current_coins
	var old_snapshot: Array = s.get_shop_inventory_snapshot()
	scene.slot_items.get_child(0).get_child(1).pressed.emit(); await process_frame
	var after_purchase: Array = s.get_shop_inventory_snapshot()
	_expect(s.current_coins == coins_before - 10, "purchase deducts snapshot price")
	_expect(s.get_weapon_upgrade_level(&"basic") == 2, "weapon purchase upgrades level")
	_expect(after_purchase[0].get("offer_id", &"") != old_offer_id or after_purchase[0].is_empty(), "purchase refills slot")
	_expect(scene.gold_label.text == "Coins: 90", "purchase refreshes coins UI")
	var stale_before: Array = s.get_shop_inventory_snapshot(); var stale_coins: int = s.current_coins
	scene._on_purchase_pressed(1, &"relic:stale")
	_expect(s.get_shop_inventory_snapshot() == stale_before and s.current_coins == stale_coins, "stale offer purchase is no-op")
	s.current_coins = 0; var failed_before: Array = s.get_shop_inventory_snapshot()
	scene._on_purchase_pressed(1, StringName(failed_before[1].get("offer_id", &"")))
	_expect(s.get_shop_inventory_snapshot() == failed_before and s.current_coins == 0, "purchase failure is no-op")
	s.shop_inventory = old_snapshot.duplicate(true) as Array[Dictionary]; s.shop_reroll_count = 0; s.current_coins = 100; scene._refresh_shop()
	scene.reroll_button.pressed.emit(); await process_frame
	_expect(s.current_coins == 95 and s.shop_reroll_count == 1, "reroll success deducts snapshot price")
	_expect(scene.reroll_button.text == "Reroll 7", "reroll price refreshes")
	s.current_coins = 0; var reroll_fail: Array = s.get_shop_inventory_snapshot(); scene.reroll_button.pressed.emit(); await process_frame
	_expect(s.get_shop_inventory_snapshot() == reroll_fail and s.current_coins == 0, "reroll failure is no-op")
	var defensive: Array = s.get_shop_inventory_snapshot(); defensive[0]["price"] = 999
	_expect(s.get_shop_inventory_snapshot()[0].get("price") != 999, "snapshot is defensive")
	_expect(resources_before == _capture_resources(s), "shop operations do not mutate resources")
	# Locked offers remain purchasable through the same slot transaction path.
	s.reset_run(); s.current_coins = 100
	s.shop_inventory = ([{}, {"offer_id": &"relic:rapid_chamber", "offer_type": &"relic", "content_id": &"rapid_chamber", "rarity": 0, "price": 8, "slot_index": 1, "locked": true}, {}] as Array[Dictionary])
	scene.refresh_shop(); await process_frame
	scene.slot_items.get_child(1).get_child(1).pressed.emit(); await process_frame
	_expect(s.has_relic("rapid_chamber") and s.current_coins == 92, "locked offer purchase")
	scene.queue_free(); await process_frame
	var reloaded: Control = shop_scene.instantiate(); get_root().add_child(reloaded); await process_frame
	_expect(reloaded.slot_items.get_child_count() == 3, "scene reload preserves three slots")
	_expect(reloaded.gold_label.text == "Coins: 92", "scene reload reads current coins")
	var round_before: int = s.current_round
	_expect(reloaded.continue_button != null, "Continue control exists")
	if reloaded.continue_button != null:
		reloaded.continue_button.pressed.emit()
		_expect(s.current_round == round_before + 1, "Continue advances round")
	_finish()

func _capture_resources(s: Node) -> Array:
	var out: Array = []
	for w in s.WEAPON_OPTIONS: out.append({"id": w.id, "stats": w.resolved_stats(), "rarity": w.rarity, "weight": w.shop_weight})
	for r in s.RELIC_OPTIONS: out.append({"id": r.id, "price": r.price, "rarity": r.rarity, "weight": r.shop_weight, "effect_type": r.effect_type, "effect_value": r.effect_value})
	return out

func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)

func _finish() -> void:
	for f in failures: push_error(f)
	print("Phase 11 Task 6 smoke passed" if failures.is_empty() else "Phase 11 Task 6 smoke failed")
	quit(0 if failures.is_empty() else 1)
