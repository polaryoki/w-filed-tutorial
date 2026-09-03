extends Node
const WeaponSystemScript := preload("res://scene/weapon_system.gd")
var failures: Array[String] = []
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS; call_deferred("_run")
func _run() -> void:
	var s = get_tree().root.get_node("GameSession"); s.reset_run(); s.current_coins = 100
	var resources: Array = s.WEAPON_OPTIONS.map(func(w): return w.resolved_stats())
	_expect(s.try_purchase_weapon(&"scatter", s.SHOP_WEAPON_PRICE), "authoritative purchase")
	_expect(s.get_weapon_upgrade_level(&"scatter") == 1, "purchase level")
	_expect(s.upgrade_weapon(&"scatter", s.SHOP_WEAPON_UPGRADE_PRICE), "authoritative upgrade")
	_expect(s.get_weapon_upgrade_level(&"scatter") == 2, "upgrade level")
	_expect(not s.upgrade_weapon(&"driver", s.SHOP_WEAPON_UPGRADE_PRICE), "unowned upgrade atomic")
	var system := WeaponSystemScript.new(); add_child(system)
	system.setup_loadout(s.get_equipped_weapon_configs(), s.get_weapon_upgrade_levels())
	_expect(system.runtime_entries.size() == 2, "runtime loadout")
	_expect(system.runtime_entries[1].level == 2, "runtime level")
	s.reset_run(); system.setup_loadout(s.get_equipped_weapon_configs(), s.get_weapon_upgrade_levels())
	_expect(system.runtime_entries.size() == 1 and system.runtime_entries[0].weapon_id == &"basic", "reset runtime")
	_expect(resources == s.WEAPON_OPTIONS.map(func(w): return w.resolved_stats()), "immutable config")
	for f in failures: push_error(f)
	print("Phase 10 Task 5 smoke passed" if failures.is_empty() else "Phase 10 Task 5 smoke failed")
	system.free(); get_tree().quit(0 if failures.is_empty() else 1)
func _expect(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
