extends SceneTree

const GAME_SESSION_SCRIPT_PATH := "res://scene/game_session.gd"
const REQUIRED_SCENES := [
	"res://scene/main_menu.tscn",
	"res://scene/game.tscn",
	"res://scene/shop.tscn",
]

var failures: Array[String] = []


func _init() -> void:
	# SceneTree scripts can start before project autoloads have been added.
	# Defer the smoke test until the first idle frame so scene scripts that
	# reference GameSession are compiled in the same initialized context as
	# the running project.
	call_deferred("_run_after_autoloads")


func _run_after_autoloads() -> void:
	await _wait_for_editor_startup()
	# A custom SceneTree script does not expose project autoload nodes directly;
	# after editor startup, mirror the configured autoload into this test tree.
	var autoload: Node = get_root().get_node_or_null("GameSession")
	if autoload == null:
		var session_script := ResourceLoader.load(GAME_SESSION_SCRIPT_PATH) as GDScript
		if session_script == null or session_script.reload() != OK:
			failures.append("GameSession autoload script failed to load")
		else:
			autoload = session_script.new()
			autoload.name = "GameSession"
			get_root().add_child(autoload)
	_test_game_session_reset_and_purchase()
	_test_required_scenes_load()
	_finish()


func _wait_for_editor_startup() -> void:
	await process_frame
	for child in get_root().get_children():
		if child.get_class() != "EditorNode":
			continue
		for editor_child in child.get_children():
			if not editor_child.name.begins_with("@EditorFileSystem"):
				continue
			while editor_child.is_scanning():
				await process_frame
			for _i in 4:
				await process_frame
			return


func _test_game_session_reset_and_purchase() -> void:
	var session = get_root().get_node_or_null("GameSession")
	_expect(session != null, "GameSession autoload must be available before session checks")
	if session == null:
		return
	session.current_round = 4
	session.current_coins = 12
	session.add_relic("old_relic")
	session.reset_run()
	_expect(session.current_round == 1, "reset_run must reset the round")
	_expect(session.current_coins == 0, "reset_run must clear carried coins")
	_expect(session.owned_relics.is_empty(), "reset_run must clear owned relics")

	session.current_coins = 10
	_expect(session.try_purchase_relic("rapid_chamber", 6), "valid relic purchase must succeed")
	_expect(session.current_coins == 4, "successful purchase must deduct exactly once")
	_expect(session.has_relic("rapid_chamber"), "successful purchase must own the relic")
	_expect(not session.try_purchase_relic("rapid_chamber", 6), "a purchased relic must not be purchasable twice")
	_expect(session.current_coins == 4, "duplicate purchase must not deduct coins")
	_expect(not session.try_purchase_relic("reinforced_charm", 5), "purchase with insufficient coins must fail")
	_expect(session.current_coins == 4, "failed purchase must not deduct coins")


func _test_required_scenes_load() -> void:
	for script_path in [
		"res://scene/main_menu.gd",
		"res://scene/character_select.gd",
		"res://scene/game.gd",
		"res://scene/player.gd",
		"res://scene/shop.gd",
		"res://scene/enemy.gd",
		"res://scene/bullet.gd",
		"res://scene/coin.gd",
		"res://scene/pickup.gd",
	]:
		var script := ResourceLoader.load(script_path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		_expect(script != null, "scene script failed to load: %s" % script_path)
		if script != null:
			_expect(script.reload() == OK, "scene script failed to compile: %s" % script_path)

	for scene_path in REQUIRED_SCENES:
		var scene := ResourceLoader.load(scene_path) as PackedScene
		_expect(scene != null, "required scene failed to load: %s" % scene_path)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("Phase 1 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error("Phase 1 smoke test failed: %s" % failure)
	quit(1)
