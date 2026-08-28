extends SceneTree

const WEAPONS: Array[WeaponConfig] = [
	preload("res://resourse/weapon/weapon_basic.tres"),
	preload("res://resourse/weapon/weapon_scatter.tres"),
	preload("res://resourse/weapon/weapon_arc.tres"),
	preload("res://resourse/weapon/weapon_driver.tres"),
]

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_root().get_node("GameSession")
	var maximum_level: int = session.MAX_WEAPON_LEVEL
	var basic: WeaponConfig = WEAPONS[0]
	var scatter: WeaponConfig = WEAPONS[1]
	var original_basic_damage: int = basic.damage
	var original_basic_interval: float = basic.fire_interval
	var original_basic_upgrade_level: int = basic.upgrade_level
	var original_basic_tags: Array[StringName] = basic.tags.duplicate()

	var level_one := basic.resolved_stats_for_level(1, maximum_level)
	_expect(int(level_one.get("damage", -1)) == basic.damage, "level one uses base damage")
	_expect(is_equal_approx(float(level_one.get("fire_interval", -1.0)), basic.fire_interval), "level one uses base interval")
	_expect(int(level_one.get("upgrade_level", 0)) == 1, "level one reports requested level")

	var level_two := basic.resolved_stats_for_level(2, maximum_level)
	_expect(int(level_two.get("damage", -1)) == basic.damage + basic.damage_per_level, "level two applies one damage growth step")
	_expect(is_equal_approx(float(level_two.get("fire_interval", -1.0)), basic.fire_interval * basic.fire_interval_per_level), "level two applies one interval multiplier")

	var higher_level := 5
	var level_five := basic.resolved_stats_for_level(higher_level, maximum_level)
	_expect(int(level_five.get("damage", -1)) == basic.damage + basic.damage_per_level * (higher_level - 1), "higher level damage growth is deterministic")
	_expect(is_equal_approx(float(level_five.get("fire_interval", -1.0)), basic.fire_interval * pow(basic.fire_interval_per_level, higher_level - 1)), "higher level interval growth is deterministic")

	_expect(basic.resolved_stats_for_level(0, maximum_level).is_empty(), "level zero is rejected")
	_expect(basic.resolved_stats_for_level(-1, maximum_level).is_empty(), "negative level is rejected")
	_expect(basic.resolved_stats_for_level(maximum_level + 1, maximum_level).is_empty(), "level above Task 1 maximum is rejected")
	_expect(basic.resolved_stats_for_level(1, 0).is_empty(), "invalid supplied maximum is rejected")

	var default_config := WeaponConfig.new()
	var default_level_two := default_config.resolved_stats_for_level(2, maximum_level)
	_expect(int(default_level_two.get("damage", -1)) == default_config.damage + 1, "missing resource growth data uses script damage default")
	_expect(is_equal_approx(float(default_level_two.get("fire_interval", -1.0)), default_config.fire_interval * 0.92), "missing resource growth data uses script interval default")
	default_config.damage_per_level = -1
	_expect(default_config.resolved_stats_for_level(2, maximum_level).is_empty(), "invalid damage growth is rejected")
	default_config.damage_per_level = 1
	default_config.fire_interval_per_level = 0.0
	_expect(default_config.resolved_stats_for_level(2, maximum_level).is_empty(), "invalid interval growth is rejected")

	basic.upgrade_level = 7
	var explicit_level_two := basic.resolved_stats_for_level(2, maximum_level)
	_expect(int(explicit_level_two.get("upgrade_level", 0)) == 2, "static upgrade_level is not a Run-level source")
	_expect(basic.upgrade_level == 7, "resolver does not write the Resource upgrade level")
	explicit_level_two["damage"] = 999
	var mutable_tags: Array = explicit_level_two["tags"]
	mutable_tags.append(&"test_only")
	var scatter_before: Dictionary = scatter.resolved_stats_for_level(2, maximum_level)
	var basic_again := basic.resolved_stats_for_level(2, maximum_level)
	_expect(int(basic_again.get("damage", -1)) != 999, "mutating a result does not pollute the source Resource")
	_expect(basic.tags == original_basic_tags, "resolved tags are copied")
	_expect(int(scatter_before.get("damage", -1)) == scatter.damage + scatter.damage_per_level, "different WeaponConfig values resolve independently")

	_expect(basic.damage == original_basic_damage and is_equal_approx(basic.fire_interval, original_basic_interval), "resolver leaves base combat fields unchanged")
	basic.upgrade_level = original_basic_upgrade_level
	_finish()

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _finish() -> void:
	for failure in failures:
		push_error(failure)
	print("Phase 10 Task 2 smoke passed" if failures.is_empty() else "Phase 10 Task 2 smoke failed")
	quit(1 if not failures.is_empty() else 0)
