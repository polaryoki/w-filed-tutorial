extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_root().get_node("GameSession")
	var resources_before := _capture_resources(session)
	_test_seeded_generation(session)
	_test_candidate_eligibility(session)
	_test_exhausted_candidates(session)
	_test_weighted_picker(session)
	_expect(resources_before == _capture_resources(session), "weighted generation must not mutate WeaponConfig or RelicData")
	_finish()

func _test_seeded_generation(session: Node) -> void:
	session.reset_run()
	var first_rng := RandomNumberGenerator.new()
	first_rng.seed = 1102
	_expect(session.ensure_shop_inventory(first_rng), "seeded inventory generation must succeed")
	var first: Array[Dictionary] = session.get_shop_inventory_snapshot()
	_expect(first.size() == 3 and first.all(func(slot): return not slot.is_empty()), "three slots must generate while legal candidates exist")
	_assert_inventory_invariants(session, first)
	_expect(first.any(func(slot): return slot.offer_type == &"weapon") and first.any(func(slot): return slot.offer_type == &"relic"), "Weapon and Relic offers must coexist for the controlled seed")

	var unchanged := first.duplicate(true)
	var other_rng := RandomNumberGenerator.new()
	other_rng.seed = 9999
	_expect(session.ensure_shop_inventory(other_rng) and session.get_shop_inventory_snapshot() == unchanged, "ensure must not reroll initialized inventory")

	session.reset_run()
	var repeat_rng := RandomNumberGenerator.new()
	repeat_rng.seed = 1102
	_expect(session.ensure_shop_inventory(repeat_rng) and session.get_shop_inventory_snapshot() == first, "the same seed and state must reproduce inventory")

func _test_candidate_eligibility(session: Node) -> void:
	session.reset_run()
	for relic in session.RELIC_OPTIONS:
		session.add_relic(String(relic.id))
	session.weapon_upgrade_levels[&"basic"] = session.MAX_WEAPON_LEVEL
	session.equipped_weapon_ids.append(&"scatter")
	session.weapon_upgrade_levels[&"scatter"] = 2
	session.equipped_weapon_ids.append(&"arc")
	session.weapon_upgrade_levels[&"arc"] = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = 22
	_expect(session.ensure_shop_inventory(rng), "filtered inventory generation must succeed")
	var inventory: Array[Dictionary] = session.get_shop_inventory_snapshot()
	var populated := inventory.filter(func(slot): return not slot.is_empty())
	_expect(populated.size() == 2, "only two owned non-max Weapons should remain eligible")
	_expect(populated.all(func(slot): return slot.offer_type == &"weapon" and slot.content_id in [&"scatter", &"arc"] and slot.price == session.SHOP_WEAPON_UPGRADE_PRICE), "owned relics, max-level Weapons, and unowned Weapons at full capacity must be excluded")
	_expect(inventory[2].is_empty(), "candidate exhaustion must leave an empty slot")
	_assert_inventory_invariants(session, inventory)

func _test_exhausted_candidates(session: Node) -> void:
	session.reset_run()
	for relic in session.RELIC_OPTIONS:
		session.add_relic(String(relic.id))
	for weapon in session.WEAPON_OPTIONS:
		if weapon.id not in session.equipped_weapon_ids:
			session.equipped_weapon_ids.append(weapon.id)
		session.weapon_upgrade_levels[weapon.id] = session.MAX_WEAPON_LEVEL
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_expect(session.ensure_shop_inventory(rng), "empty legal pool must terminate normally")
	_expect(session.get_shop_inventory_snapshot().all(func(slot): return slot.is_empty()), "no legal candidates must produce only empty slots")

func _test_weighted_picker(session: Node) -> void:
	var candidates: Array[Dictionary] = [
		{"offer_id": &"weapon:a", "weight": NAN},
		{"offer_id": &"weapon:b", "weight": 0.0},
		{"offer_id": &"relic:c", "weight": 1.0},
		{"offer_id": &"relic:d", "weight": 3.0},
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for _draw in 32:
		var index: int = session._weighted_candidate_index(candidates, rng)
		_expect(index in [2, 3], "weighted draw must ignore invalid weights and stay in bounds")
	var shrinking := candidates.slice(2)
	var selected_ids: Dictionary = {}
	while not shrinking.is_empty():
		var index: int = session._weighted_candidate_index(shrinking, rng)
		_expect(index >= 0 and index < shrinking.size(), "weighted draw index must remain valid as pool shrinks")
		var selected: Dictionary = shrinking.pop_at(index)
		_expect(not selected_ids.has(selected.offer_id), "sampling without replacement must not select a candidate twice")
		selected_ids[selected.offer_id] = true
	_expect(selected_ids.size() == 2, "each selection must remove one candidate from the pool")

func _assert_inventory_invariants(session: Node, inventory: Array[Dictionary]) -> void:
	var offer_ids: Dictionary = {}
	for slot in inventory:
		if slot.is_empty(): continue
		_expect(slot.offer_type in [&"weapon", &"relic"], "offer type must belong to the mixed catalog")
		_expect(slot.offer_id == StringName("%s:%s" % [slot.offer_type, slot.content_id]), "offer ID must be type-qualified")
		_expect(not offer_ids.has(slot.offer_id), "inventory generation must sample without replacement")
		offer_ids[slot.offer_id] = true
		_expect(is_finite(float(slot.weight)) and float(slot.weight) > 0.0, "generated offer weight must be finite and positive")
	_expect(_contains_primitives_only(inventory), "inventory snapshots must not contain Resource or Object references")

func _capture_resources(session: Node) -> Array:
	var state: Array = []
	for resource in session.WEAPON_OPTIONS:
		state.append({"type": &"weapon", "id": resource.id, "rarity": resource.rarity, "weight": resource.shop_weight, "stats": resource.resolved_stats()})
	for resource in session.RELIC_OPTIONS:
		state.append({"type": &"relic", "id": resource.id, "rarity": resource.rarity, "weight": resource.shop_weight, "price": resource.price, "effect_type": resource.effect_type, "effect_value": resource.effect_value})
	return state

func _contains_primitives_only(value: Variant) -> bool:
	if value is Resource or value is Object: return false
	if value is Array:
		for item in value:
			if not _contains_primitives_only(item): return false
	if value is Dictionary:
		for key in value:
			if not _contains_primitives_only(key) or not _contains_primitives_only(value[key]): return false
	return true

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _finish() -> void:
	for failure in failures: push_error(failure)
	print("Phase 11 Task 2 smoke passed" if failures.is_empty() else "Phase 11 Task 2 smoke failed")
	quit(0 if failures.is_empty() else 1)
