extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var s = root.get_node("GameSession"); s.reset_run()
	var base: Dictionary = s.get_final_stat_sheet()
	_expect(s.add_relic("glass_cannon"), "tradeoff relic accepted")
	var glass: Dictionary = s.get_final_stat_sheet(); _expect(float(glass.damage) > float(base.damage) and float(glass.max_health) < float(base.max_health), "positive and negative modifiers resolve")
	var copy := glass.duplicate(true); copy.damage = 99999; _expect(s.get_final_stat_sheet().damage != 99999, "sheet defensive")
	_expect(not s.add_relic(""), "invalid relic rejected")
	s.reset_run(); s.add_relic("heavy_frame"); var heavy: Dictionary = s.get_final_stat_sheet(); _expect(float(heavy.max_health) > float(base.max_health) and float(heavy.move_speed) < float(base.move_speed), "alternative tradeoff build")
	for f in failures: push_error(f)
	print("Phase 12 Task 6 smoke passed" if failures.is_empty() else "Phase 12 Task 6 smoke failed"); quit(0 if failures.is_empty() else 1)
func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)
