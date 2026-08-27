extends Node

const GAME_SCENE := preload("res://scene/game.tscn")
const WAVE_CONFIG_SCRIPT := preload("res://resourse/wave/wave_config.gd")
const ENEMY_CONFIG := preload("res://resourse/config/enemy_basic.tres")

var failures: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	GameSession.reset_run()
	var wave: WaveConfig = WAVE_CONFIG_SCRIPT.new()
	wave.id = &"integration_wave"
	wave.wave_number = 1
	wave.duration = 2.0
	wave.spawn_budget = 2
	wave.spawn_interval = 0.05
	wave.simultaneous_cap = 1
	var entries: Array[Dictionary] = [{"enemy_config": ENEMY_CONFIG, "weight": 1.0}]
	wave.enemy_entries = entries
	wave.completion_coins = 3

	var game = GAME_SCENE.instantiate()
	var waves: Array[Resource] = [wave]
	game.wave_configs = waves
	game.initial_spawn_count = 0
	add_child(game)
	await get_tree().process_frame

	_expect(game.wave_director != null, "Game must configure a WaveDirector")
	_expect(game.wave_config == wave, "Game must select the configured wave")
	game.wave_director.advance(0.06, game.random_generator)
	var first_enemy := _first_enemy(game.get_node("EnemyContainer"))
	_expect(first_enemy != null, "spawn_requested must create an Enemy through Game")
	_expect(game.wave_director.remaining_budget == 1, "successful construction must consume one budget")
	_expect(game.wave_director.alive_count == 1, "successful construction must increment alive count")

	game.wave_director.advance(0.06, game.random_generator)
	_expect(_enemy_count(game.get_node("EnemyContainer")) == 1, "simultaneous cap must prevent a second live enemy")
	if first_enemy != null:
		first_enemy.apply_damage(999)
	_expect(game.wave_director.alive_count == 0, "Enemy defeat must decrement director alive count")
	game.wave_director.advance(0.06, game.random_generator)
	_expect(game.wave_director.remaining_budget == 0, "spawn after a defeat must consume the remaining budget")
	_expect("Wave 1" in game.round_count_label.text and "Kills 1/2" in game.round_count_label.text, "HUD must expose current wave progress")

	var completions := [0]
	game.wave_director.wave_completed.connect(func(_snapshot): completions[0] += 1)
	game.wave_director.advance(3.0, game.random_generator)
	game.wave_director.advance(1.0, game.random_generator)
	_expect(completions[0] == 1, "wave completion must emit once")
	_expect(game.is_round_transitioning and game.is_result_displayed, "Game must enter its existing one-shot transition path")
	_expect(GameSession.current_coins == game.player.get_coins() + 3, "Game must credit configured completion coins before Shop")
	_finish()


func _first_enemy(container: Node) -> Enemy:
	for child in container.get_children():
		if child is Enemy:
			return child
	return null


func _enemy_count(container: Node) -> int:
	var count := 0
	for child in container.get_children():
		if child is Enemy and not child.is_dead:
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if is_inside_tree():
		get_tree().paused = false
	Engine.time_scale = 1.0
	if failures.is_empty():
		print("Phase 9 Game integration runtime passed")
	else:
		for failure in failures:
			push_error(failure)
	Engine.get_main_loop().quit(1 if not failures.is_empty() else 0)
