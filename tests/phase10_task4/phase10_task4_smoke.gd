extends SceneTree

const WeaponSystemScript = preload("res://scene/weapon_system.gd")
const BASIC = preload("res://resourse/weapon/weapon_basic.tres")
const SCATTER = preload("res://resourse/weapon/weapon_scatter.tres")
const DAMAGE_UP = preload("res://resourse/progression/upgrade_damage.tres")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = root.get_node("GameSession")
	session.reset_run()
	session.equip_weapon(&"scatter")
	var host := Node2D.new(); root.add_child(host)
	var system := WeaponSystemScript.new(); host.add_child(system)
	var configs: Array[WeaponConfig] = [BASIC, SCATTER]
	var snapshots := [BASIC.resolved_stats(), SCATTER.resolved_stats()]
	system.setup_loadout(configs, {&"basic": 1, &"scatter": 2}, {"damage_bonus": 3, "projectile_count_bonus": 1, "fire_interval_multiplier": 0.5})
	_expect(system.runtime_entries.size() == 2, "multi-weapon runtime exists")
	for entry in system.runtime_entries:
		_expect(entry.stats.damage == entry.config.resolved_stats_for_level(entry.level, session.MAX_WEAPON_LEVEL).damage + 3, "base, Run level, then runtime damage modifier applies once")
		_expect(entry.stats.projectile_count == entry.config.resolved_stats_for_level(entry.level, session.MAX_WEAPON_LEVEL).projectile_count + 1, "projectile modifier applies to every weapon")
		_expect(is_equal_approx(entry.stats.fire_interval, entry.config.resolved_stats_for_level(entry.level, session.MAX_WEAPON_LEVEL).fire_interval * 0.5), "rapid-fire interval applies to every weapon")
	var before := _stats(system)
	system.refresh_modifiers({"damage_bonus": 3, "projectile_count_bonus": 1, "fire_interval_multiplier": 0.5})
	_expect(before == _stats(system), "refresh_modifiers is idempotent")
	session.pending_level_ups = 1
	session.current_upgrade_offer_ids = [&"damage"] as Array[StringName]
	var upgrade: Resource = session.apply_level_upgrade(&"damage")
	_expect(upgrade != null, "XP upgrade transaction succeeds")
	var upgraded_damage := _stats(system)
	system.refresh_modifiers({"damage_bonus": 4, "projectile_count_bonus": 1, "fire_interval_multiplier": 0.5})
	_expect(_stats(system)[0].damage > upgraded_damage[0].damage, "XP level-up modifier refreshes immediately")
	var pickup_before: float = session.resolve_character_stats().pickup_range
	session.pending_level_ups = 1
	session.current_upgrade_offer_ids = [&"pickup_range"] as Array[StringName]
	_expect(session.apply_level_upgrade(&"pickup_range") != null and session.resolve_character_stats().pickup_range > pickup_before, "existing pickup-range modifier remains live")
	system.setup_loadout([SCATTER], {&"scatter": 2}, {"damage_bonus": 0})
	_expect(system.runtime_entries.size() == 1 and system.runtime_entries[0].weapon_id == &"scatter", "reload clears old runtime state")
	_expect(snapshots == [BASIC.resolved_stats(), SCATTER.resolved_stats()], "resources remain immutable")
	for failure in failures: push_error(failure)
	print("Phase 10 Task 4 smoke passed" if failures.is_empty() else "Phase 10 Task 4 smoke failed")
	host.free(); quit(0 if failures.is_empty() else 1)

func _stats(system: Node) -> Array:
	return system.runtime_entries.map(func(entry): return {"damage": entry.stats.damage, "interval": entry.stats.fire_interval, "projectile_count": entry.stats.projectile_count})

func _expect(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
