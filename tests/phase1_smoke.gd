extends SceneTree

const GAME_SESSION_SCRIPT := preload("res://scene/game_session.gd")
const REQUIRED_SCENES := [
	"res://scene/main_menu.tscn",
	"res://scene/game.tscn",
	"res://scene/shop.tscn",
]

var failures: Array[String] = []


func _init() -> void:
	_test_game_session_reset_and_purchase()
	_test_required_scenes_load()
	_finish()


func _test_game_session_reset_and_purchase() -> void:
	var session = GAME_SESSION_SCRIPT.new()
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
