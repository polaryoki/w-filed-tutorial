extends Node

const SHOP_SCENE := preload("res://scene/shop.tscn")
const WeaponSystemScript := preload("res://scene/weapon_system.gd")

var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	var session = get_tree().root.get_node("GameSession")
	session.reset_run()
	session.current_coins = 100
	var resources: Array = session.WEAPON_OPTIONS.map(func(weapon): return weapon.resolved_stats())
	var shop = SHOP_SCENE.instantiate()
	add_child(shop)
	await get_tree().process_frame
	_expect(shop.weapon_items != null and shop.weapon_items.get_child_count() == session.WEAPON_OPTIONS.size(), "Shop presents all configured weapons")
	_expect(shop.try_buy_weapon(-1) == false and session.current_coins == 100, "invalid offer is atomic")
	var scatter_index := _displayed_index(shop, &"scatter")
	_expect(scatter_index >= 0 and shop.try_buy_weapon(scatter_index), "unequipped weapon can be purchased")
	_expect(session.get_equipped_weapon_ids() == [&"basic", &"scatter"] and session.current_coins == 88, "purchase updates ordered loadout and exact coins")
	_expect(shop.displayed_weapons.all(func(weapon): return weapon.id != &"scatter"), "purchased weapon leaves purchase offers")
	_expect(shop.try_upgrade_weapon(&"scatter"), "equipped weapon can be upgraded")
	_expect(session.get_weapon_upgrade_level(&"scatter") == 2 and session.current_coins == 78, "upgrade updates level and exact coins")
	_expect(not shop.try_upgrade_weapon(&"driver") and session.current_coins == 78, "unowned upgrade is atomic")
	var arc_index := _displayed_index(shop, &"arc")
	_expect(arc_index >= 0 and shop.try_buy_weapon(arc_index), "third slot can be purchased")
	_expect(session.get_equipped_weapon_ids().size() == session.MAX_WEAPON_SLOTS, "loadout reaches capacity")
	var driver_index := _displayed_index(shop, &"driver")
	var before_full: int = session.current_coins
	_expect(driver_index >= 0 and not shop.try_buy_weapon(driver_index) and session.current_coins == before_full, "full-slot purchase is atomic")
	shop._refresh_weapon_ui()
	_expect(_weapon_button(shop, &"driver").disabled, "full-slot unavailable weapon is disabled")
	var system := WeaponSystemScript.new(); add_child(system)
	system.setup_loadout(session.get_equipped_weapon_configs(), session.get_weapon_upgrade_levels())
	_expect(system.runtime_entries.size() == 3 and system.runtime_entries[1].level == 2, "Shop state flows into multi-weapon runtime")
	system.runtime_entries[0].cooldown_left = 0.5
	_expect(system.runtime_entries[1].cooldown_left == 0.0, "runtime entries remain independent")
	session.reset_run()
	system.setup_loadout(session.get_equipped_weapon_configs(), session.get_weapon_upgrade_levels())
	_expect(system.runtime_entries.size() == 1 and system.runtime_entries[0].weapon_id == &"basic", "reset/reload clears old runtime state")
	_expect(resources == session.WEAPON_OPTIONS.map(func(weapon): return weapon.resolved_stats()), "Shop and runtime keep WeaponConfig immutable")
	for failure in failures: push_error(failure)
	print("Phase 10 Task 5 smoke passed" if failures.is_empty() else "Phase 10 Task 5 smoke failed")
	shop.free(); system.free(); get_tree().quit(0 if failures.is_empty() else 1)

func _displayed_index(shop: Node, weapon_id: StringName) -> int:
	for index in shop.displayed_weapons.size():
		if shop.displayed_weapons[index].id == weapon_id: return index
	return -1

func _weapon_button(shop: Node, weapon_id: StringName) -> Button:
	for row in shop.weapon_items.get_children():
		if row.get_child(0).text.begins_with(String(get_tree().root.get_node("GameSession").get_weapon_config(weapon_id).display_name)):
			return row.get_child(1) as Button
	return null

func _expect(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
