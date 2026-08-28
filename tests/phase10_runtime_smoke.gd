extends SceneTree
const WeaponSystemScript = preload("res://scene/weapon_system.gd")
const FAST = preload("res://resourse/weapon/weapon_basic.tres")
const SLOW = preload("res://resourse/weapon/weapon_driver.tres")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var parent := Node2D.new(); get_root().add_child(parent)
	var system = WeaponSystemScript.new(); parent.add_child(system)
	var configs: Array[WeaponConfig] = [FAST, SLOW]
	system.setup_loadout(configs, {&"basic": 1, &"driver": 1})
	var original_damage := FAST.damage
	var shots := {&"basic": 0, &"driver": 0}
	for i in 20:
		system.advance_and_fire(0.1, Vector2.ZERO, Vector2.RIGHT, parent, func(_d): return true)
		for child in parent.get_children():
			if child is Bullet and not child.has_meta("counted"):
				child.set_meta("counted", true); var id: StringName = child.get_meta("weapon_id"); shots[id] = int(shots.get(id, 0)) + 1
	_expect(int(shots[&"basic"]) > int(shots[&"driver"]), "independent cooldowns must preserve fast/slow cadence")
	_expect(int(shots[&"driver"]) >= 2, "slow weapon cooldown must not be reset by fast weapon")
	_expect(FAST.damage == original_damage, "runtime setup must not mutate WeaponConfig")
	parent.free(); _finish()
func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)
func _finish() -> void:
	for f in failures: push_error(f)
	print("Phase 10 runtime smoke passed" if failures.is_empty() else "Phase 10 runtime smoke failed"); quit(1 if not failures.is_empty() else 0)
