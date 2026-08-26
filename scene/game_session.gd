extends Node

const UpgradeConfigScript = preload("res://resourse/progression/upgrade_config.gd")

signal experience_changed(current_xp: int, xp_to_next_level: int, current_level: int)
signal level_up_queued(new_levels: int)
signal level_upgrade_applied(upgrade_id: StringName)

const DEFAULT_CHARACTER_ID: StringName = &"gunslinger"
const CHARACTER_OPTIONS: Array[Resource] = [
	preload("res://resourse/character/character_gunslinger.tres"),
	preload("res://resourse/character/character_scout.tres"),
	preload("res://resourse/character/character_guardian.tres"),
]
const WEAPON_OPTIONS: Array[Resource] = [preload("res://resourse/weapon/weapon_basic.tres"), preload("res://resourse/weapon/weapon_scatter.tres")]
const SYNERGY_OPTIONS: Array[Resource] = [preload("res://resourse/weapon/synergy_kinetic_pair.tres")]
const UPGRADE_OPTIONS: Array[Resource] = [
	preload("res://resourse/progression/upgrade_max_health.tres"),
	preload("res://resourse/progression/upgrade_move_speed.tres"),
	preload("res://resourse/progression/upgrade_damage.tres"),
	preload("res://resourse/progression/upgrade_attack_speed.tres"),
	preload("res://resourse/progression/upgrade_pickup_range.tres"),
	preload("res://resourse/progression/upgrade_luck.tres"),
]
const BASE_XP_THRESHOLD := 5
const XP_THRESHOLD_STEP := 3

var current_round: int = 1
var current_coins: int = 0
var owned_relics: Array[String] = []
var selected_character_id: StringName = DEFAULT_CHARACTER_ID
var equipped_weapon_ids: Array[StringName] = [&"basic"]
var boss_reward_coins: int = 0
var boss_defeated: bool = false
var weapon_upgrade_levels: Dictionary = {&"basic": 1}
var shop_reroll_count: int = 0
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = BASE_XP_THRESHOLD
var pending_level_ups: int = 0
var level_upgrade_stacks: Dictionary = {}
var current_upgrade_offer_ids: Array[StringName] = []

var _resolved_character_id: StringName = &""
var _resolved_round: int = 0
var _resolved_stats: Dictionary = {}


func reset_run() -> void:
	current_round = 1
	current_coins = 0
	owned_relics.clear()
	selected_character_id = DEFAULT_CHARACTER_ID
	equipped_weapon_ids = [&"basic"]
	boss_reward_coins = 0
	boss_defeated = false
	weapon_upgrade_levels = {&"basic": 1}
	shop_reroll_count = 0
	current_level = 1
	current_xp = 0
	xp_to_next_level = _xp_threshold_for_level(current_level)
	pending_level_ups = 0
	level_upgrade_stacks.clear()
	current_upgrade_offer_ids.clear()
	_invalidate_character_resolution()
	experience_changed.emit(current_xp, xp_to_next_level, current_level)


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

func equip_weapon(weapon_id: StringName) -> bool:
	for weapon in WEAPON_OPTIONS:
		if weapon.get("id") != weapon_id:
			continue
		if weapon_id not in equipped_weapon_ids:
			equipped_weapon_ids.append(weapon_id)
		return true
	return false

func get_weapon_upgrade_level(weapon_id: StringName) -> int:
	return maxi(int(weapon_upgrade_levels.get(weapon_id, 1)), 1)

func upgrade_weapon(weapon_id: StringName, price: int) -> bool:
	if price <= 0 or current_coins < price or weapon_id not in equipped_weapon_ids:
		return false
	current_coins -= price
	weapon_upgrade_levels[weapon_id] = get_weapon_upgrade_level(weapon_id) + 1
	return true

func reroll_shop(price: int) -> bool:
	if price <= 0 or current_coins < price:
		return false
	current_coins -= price
	shop_reroll_count += 1
	return true

