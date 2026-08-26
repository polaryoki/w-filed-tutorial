extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_root().get_node_or_null("GameSession")
	if session == null:
		failures.append("GameSession autoload missing")
		_finish()
		return
	session.reset_run()
	_expect(session.current_level == 1 and session.current_xp == 0, "new run XP state must reset")
	_expect(session.xp_to_next_level == 5 and session.pending_level_ups == 0, "new run threshold must reset")
	_expect(session.add_experience(4) == 0 and session.current_xp == 4, "XP below threshold must accumulate")
	_expect(session.add_experience(2) == 1, "XP crossing threshold must level once")
	_expect(session.current_level == 2 and session.current_xp == 1, "overflow XP must be retained")

	session.reset_run()
	_expect(session.add_experience(30) == 3, "large XP grant must support consecutive levels")
	_expect(session.current_level == 4 and session.current_xp == 6, "multi-level overflow must be exact")
	_expect(session.pending_level_ups == 3 and session.xp_to_next_level == 14, "multi-level pending state must be saved")
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	var options: Array[Resource] = session.roll_level_up_options(rng)
	_expect(options.size() == 3, "level-up must offer three options")
	var ids: Array[StringName] = []
	for option in options:
		ids.append(StringName(option.get("id")))
	_expect(ids[0] != ids[1] and ids[0] != ids[2] and ids[1] != ids[2], "level-up options must be distinct")
	var before: Dictionary = session.resolve_character_stats()
	var applied = session.apply_level_upgrade(ids[0])
	var after: Dictionary = session.resolve_character_stats()
	_expect(applied != null and session.pending_level_ups == 2, "one selection must consume one pending level")
	_expect(before != after, "selected upgrade must alter resolved run stats")
	_expect(session.apply_level_upgrade(ids[1]) == null, "stale offers must not be selectable twice")

	session.reset_run()
	_expect(session.current_level == 1 and session.current_xp == 0, "reset after progression must clear XP and level")
	_expect(session.level_upgrade_stacks.is_empty(), "reset must clear selected upgrades")
	_expect(ResourceLoader.exists("res://scene/experience_pickup.tscn"), "XP pickup scene missing")
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("Phase 8 smoke passed")
	else:
		for failure in failures:
			push_error(failure)
	quit(1 if not failures.is_empty() else 0)
