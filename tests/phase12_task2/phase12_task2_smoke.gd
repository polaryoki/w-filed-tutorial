extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var s = root.get_node("GameSession"); s.reset_run()
	var mods: Array[Dictionary] = [
		{"stat_id": &"damage", "operation": &"flat", "value": 5.0, "source_id": &"z_flat", "source_type": &"upgrade"},
		{"stat_id": &"damage", "operation": &"flat", "value": -2.0, "source_id": &"a_flat", "source_type": &"relic"},
		{"stat_id": &"damage", "operation": &"percent", "value": 0.2, "source_id": &"b_pct", "source_type": &"upgrade"},
		{"stat_id": &"damage", "operation": &"percent", "value": -0.1, "source_id": &"c_pct", "source_type": &"relic"},
	]
	var out: Dictionary = s.resolve_stat_sheet({"damage": 10.0}, mods)
	_expect(is_equal_approx(float(out.damage), 14.04), "flat percent multiplicative")
	_expect(s.resolve_stat_sheet({"move_speed": 1.0}, [{"stat_id": &"move_speed", "operation": &"percent", "value": -2.0, "source_id": &"x", "source_type": &"relic"}]).move_speed >= 1.0, "bounds clamp")
	var a: Dictionary = s.get_final_stat_sheet(); var b: Dictionary = s.get_final_stat_sheet(); _expect(a == b, "deterministic repeated resolution")
	var copy := a.duplicate(true); copy["damage"] = 999999; _expect(s.get_final_stat_sheet().get("damage") != 999999, "defensive")
	var old_resources: Array = s.WEAPON_OPTIONS.map(func(w): return w.resolved_stats()); s.add_relic("rapid_chamber"); var changed: Dictionary = s.resolve_character_stats(); _expect(changed.fire_interval < a.fire_interval, "relic invalidates cache")
	_expect(old_resources == s.WEAPON_OPTIONS.map(func(w): return w.resolved_stats()), "resources immutable")
	s.reset_run(); var base: Dictionary = s.resolve_character_stats(); s.add_relic("swift_boots"); var boots: Dictionary = s.resolve_character_stats()
	_expect(is_equal_approx(float(boots.move_speed), float(base.move_speed) * 1.15), "swift boots applied once")
	s.reset_run(); var fire_base: Dictionary = s.resolve_character_stats(); s.add_relic("rapid_chamber"); var rapid: Dictionary = s.resolve_character_stats()
	_expect(is_equal_approx(float(rapid.fire_interval), float(fire_base.fire_interval) * 0.9), "rapid chamber applied once")
	for f in failures: push_error(f)
	print("Phase 12 Task 2 smoke passed" if failures.is_empty() else "Phase 12 Task 2 smoke failed"); quit(0 if failures.is_empty() else 1)
func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)
