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
const WEAPON_OPTIONS: Array[Resource] = [preload("res://resourse/weapon/weapon_basic.tres"), preload("res://resourse/weapon/weapon_scatter.tres"), preload("res://resourse/weapon/weapon_arc.tres"), preload("res://resourse/weapon/weapon_driver.tres")]
const RELIC_OPTIONS: Array[Resource] = [
	preload("res://resourse/relic/relic_lucky_start.tres"),
	preload("res://resourse/relic/relic_rapid_chamber.tres"),
	preload("res://resourse/relic/relic_reinforced_charm.tres"),
	preload("res://resourse/relic/relic_swift_boots.tres"),
	preload("res://resourse/relic/relic_iron_will.tres"),
	preload("res://resourse/relic/relic_long_barrel.tres"),
	preload("res://resourse/relic/relic_brittle_core.tres"),
	preload("res://resourse/relic/relic_glass_cannon.tres"),
	preload("res://resourse/relic/relic_heavy_frame.tres"),
]
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
const MAX_WEAPON_SLOTS := 3
const MAX_WEAPON_LEVEL := 99
const SHOP_INVENTORY_SIZE := 3
const SHOP_WEAPON_PRICE := 12
const SHOP_WEAPON_UPGRADE_PRICE := 10
const SHOP_REROLL_BASE_PRICE := 5
const SHOP_REROLL_PRICE_STEP := 2
const SHOP_OFFER_TYPE_WEAPON: StringName = &"weapon"
const SHOP_OFFER_TYPE_RELIC: StringName = &"relic"
const SHOP_RARITY_COUNT := 3

const STAT_IDS: Array[StringName] = [
	&"damage", &"attack_speed", &"projectile_count", &"projectile_speed", &"range",
	&"max_health", &"armor", &"move_speed", &"pickup_range", &"luck", &"xp_gain",
	&"fire_interval", &"bullet_spawn_distance",
]
const MODIFIER_OPERATIONS: Array[StringName] = [&"flat", &"percent"]
const MODIFIER_SOURCE_TYPES: Array[StringName] = [&"character", &"relic", &"upgrade", &"synergy"]
const STAT_BOUNDS: Dictionary = {
	&"damage": Vector2(0.0, 9999.0), &"attack_speed": Vector2(0.01, 100.0),
	&"projectile_count": Vector2(1.0, 32.0), &"projectile_speed": Vector2(1.0, 5000.0),
	&"range": Vector2(1.0, 5000.0), &"max_health": Vector2(1.0, 9999.0),
	&"armor": Vector2(0.0, 9999.0), &"move_speed": Vector2(1.0, 1000.0),
	&"pickup_range": Vector2(1.0, 512.0), &"luck": Vector2(0.0, 1.0),
	&"xp_gain": Vector2(0.01, 100.0), &"fire_interval": Vector2(0.01, 10.0),
	&"bullet_spawn_distance": Vector2(0.0, 256.0),
}

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
var shop_inventory: Array[Dictionary] = []

var _resolved_character_id: StringName = &""
var _resolved_round: int = 0
var _resolved_stats: Dictionary = {}

func is_valid_stat_id(stat_id: StringName) -> bool:
	return stat_id in STAT_IDS

func get_stat_bounds(stat_id: StringName) -> Vector2:
	return STAT_BOUNDS.get(stat_id, Vector2.ZERO)

func validate_modifier(modifier: Dictionary) -> bool:
	if not is_valid_stat_id(StringName(modifier.get("stat_id", &""))): return false
	if StringName(modifier.get("operation", &"")) not in MODIFIER_OPERATIONS: return false
	if StringName(modifier.get("source_type", &"")) not in MODIFIER_SOURCE_TYPES: return false
	if not (modifier.get("value", null) is float or modifier.get("value", null) is int): return false
	return modifier.has("source_id") and StringName(modifier.get("source_id")) != &""

func get_final_stat_sheet() -> Dictionary:
	var sheet := resolve_character_stats()
	if not sheet.has("attack_speed"):
		sheet["attack_speed"] = 1.0
	return sheet.duplicate(true)

