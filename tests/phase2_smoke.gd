extends SceneTree

const GAME_SESSION_SCRIPT_PATH := "res://scene/game_session.gd"
const REQUIRED_SCENES := [
	"res://scene/main_menu.tscn",
	"res://scene/character_select.tscn",
	"res://scene/game.tscn",
	"res://scene/shop.tscn",
]
const REQUIRED_CHARACTER_RESOURCES := [
	"res://resourse/character/character_gunslinger.tres",
	"res://resourse/character/character_scout.tres",
	"res://resourse/character/character_guardian.tres",
]

var failures: Array[String] = []
var session


func _init() -> void:
	call_deferred("_run_after_startup")


func _run_after_startup() -> void:
	await _wait_for_editor_startup()
	_init_game_session_context()
	if session == null:
		_finish()
		return
	_test_character_resources()
	_test_character_selection()
	_test_round_resolution()
	_test_required_scenes()
	await _test_character_select_scene()
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
			# Script class registration follows the filesystem scan.
			for _i in 4:
				await process_frame
			return


func _init_game_session_context() -> void:
	session = get_root().get_node_or_null("GameSession")
	if session != null:
		return

	var session_script := ResourceLoader.load(GAME_SESSION_SCRIPT_PATH) as GDScript
	if session_script == null or session_script.reload() != OK:
		failures.append("GameSession autoload script failed to initialize")
		return

	session = session_script.new()
	session.name = "GameSession"
	get_root().add_child(session)


func _test_character_resources() -> void:
	var seen_ids: Dictionary = {}
	for resource_path in REQUIRED_CHARACTER_RESOURCES:
		var character := ResourceLoader.load(resource_path)
		_expect(character != null, "character resource failed to load: %s" % resource_path)
		if character == null:
			continue
		var character_id: StringName = character.get("id")
		_expect(not String(character_id).is_empty(), "character id must not be empty: %s" % resource_path)
		_expect(not seen_ids.has(character_id), "character ids must be unique: %s" % character_id)
		seen_ids[character_id] = true
		_expect(int(character.get("base_health")) > 0, "character health must be positive: %s" % character_id)
		_expect(float(character.get("move_speed")) > 0.0, "character speed must be positive: %s" % character_id)
		_expect(float(character.get("fire_interval")) >= 0.01, "character fire interval must be valid: %s" % character_id)

	var available: Array = session.get_available_characters()
	_expect(available.size() == REQUIRED_CHARACTER_RESOURCES.size(), "GameSession must expose all character options")


func _test_character_selection() -> void:
	session.reset_run()
	_expect(session.selected_character_id == &"gunslinger", "reset_run must select the default character")
	_expect(session.select_character(&"scout"), "known character selection must succeed")
	_expect(session.selected_character_id == &"scout", "selected character id must be stored")
	_expect(not session.select_character(&"missing_character"), "unknown character selection must fail")
	_expect(session.selected_character_id == &"scout", "failed selection must preserve the previous choice")


func _test_round_resolution() -> void:
	session.reset_run()
	session.select_character(&"scout")
	var base_stats: Dictionary = session.resolve_character_stats()
	_expect(base_stats["max_health"] == 4, "scout base health must resolve")
	_expect(is_equal_approx(base_stats["move_speed"], 155.0), "scout base speed must resolve")
	_expect(base_stats["starting_coins"] == 0, "base starting coins must be zero")

	session.add_relic("swift_boots")
	session.add_relic("reinforced_charm")
	session.add_relic("rapid_chamber")
	var resolved_stats: Dictionary = session.resolve_character_stats()
	var resolved_again: Dictionary = session.resolve_character_stats()
	_expect(resolved_stats == resolved_again, "resolving twice in one round must be idempotent")
	_expect(resolved_stats["max_health"] == 5, "health relic must apply once")
	_expect(is_equal_approx(resolved_stats["move_speed"], 178.25), "speed multiplier must apply to character base")
	_expect(is_equal_approx(resolved_stats["fire_interval"], 0.198), "fire multiplier must apply to character base")

	session.current_round += 1
	var next_round_stats: Dictionary = session.resolve_character_stats()
	_expect(next_round_stats == resolved_stats, "new round must recalculate from the same base without compounding")
	session.select_character(&"guardian")
	var guardian_stats: Dictionary = session.resolve_character_stats()
	_expect(guardian_stats["max_health"] == 9, "guardian base health must replace the previous character")
	_expect(guardian_stats["armor"] == 1, "guardian armor must resolve")
	_expect(guardian_stats["character_id"] == &"guardian", "resolved stats must identify the selected character")


func _test_required_scenes() -> void:
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
		if scene == null:
			continue
		var instance := scene.instantiate()
		_expect(instance != null, "required scene failed to instantiate: %s" % scene_path)
		if instance != null:
			instance.free()


func _test_character_select_scene() -> void:
	session.reset_run()
	var scene := ResourceLoader.load("res://scene/character_select.tscn") as PackedScene
	if scene == null:
		return
	var instance := scene.instantiate()
	if instance == null:
		return
	_expect(instance.get_node("CenterContainer/PanelContainer/MarginContainer/Layout/CharacterCards").get_child_count() == 3, "character select must expose three options")
	instance.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("Phase 2 smoke test passed.")
		quit(0)
		return

	for failure in failures:
		push_error("Phase 2 smoke test failed: %s" % failure)
	quit(1)
