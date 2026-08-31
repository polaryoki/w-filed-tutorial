extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_root().get_node("GameSession")
	session.reset_run()
	var resources_before := _capture_resources(session)
	_expect(session.get_shop_reroll_price() == 5, "initial reroll price must be 5")

	var rng := RandomNumberGenerator.new()
	rng.seed = 1104
	_expect(session.ensure_shop_inventory(rng), "inventory must initialize")
	var initial: Array[Dictionary] = session.get_shop_inventory_snapshot()
	var locked_index := _first_populated_slot(initial)
	_expect(locked_index >= 0, "reroll smoke requires a populated offer")
	if locked_index >= 0:
		var locked_id: StringName = initial[locked_index].offer_id
		_expect(session.set_shop_offer_locked(locked_index, locked_id, true), "offer must lock")
		var locked_offer: Dictionary = session.get_shop_inventory_snapshot()[locked_index]
		session.current_coins = 30
		var before_success_state := rng.state
		_expect(session.try_reroll_shop(rng), "funded reroll must succeed")
		var after_first: Array[Dictionary] = session.get_shop_inventory_snapshot()
		_expect(session.current_coins == 25 and session.shop_reroll_count == 1, "first reroll must deduct 5 and increment once")
		_expect(session.get_shop_reroll_price() == 7, "second reroll price must be 7")
		_expect(after_first[locked_index] == locked_offer and bool(after_first[locked_index].locked), "locked offer and slot must remain unchanged")
		_expect(_valid_inventory(session, after_first), "rerolled inventory must be legal, unique, and primitive")
		_expect(rng.state != before_success_state, "successful reroll must consume injected RNG")

		_expect(session.try_reroll_shop(rng), "second funded reroll must succeed")
		_expect(session.current_coins == 18 and session.shop_reroll_count == 2, "second reroll must deduct 7")
		_expect(session.get_shop_reroll_price() == 9, "third reroll price must be 9")

		var failure_inventory: Array[Dictionary] = session.get_shop_inventory_snapshot()
		session.current_coins = 8
		var failure_rng_state := rng.state
		_expect(not session.try_reroll_shop(rng), "insufficient coins must fail")
		_expect(session.current_coins == 8 and session.shop_reroll_count == 2, "failed reroll must preserve coins and counter")
		_expect(session.get_shop_reroll_price() == 9 and session.get_shop_inventory_snapshot() == failure_inventory, "failed reroll must preserve price and inventory")
		_expect(rng.state == failure_rng_state, "validation failure must not consume RNG")

		session.shop_reroll_count = -1
		failure_rng_state = rng.state
		_expect(not session.try_reroll_shop(rng), "corrupt reroll counter must fail")
		_expect(session.current_coins == 8 and session.get_shop_inventory_snapshot() == failure_inventory and rng.state == failure_rng_state, "corrupt-counter failure must be atomic")
		session.shop_reroll_count = 2
		session.shop_inventory[locked_index]["slot_index"] = -1
		failure_rng_state = rng.state
		_expect(not session.try_reroll_shop(rng), "malformed inventory must fail")
		_expect(session.current_coins == 8 and rng.state == failure_rng_state, "malformed-inventory failure must preserve coins and RNG")
		session.shop_inventory = failure_inventory.duplicate(true)

		for index in session.shop_inventory.size():
			if not session.shop_inventory[index].is_empty():
				session.set_shop_offer_locked(index, session.shop_inventory[index].offer_id, true)
		session.current_coins = 100
		var all_locked_before: Array[Dictionary] = session.get_shop_inventory_snapshot()
		failure_rng_state = rng.state
		_expect(not session.try_reroll_shop(rng), "all-locked inventory must fail")
		_expect(session.current_coins == 100 and session.get_shop_inventory_snapshot() == all_locked_before and rng.state == failure_rng_state, "all-locked failure must be atomic")

	var defensive: Array[Dictionary] = session.get_shop_inventory_snapshot()
	if not defensive.is_empty():
		defensive[0] = {}
		_expect(session.get_shop_inventory_snapshot() != defensive, "snapshot must be defensive")
	_expect(resources_before == _capture_resources(session), "reroll must not mutate Resources")

	session.reset_run()
	var uninitialized_rng := RandomNumberGenerator.new()
	uninitialized_rng.seed = 77
	var uninitialized_state := uninitialized_rng.state
	session.current_coins = 100
	_expect(not session.try_reroll_shop(uninitialized_rng), "uninitialized inventory must fail")
	_expect(session.current_coins == 100 and session.shop_reroll_count == 0 and session.get_shop_reroll_price() == 5, "uninitialized failure must preserve reroll state")
	_expect(uninitialized_rng.state == uninitialized_state, "uninitialized failure must not consume RNG")

	_test_eligibility_and_exhaustion(session)
	session.reset_run()
	_expect(session.shop_inventory.is_empty() and session.shop_reroll_count == 0 and session.get_shop_reroll_price() == 5, "reset must clear reroll state")
	_finish()

func _test_eligibility_and_exhaustion(session: Node) -> void:
	session.reset_run()
	for relic in session.RELIC_OPTIONS:
		session.owned_relics.append(String(relic.id))
	session.equipped_weapon_ids.clear()
	session.equipped_weapon_ids.append_array([&"basic", &"scatter", &"arc"])
	session.weapon_upgrade_levels = {&"basic": session.MAX_WEAPON_LEVEL, &"scatter": session.MAX_WEAPON_LEVEL, &"arc": session.MAX_WEAPON_LEVEL}
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	_expect(session.ensure_shop_inventory(rng), "exhausted inventory must initialize")
	_expect(_populated_count(session.get_shop_inventory_snapshot()) == 0, "ineligible exhausted catalog must produce empty slots")
	session.current_coins = 5
	_expect(session.try_reroll_shop(rng), "empty unlocked slots may reroll successfully")
	_expect(_populated_count(session.get_shop_inventory_snapshot()) == 0, "candidate exhaustion must retain empty slots")

func _valid_inventory(session: Node, inventory: Array[Dictionary]) -> bool:
	if inventory.size() != session.SHOP_INVENTORY_SIZE: return false
	var seen: Dictionary = {}
	for offer in inventory:
		if offer.is_empty(): continue
		if seen.has(offer.offer_id) or offer.offer_id != StringName("%s:%s" % [offer.offer_type, offer.content_id]): return false
		if offer.has("resource") or offer.has("object"): return false
		seen[offer.offer_id] = true
	return true

func _first_populated_slot(inventory: Array[Dictionary]) -> int:
	for index in inventory.size():
		if not inventory[index].is_empty(): return index
	return -1

func _populated_count(inventory: Array[Dictionary]) -> int:
	var count := 0
	for offer in inventory:
		if not offer.is_empty(): count += 1
	return count

func _capture_resources(session: Node) -> Array:
	var state: Array = []
	for resource in session.WEAPON_OPTIONS:
		state.append({"type": &"weapon", "id": resource.id, "rarity": resource.rarity, "weight": resource.shop_weight, "stats": resource.resolved_stats()})
	for resource in session.RELIC_OPTIONS:
		state.append({"type": &"relic", "id": resource.id, "rarity": resource.rarity, "weight": resource.shop_weight, "price": resource.price, "effect_type": resource.effect_type, "effect_value": resource.effect_value})
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _finish() -> void:
	for failure in failures: push_error(failure)
	print("Phase 11 Task 4 smoke passed" if failures.is_empty() else "Phase 11 Task 4 smoke failed")
	quit(0 if failures.is_empty() else 1)
