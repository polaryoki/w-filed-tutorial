extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var s = root.get_node("GameSession"); s.reset_run(); s.current_coins = 100
	var shop_scene: PackedScene = load("res://scene/shop.tscn"); var shop: Control = shop_scene.instantiate(); root.add_child(shop); await process_frame
	var label: Label = shop.get_node("CenterContainer/PanelContainer/MarginContainer/Layout/StatSheet")
	var initial := label.text; _expect(initial.find("Build") >= 0 and initial.find("HP") >= 0, "compact stat sheet displayed")
	s.pending_level_ups = 1; s.current_upgrade_offer_ids.clear(); s.current_upgrade_offer_ids.append(&"damage"); s.apply_level_upgrade(&"damage"); shop.refresh_shop(); var upgraded := label.text; _expect(upgraded != initial and upgraded.find("DMG") >= 0, "refresh after upgrade")
	s.add_relic("swift_boots"); shop.refresh_shop(); _expect(label.text.find("swift_boots") >= 0, "refresh after relic")
	s.reset_run(); shop.refresh_shop(); _expect(label.text.find("Relics: none") >= 0 and label.text.find("Upgrades: none") >= 0, "refresh after reset")
	shop.queue_free(); await process_frame
	var shop2: Control = shop_scene.instantiate(); root.add_child(shop2); await process_frame
	_expect((shop2.get_node("CenterContainer/PanelContainer/MarginContainer/Layout/StatSheet") as Label).text.find("Build") >= 0, "reload refreshes display")
	shop2.queue_free(); await process_frame
	for f in failures: push_error(f)
	print("Phase 12 Task 5 smoke passed" if failures.is_empty() else "Phase 12 Task 5 smoke failed"); quit(0 if failures.is_empty() else 1)
func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)
