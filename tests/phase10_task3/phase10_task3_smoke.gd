extends SceneTree
const WeaponSystemScript = preload("res://scene/weapon_system.gd")
const BASIC = preload("res://resourse/weapon/weapon_basic.tres")
const SCATTER = preload("res://resourse/weapon/weapon_scatter.tres")
const ARC = preload("res://resourse/weapon/weapon_arc.tres")
var failures: Array[String] = []
func _init() -> void:
	var host := Node2D.new(); root.add_child(host)
	var system := WeaponSystemScript.new(); host.add_child(system)
	var configs: Array[WeaponConfig] = [BASIC, SCATTER, ARC]
	var resource_snapshots := [BASIC.resolved_stats(), SCATTER.resolved_stats(), ARC.resolved_stats()]
	system.setup_loadout([BASIC], {&"basic": 1})
	_expect(system.runtime_entries.size() == 1 and system.advance_and_fire(0.0, Vector2.ZERO, Vector2.RIGHT, host, _allow) > 0, "single weapon fires")
	system.setup_loadout(configs, {&"basic": 2, &"scatter": 3, &"arc": 4})
	_expect(system.runtime_entries.size() == 3, "three weapons coexist")
	_expect(system.runtime_entries[0].level == 2 and system.runtime_entries[1].level == 3 and system.runtime_entries[2].level == 4, "per weapon Run levels")
	for entry in system.runtime_entries:
		var expected: Dictionary = entry.config.resolved_stats_for_level(entry.level, GameSession.MAX_WEAPON_LEVEL)
		_expect(entry.stats.damage == expected.damage and is_equal_approx(entry.stats.fire_interval, expected.fire_interval), "Task 2 resolver is growth source")
	_expect(system.advance_and_fire(0.0, Vector2.ZERO, Vector2.RIGHT, host, _allow) >= 3, "all weapons fire")
	var first_cd: float = system.runtime_entries[0].cooldown_left
	system.runtime_entries[1].cooldown_left = 0.0
	var before := _count(host, system.runtime_entries[1].weapon_id)
	system.advance_and_fire(0.0, Vector2.ZERO, Vector2.RIGHT, host, _allow)
	_expect(system.runtime_entries[0].cooldown_left == first_cd and _count(host, system.runtime_entries[1].weapon_id) > before, "cooldowns are independent")
	var mutable: WeaponConfig = BASIC.duplicate(true); mutable.upgrade_level = 99
	system.setup_loadout([mutable], {&"basic": 2})
	_expect(system.runtime_entries[0].stats.upgrade_level == 2, "static upgrade level ignored")
	system.setup_loadout([BASIC, BASIC, SCATTER], {&"basic": 1, &"scatter": 1})
	_expect(system.runtime_entries.size() == 2, "duplicate entries suppressed")
	system.setup_loadout([ARC], {&"arc": 1}); _expect(system.runtime_entries.size() == 1 and system.runtime_entries[0].weapon_id == &"arc", "rebuild removes old entries")
	system.setup_loadout([BASIC], {}); _expect(system.runtime_entries.is_empty(), "missing level safe")
	system.setup_loadout([BASIC], {&"basic": 0}); _expect(system.runtime_entries.is_empty(), "invalid level safe")
	system.setup_loadout([], {}); _expect(system.fire(Vector2.ZERO, Vector2.RIGHT, host, _allow) == 0, "empty runtime safe")
	_expect(resource_snapshots == [BASIC.resolved_stats(), SCATTER.resolved_stats(), ARC.resolved_stats()], "runtime never mutates WeaponConfig Resources")
	for failure in failures: push_error(failure)
	print("Phase 10 Task 3 smoke passed" if failures.is_empty() else "Phase 10 Task 3 smoke failed"); host.free(); quit(0 if failures.is_empty() else 1)
func _allow(_direction: Vector2) -> bool: return true
func _count(host: Node, id: StringName) -> int:
	var n := 0
	for child in host.get_children():
		if child is Bullet and child.get_meta("weapon_id", &"") == id: n += 1
	return n
func _expect(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
