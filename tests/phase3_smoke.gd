extends SceneTree

const WEAPON_SCRIPT_PATH := "res://resourse/weapon/weapon_config.gd"
const WEAPON_SYSTEM_SCRIPT_PATH := "res://scene/weapon_system.gd"
const BASIC_WEAPON_PATH := "res://resourse/weapon/weapon_basic.tres"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _wait_for_editor_startup()
	for path in [WEAPON_SCRIPT_PATH, WEAPON_SYSTEM_SCRIPT_PATH, "res://scene/player.gd", "res://scene/bullet.gd", "res://scene/enemy.gd"]:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		_expect(script != null, "weapon-related script failed to load: %s" % path)
		if script != null:
			_expect(script.reload() == OK, "weapon-related script failed to compile: %s" % path)

	var weapon := ResourceLoader.load(BASIC_WEAPON_PATH) as Resource
	_expect(weapon != null, "basic weapon resource failed to load")
	if weapon != null:
		_expect(int(weapon.get("damage")) == 1, "basic weapon damage contract must resolve")
		_expect(int(weapon.get("projectile_count")) == 1, "basic weapon projectile count must resolve")
		_expect(int(weapon.get("piercing")) == 1, "basic weapon piercing must resolve")
		_expect(float(weapon.get("fire_interval")) > 0.0, "weapon cooldown must be positive")
		_expect(float(weapon.get("range")) > 0.0, "weapon range must be positive")

	var scene := ResourceLoader.load("res://scene/player.tscn") as PackedScene
	_expect(scene != null, "player scene failed to load with WeaponSystem")
	if scene != null:
		var instance := scene.instantiate()
		_expect(instance != null and instance.get_node_or_null("WeaponSystem") != null, "player must own a WeaponSystem node")
		if instance != null:
			instance.free()

	if failures.is_empty():
		print("Phase 3 smoke test passed.")
		quit(0)
		return
	for failure in failures:
		push_error("Phase 3 smoke test failed: %s" % failure)
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
