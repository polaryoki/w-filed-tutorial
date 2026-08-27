extends SceneTree

const WaveDirectorScript = preload("res://scene/wave_director.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var waves: Array[Resource] = []
	for path in ["res://resourse/wave/wave_1.tres", "res://resourse/wave/wave_2.tres", "res://resourse/wave/wave_3.tres"]:
		var wave := load(path)
		_expect(wave != null and wave.is_valid(), "%s must load and validate" % path)
		waves.append(wave)
	_expect(waves[0].duration != waves[1].duration and waves[1].spawn_budget != waves[2].spawn_budget, "initial waves need distinct pacing")

	var director = WaveDirectorScript.new()
	_expect(director.configure(waves[0]), "director must accept a valid wave")
	for index in waves[0].simultaneous_cap:
		_expect(director.notify_enemy_spawned(), "spawn within cap must be accepted")
	_expect(not director.notify_enemy_spawned(), "simultaneous cap must be respected")
	_expect(director.remaining_budget == waves[0].spawn_budget - waves[0].simultaneous_cap, "accepted spawns consume exactly one budget")
	for index in waves[0].simultaneous_cap:
		_expect(director.notify_enemy_defeated(), "live enemy defeat must be accepted")
	_expect(not director.notify_enemy_defeated(), "duplicate defeat must be rejected")

	while director.remaining_budget > 0:
		_expect(director.notify_enemy_spawned(), "remaining budget should be spawnable")
		_expect(director.notify_enemy_defeated(), "spawned enemy should be defeatable")
	_expect(not director.notify_enemy_spawned() and director.remaining_budget == 0, "spawn budget cannot go negative")
	var completion_count := [0]
	director.wave_completed.connect(func(_snapshot): completion_count[0] += 1)
	director.advance(waves[0].duration + 1.0)
	director.advance(1.0)
	_expect(completion_count[0] == 1 and director.snapshot().completed, "duration completion must emit once")
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("Phase 9 smoke passed")
	else:
		for failure in failures:
			push_error(failure)
	quit(1 if not failures.is_empty() else 0)
