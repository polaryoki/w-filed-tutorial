extends Control
@onready var round_label: Label = $CenterContainer/PanelContainer/MarginContainer/Layout/RoundLabel
@onready var gold_label: Label = $CenterContainer/PanelContainer/MarginContainer/Layout/GoldLabel
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/Layout/ContinueButton
var weapon_items: VBoxContainer
var slot_items: VBoxContainer
var reroll_button: Button
var displayed_weapons: Array = []
var _rng := RandomNumberGenerator.new()
func _ready() -> void:
	round_label.text = "Round %d" % GameSession.current_round
	var layout := $CenterContainer/PanelContainer/MarginContainer/Layout
	var old := layout.get_node_or_null("RelicItems"); if old: old.queue_free()
	# Prefer the authored ShopSlots/RerollButton nodes.  The fallback keeps the
	# scene backwards compatible with the Phase 10 layout.
	slot_items = layout.get_node_or_null("ShopSlots") as VBoxContainer
	if slot_items == null:
		slot_items = VBoxContainer.new(); slot_items.name = "ShopSlots"; layout.add_child(slot_items)
	reroll_button = layout.get_node_or_null("RerollButton") as Button
	if reroll_button == null:
		reroll_button = Button.new(); reroll_button.name = "RerollButton"; layout.add_child(reroll_button)
	if not reroll_button.pressed.is_connected(_on_reroll_pressed):
		reroll_button.pressed.connect(_on_reroll_pressed)
	weapon_items = layout.get_node_or_null("WeaponItems") as VBoxContainer
	if weapon_items == null:
		weapon_items = VBoxContainer.new(); weapon_items.name = "WeaponItems"; layout.add_child(weapon_items)
	displayed_weapons = GameSession.WEAPON_OPTIONS.duplicate()
	GameSession.ensure_shop_inventory(_rng); _refresh_weapon_ui(); _refresh_shop(); continue_button.grab_focus()
func _refresh_shop() -> void:
	if not is_instance_valid(slot_items) or not is_instance_valid(reroll_button): return
	round_label.text = "Round %d" % GameSession.current_round
	gold_label.text = "Coins: %d" % GameSession.current_coins; reroll_button.text = "Reroll %d" % GameSession.get_shop_reroll_price()
	for c in slot_items.get_children():
		slot_items.remove_child(c)
		c.queue_free()
	var snap: Array[Dictionary] = GameSession.get_shop_inventory_snapshot()
	# Always render exactly three rows, including empty slots, from a fresh snapshot.
	for i in GameSession.SHOP_INVENTORY_SIZE:
		var offer: Dictionary = snap[i] if i < snap.size() else {}
		var row := HBoxContainer.new(); row.name = "Slot%d" % i
		var info := Label.new(); info.name = "Info"; info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var buy := Button.new(); buy.name = "PurchaseButton"
		var upgrade := Button.new(); upgrade.name = "UpgradeButton"; upgrade.visible = false
		var lock := Button.new(); lock.name = "LockButton"
		row.add_child(info); row.add_child(buy); row.add_child(lock); row.add_child(upgrade); slot_items.add_child(row)
		if offer.is_empty(): info.text = "Slot %d: Unavailable" % (i + 1); buy.text = "Empty"; buy.disabled = true; lock.disabled = true; continue
		var weapon: bool = offer.get("offer_type") == &"weapon"; var id := StringName(offer.get("content_id")); var level := GameSession.get_weapon_upgrade_level(id) if weapon else 0
		info.text = "%s %s%s  Rarity %d  Price %d" % ["Weapon" if weapon else "Relic", String(id), (" Lv.%d" % level) if weapon else "", int(offer.get("rarity", 0)), int(offer.get("price", 0))]
		buy.text = "Purchase" if weapon and level <= 0 else ("Purchase" if not weapon else "Upgrade")
		upgrade.visible = weapon and level > 0
		upgrade.text = "Upgrade"
		buy.disabled = GameSession.current_coins < int(offer.get("price", 0))
		var oid := StringName(offer.get("offer_id", &"")); buy.pressed.connect(_on_purchase_pressed.bind(i, oid))
		upgrade.pressed.connect(_on_purchase_pressed.bind(i, oid))
		var is_locked := bool(offer.get("locked", false)); lock.text = "Unlock" if is_locked else "Lock"; lock.pressed.connect(_on_lock_pressed.bind(i, oid, not is_locked))
		lock.disabled = oid == &""
func _on_purchase_pressed(i: int, oid: StringName) -> void: GameSession.try_purchase_shop_offer(i, oid, _rng); _refresh_shop()
func _on_lock_pressed(i: int, oid: StringName, value: bool) -> void: GameSession.set_shop_offer_locked(i, oid, value); _refresh_shop()
func _on_reroll_pressed() -> void: GameSession.try_reroll_shop(_rng); _refresh_shop()
func _on_continue_button_pressed() -> void: GameSession.current_round += 1; Engine.time_scale = 1.0; get_tree().paused = false; get_tree().change_scene_to_file("res://scene/game.tscn")
func try_buy_weapon(index: int) -> bool:
	var available: Array[StringName] = []
	for weapon in GameSession.WEAPON_OPTIONS:
		if weapon.id not in GameSession.equipped_weapon_ids: available.append(weapon.id)
	if index < 0 or index >= available.size(): return false
	var ok := GameSession.try_purchase_weapon(available[index], GameSession.SHOP_WEAPON_PRICE); _refresh_shop(); return ok
func try_upgrade_weapon(id: StringName) -> bool:
	var ok := GameSession.upgrade_weapon(id, GameSession.SHOP_WEAPON_UPGRADE_PRICE); _refresh_shop(); return ok
func try_reroll() -> bool: var ok := GameSession.try_reroll_shop(_rng); _refresh_shop(); return ok

func _refresh_weapon_ui() -> void:
	if weapon_items == null: return
	for c in weapon_items.get_children(): c.queue_free()
	for weapon in displayed_weapons:
		var row := HBoxContainer.new(); var label := Label.new(); var button := Button.new()
		label.text = weapon.display_name; button.text = "Upgrade %d" % GameSession.SHOP_WEAPON_UPGRADE_PRICE
		button.disabled = weapon.id not in GameSession.equipped_weapon_ids or GameSession.current_coins < GameSession.SHOP_WEAPON_UPGRADE_PRICE
		row.add_child(label); row.add_child(button); weapon_items.add_child(row)

# Public alias used by focused smoke/integration checks.
func refresh_shop() -> void:
	_refresh_shop()
