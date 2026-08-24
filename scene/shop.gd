extends Control

const RELIC_OPTIONS: Array[RelicData] = [
	preload("res://resourse/relic/relic_lucky_start.tres"),
	preload("res://resourse/relic/relic_rapid_chamber.tres"),
	preload("res://resourse/relic/relic_reinforced_charm.tres"),
	preload("res://resourse/relic/relic_swift_boots.tres"),
	preload("res://resourse/relic/relic_iron_will.tres"),
	preload("res://resourse/relic/relic_long_barrel.tres"),
]

@onready var round_label: Label = $CenterContainer/PanelContainer/MarginContainer/Layout/RoundLabel
@onready var gold_label: Label = $CenterContainer/PanelContainer/MarginContainer/Layout/GoldLabel
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/Layout/ContinueButton
@onready var relic_items: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/Layout/RelicItems
var displayed_relics: Array[RelicData] = []

func _ready() -> void:
	round_label.text = "回合 %d" % GameSession.current_round
	_build_relic_options()
	_refresh_gold()
	continue_button.grab_focus()

func _build_relic_options() -> void:
	var available: Array[RelicData] = []
	for relic in RELIC_OPTIONS:
		if relic != null and not GameSession.has_relic(String(relic.id)):
			available.append(relic)
	available.shuffle()
	displayed_relics = available.slice(0, mini(3, available.size()))
	for index in range(relic_items.get_child_count()):
		var item_root := relic_items.get_child(index) as VBoxContainer
		var info := item_root.get_node("Info") as Label
		var buy_button := item_root.get_node("BuyButton") as Button
		if index >= displayed_relics.size():
			item_root.hide()
			continue
		var relic := displayed_relics[index]
		info.text = "%s (%d)\n%s" % [relic.display_name, relic.price, relic.description]
		buy_button.pressed.connect(_on_relic_buy_pressed.bind(index))
		_refresh_relic_button(index)

func _on_relic_buy_pressed(index: int) -> void:
	if index < 0 or index >= displayed_relics.size():
		return
	var relic := displayed_relics[index]
	if not GameSession.try_purchase_relic(String(relic.id), relic.price):
		return
	_refresh_gold()

func _refresh_relic_button(index: int) -> void:
	if index < 0 or index >= displayed_relics.size():
		return
	var item_root := relic_items.get_child(index) as VBoxContainer
	var buy_button := item_root.get_node("BuyButton") as Button
	var relic := displayed_relics[index]
	if GameSession.has_relic(String(relic.id)):
		buy_button.text = "已购买"
		buy_button.disabled = true
	else:
		buy_button.text = "购买（%d）" % relic.price
		buy_button.disabled = GameSession.current_coins < relic.price

func _refresh_gold() -> void:
	gold_label.text = "金币：%d" % GameSession.current_coins
	for index in displayed_relics.size():
		_refresh_relic_button(index)

func _on_continue_button_pressed() -> void:
	GameSession.current_round += 1
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/game.tscn")