func resolve_stat_sheet(base: Dictionary, modifiers: Array) -> Dictionary:
	var result := base.duplicate(true)
	var ordered := modifiers.duplicate(true)
	ordered.sort_custom(func(a, b): return String(a.get("source_id", "")) < String(b.get("source_id", "")))
	var factors: Dictionary = {}
	for modifier in ordered:
		if not validate_modifier(modifier): continue
		var id := StringName(modifier["stat_id"])
		if modifier["operation"] == &"flat": result[id] = float(result.get(id, 0.0)) + float(modifier["value"])
		else: factors[id] = float(factors.get(id, 1.0)) * (1.0 + float(modifier["value"]))
	for id in factors: result[id] = float(result.get(id, 0.0)) * float(factors[id])
	for id in result:
		if is_valid_stat_id(StringName(id)):
			var bounds := get_stat_bounds(StringName(id)); result[id] = clampf(float(result[id]), bounds.x, bounds.y)
	return result.duplicate(true)


func reset_run() -> void:
	current_round = 1
	current_coins = 0
	owned_relics.clear()
	selected_character_id = DEFAULT_CHARACTER_ID
	equipped_weapon_ids.clear()
	boss_reward_coins = 0
	boss_defeated = false
	weapon_upgrade_levels.clear()
	shop_reroll_count = 0
	current_level = 1
	current_xp = 0
	xp_to_next_level = _xp_threshold_for_level(current_level)
	pending_level_ups = 0
	level_upgrade_stacks.clear()
	current_upgrade_offer_ids.clear()
	shop_inventory.clear()
	_reset_weapon_loadout_for_selected_character()
	_invalidate_character_resolution()
	experience_changed.emit(current_xp, xp_to_next_level, current_level)


func validate_shop_catalogs() -> bool:
	return _validate_shop_catalog(WEAPON_OPTIONS, SHOP_OFFER_TYPE_WEAPON) and _validate_shop_catalog(RELIC_OPTIONS, SHOP_OFFER_TYPE_RELIC)


func ensure_shop_inventory(rng: RandomNumberGenerator = null) -> bool:
	if not shop_inventory.is_empty():
		return shop_inventory.size() == SHOP_INVENTORY_SIZE
	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var candidates := _build_shop_offer_candidates()
	shop_inventory.resize(SHOP_INVENTORY_SIZE)
	for index in SHOP_INVENTORY_SIZE:
		shop_inventory[index] = {}
	for slot_index in SHOP_INVENTORY_SIZE:
		var selected_index := _weighted_candidate_index(candidates, generator)
		if selected_index < 0:
			break
		var selected: Dictionary = candidates.pop_at(selected_index)
		selected["slot_index"] = slot_index
		shop_inventory[slot_index] = selected
	return true


func get_shop_inventory_snapshot() -> Array[Dictionary]:
	return shop_inventory.duplicate(true)


func set_shop_offer_locked(slot_index: int, expected_offer_id: StringName, locked: bool) -> bool:
	if slot_index < 0 or slot_index >= shop_inventory.size():
		return false
	var offer: Dictionary = shop_inventory[slot_index]
	if offer.is_empty() or expected_offer_id == &"" or StringName(offer.get("offer_id", &"")) != expected_offer_id:
		return false
	if bool(offer.get("locked", false)) == locked:
		return true
	offer["locked"] = locked
	shop_inventory[slot_index] = offer
	return true


func get_shop_reroll_price() -> int:
	if shop_reroll_count < 0:
		return -1
	return SHOP_REROLL_BASE_PRICE + SHOP_REROLL_PRICE_STEP * shop_reroll_count


func try_reroll_shop(rng: RandomNumberGenerator = null) -> bool:
	if not _is_valid_shop_inventory_for_reroll():
		return false
	var price := get_shop_reroll_price()
	if price <= 0 or current_coins < price:
		return false

	var excluded_offer_ids: Dictionary = {}
	var unlocked_slots: Array[int] = []
	for slot_index in SHOP_INVENTORY_SIZE:
		var offer: Dictionary = shop_inventory[slot_index]
		if not offer.is_empty() and bool(offer.get("locked", false)):
			excluded_offer_ids[StringName(offer["offer_id"])] = true
		else:
			unlocked_slots.append(slot_index)
	if unlocked_slots.is_empty():
		return false

	var generator := rng
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.randomize()
	var candidates := _build_shop_offer_candidates(excluded_offer_ids)
	var replacement: Array[Dictionary] = shop_inventory.duplicate(true)
	for slot_index in unlocked_slots:
		replacement[slot_index] = {}
		var selected_index := _weighted_candidate_index(candidates, generator)
		if selected_index < 0:
			continue
		var selected: Dictionary = candidates.pop_at(selected_index)
		selected["slot_index"] = slot_index
		replacement[slot_index] = selected

	current_coins -= price
	shop_reroll_count += 1
	shop_inventory = replacement
	return true


