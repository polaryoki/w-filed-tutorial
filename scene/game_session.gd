extends Node

const DEFAULT_CHARACTER_ID: StringName = &"gunslinger"
const CHARACTER_OPTIONS: Array[Resource] = [
	preload("res://resourse/character/character_gunslinger.tres"),
	preload("res://resourse/character/character_scout.tres"),
	preload("res://resourse/character/character_guardian.tres"),
]

var current_round: int = 1
var current_coins: int = 0
var owned_relics: Array[String] = []
var selected_character_id: StringName = DEFAULT_CHARACTER_ID

var _resolved_character_id: StringName = &""
var _resolved_round: int = 0
var _resolved_stats: Dictionary = {}


func reset_run() -> void:
	current_round = 1
	current_coins = 0
	owned_relics.clear()
	selected_character_id = DEFAULT_CHARACTER_ID
	_invalidate_character_resolution()


func get_available_characters() -> Array[Resource]:
	return CHARACTER_OPTIONS.duplicate()


func get_character_config(character_id: StringName = &""):
	var requested_id := character_id
	if requested_id == &"":
		requested_id = selected_character_id

	for character in CHARACTER_OPTIONS:
		if character == null:
			continue
		if character.get("id") == requested_id:
			return character

	return null


func select_character(character_id: StringName) -> bool:
	if get_character_config(character_id) == null:
		return false

	selected_character_id = character_id
	_invalidate_character_resolution()
	return true


func get_selected_character():
	return get_character_config(selected_character_id)


func resolve_character_stats() -> Dictionary:
	if (
		_resolved_character_id == selected_character_id
		and _resolved_round == current_round
		and not _resolved_stats.is_empty()
	):
		return _resolved_stats.duplicate(true)

	var character = get_selected_character()
	if character == null:
		character = CHARACTER_OPTIONS[0]
		selected_character_id = character.get("id")

	var stats: Dictionary = _get_character_base_stats(character)
	var move_speed_multiplier := 1.0
	var fire_interval_multiplier := 1.0

	for relic_id in owned_relics:
		match relic_id:
			"lucky_start":
				stats["starting_coins"] += 2
			"rapid_chamber":
				fire_interval_multiplier *= 0.9
			"reinforced_charm":
				stats["max_health"] += 1
			"swift_boots":
				move_speed_multiplier *= 1.15
			"iron_will":
				stats["invincibility_duration"] += 0.25
			"long_barrel":
				stats["bullet_spawn_distance"] += 6.0

	stats["max_health"] = clampi(roundi(float(stats["max_health"])), 1, 999)
	stats["move_speed"] = _round_stat(clampf(float(stats["move_speed"]) * move_speed_multiplier, 1.0, 1000.0))
	stats["fire_interval"] = _round_stat(clampf(float(stats["fire_interval"]) * fire_interval_multiplier, 0.01, 10.0))
	stats["damage"] = clampi(roundi(float(stats["damage"])), 0, 999)
	stats["projectile_count"] = clampi(roundi(float(stats["projectile_count"])), 1, 32)
	stats["pickup_range"] = _round_stat(clampf(float(stats["pickup_range"]), 1.0, 512.0))
	stats["luck"] = _round_stat(clampf(float(stats["luck"]), 0.0, 1.0))
	stats["armor"] = clampi(roundi(float(stats["armor"])), 0, 999)
	stats["critical_chance"] = _round_stat(clampf(float(stats["critical_chance"]), 0.0, 1.0))
	stats["invincibility_duration"] = _round_stat(clampf(float(stats["invincibility_duration"]), 0.0, 10.0))
	stats["bullet_spawn_distance"] = _round_stat(clampf(float(stats["bullet_spawn_distance"]), 0.0, 256.0))
	stats["starting_coins"] = maxi(roundi(float(stats["starting_coins"])), 0)

	_resolved_character_id = selected_character_id
	_resolved_round = current_round
	_resolved_stats = stats.duplicate(true)
	return _resolved_stats.duplicate(true)


func has_relic(relic_id: String) -> bool:
	return relic_id in owned_relics


func try_spend_coins(amount: int) -> bool:
	if amount <= 0 or current_coins < amount:
		return false
	current_coins -= amount
	return true


func add_relic(relic_id: String) -> bool:
	if relic_id.is_empty() or has_relic(relic_id):
		return false
	owned_relics.append(relic_id)
	_invalidate_character_resolution()
	return true


# 商店交易必须同时满足「未拥有」和「余额足够」两个条件，避免 UI 重复点击时
# 分别扣款、加遗物而造成状态不一致。
func try_purchase_relic(relic_id: String, price: int) -> bool:
	if relic_id.is_empty() or price <= 0:
		return false
	if has_relic(relic_id) or current_coins < price:
		return false

	current_coins -= price
	owned_relics.append(relic_id)
	_invalidate_character_resolution()
	return true


func _invalidate_character_resolution() -> void:
	_resolved_character_id = &""
	_resolved_round = 0
	_resolved_stats.clear()


func _round_stat(value: float) -> float:
	return snappedf(value, 0.001)


func _get_character_base_stats(character) -> Dictionary:
	return {
		"character_id": character.get("id"),
		"display_name": character.get("display_name"),
		"description": character.get("description"),
		"max_health": character.get("base_health"),
		"move_speed": character.get("move_speed"),
		"fire_interval": character.get("fire_interval"),
		"damage": character.get("damage"),
		"projectile_count": character.get("projectile_count"),
		"pickup_range": character.get("pickup_range"),
		"luck": character.get("luck"),
		"armor": character.get("armor"),
		"critical_chance": character.get("critical_chance"),
		"invincibility_duration": character.get("invincibility_duration"),
		"bullet_spawn_distance": character.get("bullet_spawn_distance"),
		"starting_weapon": character.get("starting_weapon"),
		"passive": character.get("passive"),
		"starting_coins": 0,
	}
