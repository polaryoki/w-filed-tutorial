extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var s = root.get_node("GameSession"); s.reset_run()
	for id in s.STAT_IDS: _expect(s.is_valid_stat_id(id), "valid stat %s" % id); _expect(s.get_stat_bounds(id).y >= s.get_stat_bounds(id).x, "bounds %s" % id)
	_expect(not s.is_valid_stat_id(&"not_a_stat"), "invalid stat rejected")
	var flat := {"stat_id": &"damage", "operation": &"flat", "value": -5.0, "source_id": &"test", "source_type": &"upgrade"}
	var pct := {"stat_id": &"damage", "operation": &"percent", "value": 0.2, "source_id": &"test_pct", "source_type": &"relic"}
	_expect(s.validate_modifier(flat) and s.validate_modifier(pct), "modifiers valid")
	_expect(not s.validate_modifier({"stat_id": &"damage", "operation": &"multiply", "value": 1.0, "source_id": &"x", "source_type": &"upgrade"}), "operation rejected")
	var sheet: Dictionary = s.get_final_stat_sheet(); var copy := sheet.duplicate(true); copy["damage"] = 999999.0
	_expect(s.get_final_stat_sheet().get("damage") != 999999.0, "defensive sheet")
	_expect(is_equal_approx((10.0 + 5.0) * 1.2, 18.0), "flat then percent example")
	_expect(is_equal_approx(0.2 / 1.25, 0.16), "attack speed semantic example")
	var before: Dictionary = s.get_final_stat_sheet(); s.reset_run(); _expect(s.get_final_stat_sheet() != before or s.get_final_stat_sheet().get("damage") == before.get("damage"), "reset readable")
	for f in failures: push_error(f)
	print("Phase 12 Task 1 smoke passed" if failures.is_empty() else "Phase 12 Task 1 smoke failed"); quit(0 if failures.is_empty() else 1)
func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)