func try_purchase_shop_offer(slot_index: int, expected_offer_id: StringName, rng: RandomNumberGenerator = null) -> bool:
	if slot_index < 0 or slot_index >= shop_inventory.size() or expected_offer_id == &"":
		return false
	var offer: Dictionary = shop_inventory[slot_index]
	if offer.is_empty() or StringName(offer.get("offer_id", &"")) != expected_offer_id:
		return false
	if int(offer.get("slot_index", -1)) != slot_index or not offer.has("locked") or not (offer.get("locked") is bool):
		return false
	var offer_type := StringName(offer.get("offer_type", &""))
	var content_id := StringName(offer.get("content_id", &""))
	var price := int(offer.get("price", 0))
	if content_id == &"" or price <= 0 or current_coins < price:
		return false

	var next_weapon_ids: Array[StringName] = equipped_weapon_ids.duplicate()
	var next_weapon_levels: Dictionary = weapon_upgrade_levels.duplicate(true)
	var next_relics: Array[String] = owned_relics.duplicate()
	if offer_type == SHOP_OFFER_TYPE_WEAPON:
		var weapon := get_weapon_config(content_id)
		if weapon == null or not _is_valid_shop_resource(weapon, SHOP_OFFER_TYPE_WEAPON) or expected_offer_id != StringName("weapon:%s" % content_id):
			return false
		if content_id in next_weapon_ids:
			var level := get_weapon_upgrade_level(content_id)
			if level < 1 or level >= MAX_WEAPON_LEVEL or price != SHOP_WEAPON_UPGRADE_PRICE:
				return false
			next_weapon_levels[content_id] = level + 1
		else:
			if next_weapon_ids.size() >= MAX_WEAPON_SLOTS or price != SHOP_WEAPON_PRICE:
				return false
			next_weapon_ids.append(content_id)
			next_weapon_levels[content_id] = 1
	elif offer_type == SHOP_OFFER_TYPE_RELIC:
		var relic := _get_relic_config(content_id)
		if relic == null or not _is_valid_shop_resource(relic, SHOP_OFFER_TYPE_RELIC) or expected_offer_id != StringName("relic:%s" % content_id):
			return false
		if String(content_id) in next_relics or price != int(relic.get("price")):
			return false
		next_relics.append(String(content_id))
	else:
		return false

	var excluded_offer_ids: Dictionary = {}
	for other_slot in shop_inventory:
		if not other_slot.is_empty():
			excluded_offer_ids[StringName(other_slot.get("offer_id", &""))] = true
	var candidates := _build_shop_offer_candidates_for_state(excluded_offer_ids, next_weapon_ids, next_weapon_levels, next_relics)
	var refill: Dictionary = {}
	if not candidates.is_empty():
		var generator := rng
		if generator == null:
			generator = RandomNumberGenerator.new()
			generator.randomize()
		var selected_index := _weighted_candidate_index(candidates, generator)
		if selected_index < 0:
			return false
		refill = candidates[selected_index]
		refill["slot_index"] = slot_index
		refill["locked"] = false

	current_coins -= price
	equipped_weapon_ids = next_weapon_ids
	weapon_upgrade_levels = next_weapon_levels
	owned_relics = next_relics
	if offer_type == SHOP_OFFER_TYPE_RELIC:
		_invalidate_character_resolution()
	var replacement: Array[Dictionary] = shop_inventory.duplicate(true)
	replacement[slot_index] = refill
	shop_inventory = replacement
	return true


func _is_valid_shop_inventory_for_reroll() -> bool:
	if shop_reroll_count < 0 or shop_inventory.size() != SHOP_INVENTORY_SIZE:
		return false
	var seen_offer_ids: Dictionary = {}
	for slot_index in SHOP_INVENTORY_SIZE:
		var offer: Dictionary = shop_inventory[slot_index]
		if offer.is_empty():
			continue
		var offer_id := StringName(offer.get("offer_id", &""))
		if offer_id == &"" or int(offer.get("slot_index", -1)) != slot_index or seen_offer_ids.has(offer_id):
			return false
		if not offer.has("locked") or not (offer.get("locked") is bool):
			return false
		seen_offer_ids[offer_id] = true
	return true


