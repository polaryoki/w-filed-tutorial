extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_root().get_node("GameSession")
	session.reset_run()
	_expect(session.get_equipped_weapon_ids() == [&"basic"], "reset restores default character starting weapon")
	_expect(session.get_weapon_upgrade_level(&"basic") == 1, "starter level is one")
	_expect(session.get_equipped_weapon_ids().size() <= session.MAX_WEAPON_SLOTS, "loadout respects slot cap")

	session.current_coins = 100
	_expect(session.try_purchase_weapon(&"scatter", 12), "valid purchase succeeds")
	_expect(session.current_coins == 88, "purchase deducts exact price")
	_expect(session.get_equipped_weapon_ids() == [&"basic", &"scatter"], "purchase preserves insertion order")
	_expect(session.get_weapon_upgrade_level(&"scatter") == 1, "purchased weapon starts at level one")

	var before_ids: Array[StringName] = session.get_equipped_weapon_ids()
	var before_levels: Dictionary = session.get_weapon_upgrade_levels()
	var before_coins: int = session.current_coins
	_expect(not session.try_purchase_weapon(&"scatter", 12), "duplicate purchase fails")
	_expect(session.current_coins == before_coins and session.get_equipped_weapon_ids() == before_ids and session.get_weapon_upgrade_levels() == before_levels, "duplicate purchase is atomic")
	_expect(not session.try_purchase_weapon(&"unknown", 12), "unknown purchase fails")
	_expect(session.current_coins == before_coins and session.get_equipped_weapon_ids() == before_ids, "unknown purchase is atomic")
	_expect(not session.try_purchase_weapon(&"arc", 0), "non-positive purchase price fails")
	session.current_coins = 0
	_expect(not session.try_purchase_weapon(&"arc", 12), "underfunded purchase fails")
	_expect(session.get_equipped_weapon_ids() == before_ids and session.get_weapon_upgrade_levels() == before_levels, "underfunded purchase is atomic")

	session.current_coins = 100
	_expect(session.try_purchase_weapon(&"arc", 12), "third weapon purchase succeeds")
	var full_ids: Array[StringName] = session.get_equipped_weapon_ids()
	var full_coins: int = session.current_coins
	_expect(not session.try_purchase_weapon(&"driver", 12), "full loadout purchase fails")
	_expect(session.current_coins == full_coins and session.get_equipped_weapon_ids() == full_ids, "full loadout purchase is atomic")

	_expect(session.try_upgrade_weapon(&"scatter", 10), "equipped weapon upgrade succeeds")
	_expect(session.current_coins == full_coins - 10 and session.get_weapon_upgrade_level(&"scatter") == 2, "upgrade changes only target level and deducts exact price")
	var upgrade_coins: int = session.current_coins
	var upgrade_levels: Dictionary = session.get_weapon_upgrade_levels()
	_expect(not session.try_upgrade_weapon(&"driver", 10), "un-equipped upgrade fails")
	_expect(session.current_coins == upgrade_coins and session.get_weapon_upgrade_levels() == upgrade_levels, "un-equipped upgrade is atomic")
	_expect(not session.try_upgrade_weapon(&"scatter", 0), "non-positive upgrade price fails")
	_expect(session.current_coins == upgrade_coins and session.get_weapon_upgrade_levels() == upgrade_levels, "invalid upgrade price is atomic")
	session.weapon_upgrade_levels[&"scatter"] = session.MAX_WEAPON_LEVEL
	var max_level_coins: int = session.current_coins
	_expect(not session.try_upgrade_weapon(&"scatter", 10), "max-level upgrade fails")
	_expect(session.current_coins == max_level_coins and session.get_weapon_upgrade_level(&"scatter") == session.MAX_WEAPON_LEVEL, "max-level failure is atomic")
	session.weapon_upgrade_levels[&"scatter"] = 0
	_expect(not session.try_upgrade_weapon(&"scatter", 10), "illegal level upgrade fails")
	_expect(session.current_coins == max_level_coins and session.get_weapon_upgrade_level(&"scatter") == 0, "illegal level remains invalid without mutation")

	session.select_character(&"scout")
	session.reset_run()
	_expect(session.get_equipped_weapon_ids() == [&"basic"], "reset clears extras and uses selected reset character")
	_expect(session.get_weapon_upgrade_levels() == {&"basic": 1}, "reset clears old weapon levels")
	session.reset_run()
	_expect(session.get_equipped_weapon_ids() == [&"basic"] and session.get_weapon_upgrade_levels() == {&"basic": 1}, "multiple resets do not duplicate or retain levels")

	var default_character = session.get_character_config(session.DEFAULT_CHARACTER_ID)
	var original_starting_weapon: StringName = default_character.starting_weapon
	default_character.starting_weapon = &"scatter"
	session.reset_run()
	_expect(session.get_equipped_weapon_ids() == [&"scatter"] and session.get_weapon_upgrade_level(&"scatter") == 1, "reset derives loadout from CharacterConfig starting_weapon")
	default_character.starting_weapon = &"missing_weapon"
	session.reset_run()
	_expect(session.get_equipped_weapon_ids().is_empty() and session.get_weapon_upgrade_levels().is_empty(), "invalid starting weapon leaves no illegal loadout")
	default_character.starting_weapon = original_starting_weapon
	session.reset_run()
	_finish()

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _finish() -> void:
	for failure in failures:
		push_error(failure)
	print("Phase 10 Task 1 smoke passed" if failures.is_empty() else "Phase 10 Task 1 smoke failed")
	quit(1 if not failures.is_empty() else 0)
