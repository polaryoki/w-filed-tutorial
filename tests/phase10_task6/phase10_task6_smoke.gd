extends SceneTree

const WeaponSystemScript := preload("res://scene/weapon_system.gd")
const BASIC := preload("res://resourse/weapon/weapon_basic.tres")
const DRIVER := preload("res://resourse/weapon/weapon_driver.tres")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_root().get_node("GameSession")
	session.reset_run()
	session.current_coins = 100
	_expect(session.try_purchase_weapon(&"driver", 12), "Task 5 purchase remains available")
	_expect(session.upgrade_weapon(&"driver", 10), "Task 5 upgrade remains available")
	_expect(not session.try_purchase_weapon(&"driver", 12), "duplicate purchase is rejected atomically")
	_expect(session.equipped_weapon_ids == [&"basic", &"driver"] and session.current_coins == 78, "valid transactions commit exact state")

	var parent := Node2D.new()
	get_root().add_child(parent)
	var system := WeaponSystemScript.new()
	parent.add_child(system)
	var source_damage := BASIC.damage
	system.setup_loadout([BASIC, DRIVER], {&"basic": 1, &"driver": 2}, {
		"damage_bonus": 2,
		"fire_interval_multiplier": 0.5,
		"projectile_count_bonus": 1,
	})
	_expect(system.runtime_entries.size() == 2, "two independent runtime entries are created")
	_expect(int(system.runtime_entries[0].stats.damage) != int(system.runtime_entries[1].stats.damage), "weapon identity and level stats remain distinct")
	var spawned := system.advance_and_fire(0.0, Vector2.ZERO, Vector2.RIGHT, parent, func(_direction): return true)
	_expect(spawned > 0, "core multi-weapon firing works")
	var first_cooldown := float(system.runtime_entries[0].cooldown_left)
	_expect(float(system.runtime_entries[1].cooldown_left) > 0.0 and first_cooldown != float(system.runtime_entries[1].cooldown_left), "cooldowns do not share state")
	var resolved_damage := int(system.runtime_entries[0].stats.damage)
	system.refresh_modifiers({"damage_bonus": 2, "fire_interval_multiplier": 0.5, "projectile_count_bonus": 1})
	_expect(int(system.runtime_entries[0].stats.damage) == resolved_damage, "modifier refresh is idempotent")
	_expect(BASIC.damage == source_damage, "WeaponConfig Resource remains immutable")

	session.reset_run()
	system.setup_loadout(session.get_equipped_weapon_configs(), session.get_weapon_upgrade_levels())
	_expect(system.runtime_entries.size() == 1 and system.runtime_entries[0].weapon_id == &"basic", "reset and reload discard old runtime entries")
	var coins_before: int = session.current_coins
	_expect(not session.try_purchase_weapon(&"missing", 12) and session.current_coins == coins_before, "invalid Shop transaction has no partial update")
	parent.queue_free()
	_finish()

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _finish() -> void:
	for failure in failures:
		push_error(failure)
	print("Phase 10 Task 6 smoke passed" if failures.is_empty() else "Phase 10 Task 6 smoke failed")
	quit(0 if failures.is_empty() else 1)