func _validate_shop_catalog(catalog: Array[Resource], offer_type: StringName) -> bool:
	var seen_ids: Dictionary = {}
	for resource in catalog:
		if not _is_valid_shop_resource(resource, offer_type):
			return false
		var content_id := StringName(resource.get("id"))
		if seen_ids.has(content_id):
			return false
		seen_ids[content_id] = true
	return true


func _is_valid_shop_resource(resource: Resource, offer_type: StringName) -> bool:
	if resource == null or StringName(resource.get("id")) == &"":
		return false
	var rarity := int(resource.get("rarity"))
	var weight := float(resource.get("shop_weight"))
	if rarity < 0 or rarity >= SHOP_RARITY_COUNT or not is_finite(weight) or weight <= 0.0:
		return false
	if offer_type == SHOP_OFFER_TYPE_RELIC:
		return int(resource.get("price")) > 0
	return offer_type == SHOP_OFFER_TYPE_WEAPON


func _build_shop_offer_candidates(excluded_offer_ids: Dictionary = {}) -> Array[Dictionary]:
	return _build_shop_offer_candidates_for_state(excluded_offer_ids, equipped_weapon_ids, weapon_upgrade_levels, owned_relics)


func _build_shop_offer_candidates_for_state(excluded_offer_ids: Dictionary, weapon_ids: Array[StringName], weapon_levels: Dictionary, relic_ids: Array[String]) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var seen_offer_ids: Dictionary = {}
	for weapon in WEAPON_OPTIONS:
		if not _is_valid_shop_resource(weapon, SHOP_OFFER_TYPE_WEAPON):
			continue
		var weapon_id := StringName(weapon.get("id"))
		var is_owned := weapon_id in weapon_ids
		if is_owned:
			var level := int(weapon_levels.get(weapon_id, 0))
			if level < 1 or level >= MAX_WEAPON_LEVEL:
				continue
		elif weapon_ids.size() >= MAX_WEAPON_SLOTS:
			continue
		var offer := _create_shop_offer_snapshot(weapon, SHOP_OFFER_TYPE_WEAPON, -1)
		if excluded_offer_ids.has(offer["offer_id"]) or seen_offer_ids.has(offer["offer_id"]):
			continue
		seen_offer_ids[offer["offer_id"]] = true
		candidates.append(offer)
	for relic in RELIC_OPTIONS:
		if not _is_valid_shop_resource(relic, SHOP_OFFER_TYPE_RELIC):
			continue
		var relic_id := StringName(relic.get("id"))
		if String(relic_id) in relic_ids:
			continue
		var offer := _create_shop_offer_snapshot(relic, SHOP_OFFER_TYPE_RELIC, -1)
		if excluded_offer_ids.has(offer["offer_id"]) or seen_offer_ids.has(offer["offer_id"]):
			continue
		seen_offer_ids[offer["offer_id"]] = true
		candidates.append(offer)
	return candidates


func _weighted_candidate_index(candidates: Array[Dictionary], rng: RandomNumberGenerator) -> int:
	if rng == null:
		return -1
	var total_weight := 0.0
	for candidate in candidates:
		var weight := float(candidate.get("weight", 0.0))
		if is_finite(weight) and weight > 0.0:
			total_weight += weight
	if not is_finite(total_weight) or total_weight <= 0.0:
		return -1
	var draw := rng.randf() * total_weight
	var cumulative := 0.0
	var last_valid_index := -1
	for index in candidates.size():
		var weight := float(candidates[index].get("weight", 0.0))
		if not is_finite(weight) or weight <= 0.0:
			continue
		last_valid_index = index
		cumulative += weight
		if draw < cumulative:
			return index
	return last_valid_index


func _create_shop_offer_snapshot(resource: Resource, offer_type: StringName, slot_index: int) -> Dictionary:
	var content_id := StringName(resource.get("id"))
	var price := int(resource.get("price")) if offer_type == SHOP_OFFER_TYPE_RELIC else (
		SHOP_WEAPON_UPGRADE_PRICE if content_id in equipped_weapon_ids else SHOP_WEAPON_PRICE
	)
	return {
		"slot_index": slot_index,
		"offer_id": StringName("%s:%s" % [offer_type, content_id]),
		"offer_type": offer_type,
		"content_id": content_id,
		"rarity": int(resource.get("rarity")),
		"weight": float(resource.get("shop_weight")),
		"price": price,
		"locked": false,
}