func resolve_weapon_synergies() -> Dictionary:
	var weapons: Array[Resource] = []
	for weapon_id in equipped_weapon_ids:
		for weapon in WEAPON_OPTIONS:
			if weapon.get("id") == weapon_id:
				weapons.append(weapon)
	var tags: Array[StringName] = []
	for weapon in weapons:
		for tag in weapon.get("tags"):
			if tag not in tags:
				tags.append(tag)
	var active: Array[StringName] = []
	for synergy in SYNERGY_OPTIONS:
		if synergy.applies_to_tags(tags):
			active.append(synergy.get("id"))
	return {"active_synergies": active, "weapon_count": weapons.size(), "tags": tags}


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

	_apply_level_upgrade_stacks(stats)

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

func add_boss_reward(amount: int) -> bool:
	if amount <= 0 or boss_defeated:
		return false
	boss_reward_coins += amount
	current_coins += amount
	boss_defeated = true
	return true


func add_experience(amount: int) -> int:
	if amount <= 0:
		return 0
	current_xp += amount
	var levels_gained := 0
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		pending_level_ups += 1
		levels_gained += 1
		xp_to_next_level = _xp_threshold_for_level(current_level)
	experience_changed.emit(current_xp, xp_to_next_level, current_level)
	if levels_gained > 0:
		level_up_queued.emit(levels_gained)
	return levels_gained


func roll_level_up_options(rng: RandomNumberGenerator = null) -> Array[Resource]:
	current_upgrade_offer_ids.clear()
	if pending_level_ups <= 0:
		return []
	var available := UPGRADE_OPTIONS.duplicate()
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var result: Array[Resource] = []
	while result.size() < 3 and not available.is_empty():
		var index := generator.randi_range(0, available.size() - 1)
		var upgrade: Resource = available.pop_at(index)
		result.append(upgrade)
		current_upgrade_offer_ids.append(StringName(upgrade.get("id")))
	return result


func apply_level_upgrade(upgrade_id: StringName) -> Resource:
	if pending_level_ups <= 0 or upgrade_id not in current_upgrade_offer_ids:
		return null
	var upgrade := get_level_upgrade(upgrade_id)
	if upgrade == null:
		return null
	level_upgrade_stacks[upgrade_id] = int(level_upgrade_stacks.get(upgrade_id, 0)) + 1
	pending_level_ups -= 1
	current_upgrade_offer_ids.clear()
	_invalidate_character_resolution()
	level_upgrade_applied.emit(upgrade_id)
	return upgrade


func get_level_upgrade(upgrade_id: StringName) -> Resource:
	for upgrade in UPGRADE_OPTIONS:
		if upgrade != null and StringName(upgrade.get("id")) == upgrade_id:
			return upgrade
	return null


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


func _xp_threshold_for_level(level: int) -> int:
	return BASE_XP_THRESHOLD + maxi(level - 1, 0) * XP_THRESHOLD_STEP


func _apply_level_upgrade_stacks(stats: Dictionary) -> void:
	for upgrade_id in level_upgrade_stacks:
		var stacks := maxi(int(level_upgrade_stacks[upgrade_id]), 0)
		if stacks == 0:
			continue
		var upgrade := get_level_upgrade(StringName(upgrade_id))
		if upgrade == null:
			continue
		var value := float(upgrade.get("effect_value"))
		match int(upgrade.get("effect_type")):
			UpgradeConfigScript.EffectType.MAX_HEALTH:
				stats["max_health"] += roundi(value) * stacks
			UpgradeConfigScript.EffectType.MOVE_SPEED_MULTIPLIER:
				stats["move_speed"] *= pow(value, stacks)
			UpgradeConfigScript.EffectType.DAMAGE:
				stats["damage"] += roundi(value) * stacks
			UpgradeConfigScript.EffectType.ATTACK_SPEED_MULTIPLIER:
				stats["fire_interval"] /= pow(value, stacks)
			UpgradeConfigScript.EffectType.PICKUP_RANGE_MULTIPLIER:
				stats["pickup_range"] *= pow(value, stacks)
			UpgradeConfigScript.EffectType.LUCK:
				stats["luck"] += value * stacks


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
