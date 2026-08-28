extends Node
const GAME_SCENE := preload("res://scene/game.tscn")
const SHOP_SCENE := preload("res://scene/shop.tscn")
var failures: Array[String] = []
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS; call_deferred("_run")
func _run() -> void:
	GameSession.reset_run(); GameSession.current_coins = 100
	_expect(GameSession.try_purchase_weapon(&"scatter", 12), "buy second")
	_expect(GameSession.try_purchase_weapon(&"arc", 12), "buy third")
	_expect(not GameSession.try_purchase_weapon(&"driver", 12), "fourth rejected")
	_expect(GameSession.upgrade_weapon(&"scatter", 10), "upgrade equipped")
	var game = GAME_SCENE.instantiate(); add_child(game); await get_tree().process_frame
	var player: Player = game.player
	_expect(player.weapon_system.runtime_entries.size() == 3, "Game round restores three runtime weapons")
	var original_configs := GameSession.get_equipped_weapon_configs()
	var original_damage := original_configs[1].damage
	player._try_shoot(Vector2.RIGHT, 1.0)
	await get_tree().process_frame
	var ids: Array[StringName] = []
	for child in get_tree().current_scene.get_children():
		if child is Bullet: ids.append(StringName(child.get_meta("weapon_id", &"")))
	_expect(&"basic" in ids and &"scatter" in ids and &"arc" in ids, "shared aim fires all ready weapons")
	_expect(original_configs[1].damage == original_damage, "runtime does not mutate config")
	var cooldowns: Array[float] = []
	for entry in player.weapon_system.runtime_entries: cooldowns.append(float(entry["cooldown"]))
	_expect(cooldowns[0] != cooldowns[1], "runtime cooldowns are independent")
	GameSession.add_experience(5); await get_tree().process_frame
	var paused_cooldown := float(player.weapon_system.runtime_entries[0]["cooldown"])
	await get_tree().process_frame
	_expect(get_tree().paused and is_equal_approx(paused_cooldown, float(player.weapon_system.runtime_entries[0]["cooldown"])), "level-up pause freezes weapons")
	if game.current_level_up_options.size() == 3: game.choose_level_up_option(0)
	_expect(not get_tree().paused, "level-up resumes")
	game.queue_free(); await get_tree().process_frame
	_expect(GameSession.equipped_weapon_ids.size() == 3 and GameSession.get_weapon_upgrade_level(&"scatter") == 2, "loadout persists between scenes")
	var shop = SHOP_SCENE.instantiate(); add_child(shop); await get_tree().process_frame
	_expect(shop.weapon_items != null and shop.weapon_items.get_child_count() == 4, "Shop presents every Phase 10 weapon")
	var shop_coins := GameSession.current_coins; _expect(not shop.try_buy_weapon(-1) and GameSession.current_coins == shop_coins, "invalid Shop offer is atomic")
	shop.queue_free(); await get_tree().process_frame
	GameSession.reset_run(); _expect(GameSession.equipped_weapon_ids == [&"basic"], "new run clears loadout")
	_finish()
func _expect(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)
func _finish() -> void:
	get_tree().paused = false; Engine.time_scale = 1.0
	for f in failures: push_error(f)
	print("Phase 10 integration runtime passed" if failures.is_empty() else "Phase 10 integration failed")
	get_tree().quit(1 if not failures.is_empty() else 0)