func _get_relic_config(relic_id: StringName) -> Resource:
	for relic in RELIC_OPTIONS:
		if relic != null and StringName(relic.get("id")) == relic_id:
			return relic
	return null


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
	var character = get_character_config(character_id)
	if character == null or get_weapon_config(StringName(character.get("starting_weapon"))) == null:
		return false

	selected_character_id = character_id
	_reset_weapon_loadout_for_selected_character()
	_invalidate_character_resolution()
	return true


func get_selected_character():
	return get_character_config(selected_character_id)

func equip_weapon(weapon_id: StringName) -> bool:
	return _add_weapon_to_loadout(weapon_id)

func get_weapon_config(weapon_id: StringName) -> WeaponConfig:
	for weapon in WEAPON_OPTIONS:
		if weapon != null and weapon.id == weapon_id:
			return weapon
	return null

func get_weapon_upgrade_level(weapon_id: StringName) -> int:
	if weapon_id not in equipped_weapon_ids or not weapon_upgrade_levels.has(weapon_id):
		return 0
	var level := int(weapon_upgrade_levels[weapon_id])
	return level if level >= 1 and level <= MAX_WEAPON_LEVEL else 0

func upgrade_weapon(weapon_id: StringName, price: int) -> bool:
	return try_upgrade_weapon(weapon_id, price)

func try_purchase_weapon(weapon_id: StringName, price: int) -> bool:
	if price <= 0 or current_coins < price or not _can_add_weapon_to_loadout(weapon_id):
		return false
	current_coins -= price
	equipped_weapon_ids.append(weapon_id)
	weapon_upgrade_levels[weapon_id] = 1
	return true

func try_upgrade_weapon(weapon_id: StringName, price: int) -> bool:
	var current_level := get_weapon_upgrade_level(weapon_id)
	if (
		price <= 0
		or current_coins < price
		or get_weapon_config(weapon_id) == null
		or current_level < 1
		or current_level >= MAX_WEAPON_LEVEL
	):
		return false
	current_coins -= price
	weapon_upgrade_levels[weapon_id] = current_level + 1
	return true

func get_equipped_weapon_configs() -> Array[WeaponConfig]:
	var result: Array[WeaponConfig] = []
	for weapon_id in equipped_weapon_ids:
		var config := get_weapon_config(weapon_id)
		if config != null:
			result.append(config)
	return result

func get_equipped_weapon_ids() -> Array[StringName]:
	return equipped_weapon_ids.duplicate()

func get_weapon_upgrade_levels() -> Dictionary:
	return weapon_upgrade_levels.duplicate(true)

func _can_add_weapon_to_loadout(weapon_id: StringName) -> bool:
	return (
		weapon_id != &""
		and get_weapon_config(weapon_id) != null
		and weapon_id not in equipped_weapon_ids
		and equipped_weapon_ids.size() < MAX_WEAPON_SLOTS
	)

func _add_weapon_to_loadout(weapon_id: StringName) -> bool:
	if not _can_add_weapon_to_loadout(weapon_id):
		return false
	equipped_weapon_ids.append(weapon_id)
	weapon_upgrade_levels[weapon_id] = 1
	return true

func _reset_weapon_loadout_for_selected_character() -> bool:
	equipped_weapon_ids.clear()
	weapon_upgrade_levels.clear()
	var character = get_selected_character()
	if character == null:
		push_error("Cannot reset weapon loadout: selected character is invalid")
		return false
	var starting_weapon_id := StringName(character.get("starting_weapon"))
	if get_weapon_config(starting_weapon_id) == null:
		push_error("Cannot reset weapon loadout: character starting weapon is invalid: %s" % starting_weapon_id)
		return false
	equipped_weapon_ids.append(starting_weapon_id)
	weapon_upgrade_levels[starting_weapon_id] = 1
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
	var fire_interval_multiplier := 1.0
	var damage_bonus := 0
	var projectile_count_bonus := 0
	for synergy in SYNERGY_OPTIONS:
		if synergy.applies_to_tags(tags):
			active.append(synergy.get("id"))
			fire_interval_multiplier *= float(synergy.get("fire_interval_multiplier"))
			damage_bonus += int(synergy.get("damage_bonus"))
			projectile_count_bonus += int(synergy.get("projectile_count_bonus"))
	return {"active_synergies": active, "weapon_count": weapons.size(), "tags": tags, "fire_interval_multiplier": fire_interval_multiplier, "damage_bonus": damage_bonus, "projectile_count_bonus": projectile_count_bonus}


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
	var modifiers: Array[Dictionary] = _collect_stat_modifiers(character)
	var flat: Dictionary = {}
	var percent: Dictionary = {}
	for modifier in modifiers:
		var id := StringName(modifier["stat_id"])
		if modifier["operation"] == &"flat": flat[id] = float(flat.get(id, 0.0)) + float(modifier["value"])
		else: percent[id] = float(percent.get(id, 1.0)) * (1.0 + float(modifier["value"]))
	for id in flat: stats[id] = float(stats.get(id, 0.0)) + float(flat[id])
	for id in percent: stats[id] = float(stats.get(id, 0.0)) * float(percent[id])
	if stats.has("starting_coins"): stats["starting_coins"] = float(stats["starting_coins"]) # preserved special stat
	stats["attack_speed"] = 1.0

	stats["max_health"] = clampi(roundi(float(stats["max_health"])), 1, 999)
	stats["move_speed"] = _round_stat(clampf(float(stats["move_speed"]), 1.0, 1000.0))
	stats["fire_interval"] = _round_stat(clampf(float(stats["fire_interval"]), 0.01, 10.0))
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

