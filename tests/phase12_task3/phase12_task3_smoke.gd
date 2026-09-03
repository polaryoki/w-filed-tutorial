extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var s = root.get_node("GameSession"); s.reset_run(); s.add_relic("swift_boots")
	var p_scene: PackedScene = load("res://scene/player.tscn"); var p: Node = p_scene.instantiate(); root.add_child(p); await process_frame
	var stats: Dictionary = s.resolve_character_stats(); _expect(is_equal_approx(p.move_speed, stats.move_speed), "Player consumes final stats")
	s.reset_run(); s.current_coins = 100; s.add_relic("rapid_chamber"); var p2: Node = p_scene.instantiate(); root.add_child(p2); await process_frame
	var rapid: Dictionary = s.resolve_character_stats(); _expect(is_equal_approx(p2.fire_interval, rapid.fire_interval), "fire interval consumed once")
	var ws: WeaponSystem = p2.weapon_system; _expect(ws.runtime_entries.size() == 1, "weapon runtime exists")
	var basic_stats: Dictionary = ws.runtime_entries[0].stats; var synergy: Dictionary = s.resolve_weapon_synergies(); var expected_interval := float(rapid.fire_interval) * float(synergy.get("fire_interval_multiplier", 1.0)); _expect(is_equal_approx(float(basic_stats.fire_interval), expected_interval), "weapon uses final interval plus synergy")
	var wres: Array = s.WEAPON_OPTIONS.map(func(w): return w.resolved_stats()); _expect(wres == s.WEAPON_OPTIONS.map(func(w): return w.resolved_stats()), "WeaponConfig immutable")
	p.queue_free(); p2.queue_free(); await process_frame
	for f in failures: push_error(f)
	print("Phase 12 Task 3 smoke passed" if failures.is_empty() else "Phase 12 Task 3 smoke failed"); quit(0 if failures.is_empty() else 1)
func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)
