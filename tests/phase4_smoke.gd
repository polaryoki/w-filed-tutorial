extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _wait_for_editor_startup()
	var synergy_script := ResourceLoader.load("res://resourse/weapon/weapon_synergy_config.gd") as GDScript
	_expect(synergy_script != null and synergy_script.reload() == OK, "synergy config must compile")
	var resolver_script := ResourceLoader.load("res://scene/weapon_synergy_resolver.gd") as GDScript
	_expect(resolver_script != null and resolver_script.reload() == OK, "synergy resolver must compile")
	var synergy := ResourceLoader.load("res://resourse/weapon/synergy_kinetic_pair.tres") as Resource
	var weapon := ResourceLoader.load("res://resourse/weapon/weapon_basic.tres") as Resource
	_expect(synergy != null and weapon != null, "synergy and weapon resources must load")
	if synergy != null and weapon != null:
		var resolver = resolver_script.new() if resolver_script != null else null
		var weapon_configs: Array[Resource] = [weapon, weapon]
		var synergy_configs: Array[Resource] = [synergy]
		var resolved: Dictionary = resolver.resolve(weapon_configs, synergy_configs) if resolver != null else {}
		_expect(resolved["active_synergies"].size() == 1, "matching tags must activate synergy once")
		var again: Dictionary = resolver.resolve(weapon_configs, synergy_configs) if resolver != null else {}
		_expect(resolved == again, "synergy resolution must be deterministic and non-recursive")
		_expect(is_equal_approx(float(resolved["fire_interval"]), 0.162), "synergy multiplier must apply once")
	if failures.is_empty():
		print("Phase 4 smoke test passed.")
		quit(0)
		return
	for failure in failures:
		push_error("Phase 4 smoke test failed: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

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