func _collect_stat_modifiers(character: Resource) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for relic_id in owned_relics.duplicate():
		var relic := _get_relic_config(StringName(relic_id))
		if relic == null: continue
		for effect_index in 2:
			if effect_index == 1 and not bool(relic.get("has_secondary_effect")): continue
			var value_key := "effect_value" if effect_index == 0 else "secondary_effect_value"
			var type_key := "effect_type" if effect_index == 0 else "secondary_effect_type"
			var stat := &""; var op := &"flat"; var amount := float(relic.get(value_key))
			var effect_type := int(relic.get(type_key))
			match effect_type:
				RelicData.EffectType.STARTING_COINS: stat = &"starting_coins"
				RelicData.EffectType.FIRE_INTERVAL_MULTIPLIER: stat = &"fire_interval"; op = &"percent"; amount -= 1.0
				RelicData.EffectType.MAX_HEALTH_BONUS: stat = &"max_health"
				RelicData.EffectType.MOVE_SPEED_MULTIPLIER: stat = &"move_speed"; op = &"percent"; amount -= 1.0
				RelicData.EffectType.INVINCIBILITY_DURATION_BONUS: stat = &"invincibility_duration"
				RelicData.EffectType.BULLET_SPAWN_DISTANCE_BONUS: stat = &"bullet_spawn_distance"
				RelicData.EffectType.DAMAGE_BONUS: stat = &"damage"
			if stat != &"": result.append(_modifier(stat, op, amount, StringName("%s_%d" % [relic_id, effect_index]), &"relic"))
	for upgrade_id in level_upgrade_stacks:
		var stacks := maxi(int(level_upgrade_stacks[upgrade_id]), 0)
		var upgrade := get_level_upgrade(StringName(upgrade_id))
		if stacks <= 0 or upgrade == null: continue
		var value := float(upgrade.get("effect_value"))
		var stat := &""; var op := &"flat"; var amount := value
		match int(upgrade.get("effect_type")):
			UpgradeConfigScript.EffectType.MAX_HEALTH: stat = &"max_health"
			UpgradeConfigScript.EffectType.MOVE_SPEED_MULTIPLIER: stat = &"move_speed"; op = &"percent"; amount = pow(value, stacks) - 1.0
			UpgradeConfigScript.EffectType.DAMAGE: stat = &"damage"
			UpgradeConfigScript.EffectType.ATTACK_SPEED_MULTIPLIER: stat = &"fire_interval"; op = &"percent"; amount = pow(1.0 / value, stacks) - 1.0
			UpgradeConfigScript.EffectType.PICKUP_RANGE_MULTIPLIER: stat = &"pickup_range"; op = &"percent"; amount = pow(value, stacks) - 1.0
			UpgradeConfigScript.EffectType.LUCK: stat = &"luck"
		if stat != &"": result.append(_modifier(stat, op, amount if op == &"percent" else amount * stacks, StringName(upgrade_id), &"upgrade"))
	result.sort_custom(func(a, b): return String(a["source_id"]) < String(b["source_id"]))
	return result

func _modifier(stat_id: StringName, operation: StringName, value: float, source_id: StringName, source_type: StringName) -> Dictionary:
	return {"stat_id": stat_id, "operation": operation, "value": value, "source_id": source_id, "source_type": source_type}


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
