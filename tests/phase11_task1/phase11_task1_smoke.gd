extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_root().get_node("GameSession")
	session.reset_run()
	var resource_state := _capture_resource_state(session)
	_expect(session.validate_shop_catalogs(), "Weapon and Relic catalogs must be valid")
	_test_catalog(session.WEAPON_OPTIONS, "Weapon")
	_test_catalog(session.RELIC_OPTIONS, "Relic")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1102
	_expect(session.ensure_shop_inventory(rng), "inventory initialization must succeed")
	var snapshot: Array[Dictionary] = session.get_shop_inventory_snapshot()
	_expect(snapshot.size() == session.SHOP_INVENTORY_SIZE and snapshot.size() == 3, "inventory must contain exactly three ordered slots")
	for slot in snapshot:
		if not slot.is_empty():
			_expect(slot.offer_id == StringName("%s:%s" % [slot.offer_type, slot.content_id]), "populated offer ID must be type-qualified")
	_expect(_contains_primitives_only(snapshot), "inventory must contain runtime primitive snapshots without Resources")

	session.shop_inventory[2] = {}
	snapshot = session.get_shop_inventory_snapshot()
	_expect(snapshot[2].is_empty(), "an inventory slot may be empty")
	var original_content_id: StringName = snapshot[0].content_id
	snapshot[0]["locked"] = true
	snapshot[0]["content_id"] = &"mutated"
	snapshot[2]["injected"] = true
	var unchanged: Array[Dictionary] = session.get_shop_inventory_snapshot()
	_expect(not unchanged[0].locked and unchanged[0].content_id == original_content_id and unchanged[2].is_empty(), "snapshot getter must return a deep defensive copy")
	_expect(resource_state == _capture_resource_state(session), "inventory initialization must not mutate WeaponConfig or RelicData")

	session.reset_run()
	_expect(session.get_shop_inventory_snapshot().is_empty(), "reset_run must clear temporary Shop inventory")
	_expect(resource_state == _capture_resource_state(session), "reset_run must not mutate Shop Resources")
	_finish()

func _test_catalog(catalog: Array, label: String) -> void:
	var ids: Dictionary = {}
	for resource in catalog:
		var content_id := StringName(resource.get("id"))
		var rarity := int(resource.get("rarity"))
		var weight := float(resource.get("shop_weight"))
		_expect(content_id != &"" and not ids.has(content_id), "%s catalog IDs must be non-empty and unique" % label)
		ids[content_id] = true
		_expect(rarity >= 0 and rarity < 3, "%s rarity must use the finite Phase 11 enum" % label)
		_expect(is_finite(weight) and weight > 0.0, "%s shop_weight must be finite and positive" % label)

func _capture_resource_state(session: Node) -> Array:
	var state: Array = []
	for resource in session.WEAPON_OPTIONS:
		state.append({"type": &"weapon", "id": resource.id, "rarity": resource.rarity, "weight": resource.shop_weight, "stats": resource.resolved_stats()})
	for resource in session.RELIC_OPTIONS:
		state.append({"type": &"relic", "id": resource.id, "rarity": resource.rarity, "weight": resource.shop_weight, "price": resource.price, "effect_type": resource.effect_type, "effect_value": resource.effect_value})
	return state

func _contains_primitives_only(value: Variant) -> bool:
	if value is Resource or value is Object:
		return false
	if value is Array:
		for item in value:
			if not _contains_primitives_only(item): return false
	if value is Dictionary:
		for key in value:
			if not _contains_primitives_only(key) or not _contains_primitives_only(value[key]): return false
	return true

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	for failure in failures:
		push_error(failure)
	print("Phase 11 Task 1 smoke passed" if failures.is_empty() else "Phase 11 Task 1 smoke failed")
	quit(0 if failures.is_empty() else 1)
