extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_root().get_node("GameSession")
	session.reset_run()
	var resources_before := _capture_resources(session)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1102
	_expect(session.ensure_shop_inventory(rng), "seeded inventory must initialize")
	var original: Array[Dictionary] = session.get_shop_inventory_snapshot()
	var target_index := _first_populated_slot(original)
	_expect(target_index >= 0, "lock smoke requires a populated offer")
	if target_index >= 0:
		var target_id: StringName = original[target_index].offer_id
		var rng_state: int = rng.state
		_expect(session.set_shop_offer_locked(target_index, target_id, true), "a populated offer can be locked")
		var locked: Array[Dictionary] = session.get_shop_inventory_snapshot()
		_expect(locked[target_index].locked, "target offer must report locked")
		_expect(_only_lock_changed(original, locked, target_index), "locking must affect only the target offer")
		_expect(rng.state == rng_state, "lock transaction must not consume RNG")

		var idempotent_before := locked.duplicate(true)
		_expect(session.set_shop_offer_locked(target_index, target_id, true), "repeated lock is an idempotent success")
		_expect(session.get_shop_inventory_snapshot() == idempotent_before, "repeated lock must not change state")
		_expect(session.set_shop_offer_locked(target_index, target_id, false), "a locked offer can be unlocked")
		_expect(session.get_shop_inventory_snapshot() == original, "unlock must restore the original inventory state")

		var invalid_before: Array[Dictionary] = session.get_shop_inventory_snapshot()
		_expect(not session.set_shop_offer_locked(target_index, &"weapon:stale", true), "stale offer ID must be rejected")
		_expect(not session.set_shop_offer_locked(target_index, &"", true), "empty offer ID must be rejected")
		_expect(not session.set_shop_offer_locked(-1, target_id, true), "negative slot must be rejected")
		_expect(not session.set_shop_offer_locked(session.SHOP_INVENTORY_SIZE, target_id, true), "out-of-range slot must be rejected")
		_expect(session.get_shop_inventory_snapshot() == invalid_before, "invalid lock requests must not mutate inventory")

		session.shop_inventory[2] = {}
		var empty_before: Array[Dictionary] = session.get_shop_inventory_snapshot()
		_expect(not session.set_shop_offer_locked(2, target_id, true), "empty slot must reject lock")
		_expect(session.get_shop_inventory_snapshot() == empty_before, "empty-slot rejection must be a no-op")

		var defensive: Array[Dictionary] = session.get_shop_inventory_snapshot()
		defensive[target_index]["locked"] = true
		_expect(not session.get_shop_inventory_snapshot()[target_index].locked, "snapshot mutation must not lock authoritative inventory")

		var ensure_before: Array[Dictionary] = session.get_shop_inventory_snapshot()
		var unused_rng := RandomNumberGenerator.new()
		unused_rng.seed = 9
		var unused_state: int = unused_rng.state
		_expect(session.ensure_shop_inventory(unused_rng), "ensure remains valid for initialized inventory")
		_expect(session.get_shop_inventory_snapshot() == ensure_before and unused_rng.state == unused_state, "ensure must neither reroll nor consume RNG after lock operations")

		_expect(session.set_shop_offer_locked(target_index, target_id, true), "target can be locked before reset")
		session.reset_run()
		_expect(session.get_shop_inventory_snapshot().is_empty(), "reset_run must clear offers and lock state")
	_expect(resources_before == _capture_resources(session), "lock transactions must not mutate WeaponConfig or RelicData")
	_finish()

func _first_populated_slot(inventory: Array[Dictionary]) -> int:
	for index in inventory.size():
		if not inventory[index].is_empty(): return index
	return -1

func _only_lock_changed(before: Array[Dictionary], after: Array[Dictionary], target_index: int) -> bool:
	if before.size() != after.size(): return false
	for index in before.size():
		var expected: Dictionary = before[index].duplicate(true)
		if index == target_index: expected["locked"] = true
		if expected != after[index]: return false
	return true

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
	print("Phase 11 Task 3 smoke passed" if failures.is_empty() else "Phase 11 Task 3 smoke failed")
	quit(0 if failures.is_empty() else 1)
