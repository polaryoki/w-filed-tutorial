extends Control

const CHARACTER_OPTIONS: Array[Resource] = [
	preload("res://resourse/character/character_gunslinger.tres"),
	preload("res://resourse/character/character_scout.tres"),
	preload("res://resourse/character/character_guardian.tres"),
]

@onready var character_cards: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/Layout/CharacterCards
@onready var selected_label: Label = $CenterContainer/PanelContainer/MarginContainer/Layout/SelectedLabel
@onready var confirm_button: Button = $CenterContainer/PanelContainer/MarginContainer/Layout/Actions/ConfirmButton

var selected_index: int = -1


func _ready() -> void:
	for index in range(mini(CHARACTER_OPTIONS.size(), character_cards.get_child_count())):
		var character = CHARACTER_OPTIONS[index]
		var card := character_cards.get_child(index) as VBoxContainer
		var name_label := card.get_node("NameLabel") as Label
		var description_label := card.get_node("DescriptionLabel") as Label
		var stats_label := card.get_node("StatsLabel") as Label
		var select_button := card.get_node("SelectButton") as Button
		name_label.text = character.get("display_name")
		description_label.text = character.get("description")
		stats_label.text = "HP %d  |  Speed %.0f\nFire %.2fs  |  Pickup %.0f" % [
			character.get("base_health"),
			character.get("move_speed"),
			character.get("fire_interval"),
			character.get("pickup_range"),
		]
		select_button.pressed.connect(_on_character_button_pressed.bind(index))

	var current_character = GameSession.get_selected_character()
	var current_id: StringName = &""
	if current_character != null:
		current_id = current_character.get("id")
	for index in CHARACTER_OPTIONS.size():
		if CHARACTER_OPTIONS[index].get("id") == current_id:
			_select_character(index)
			break
	if selected_index < 0:
		_select_character(0)
	confirm_button.grab_focus()


func _on_character_button_pressed(index: int) -> void:
	_select_character(index)


func _select_character(index: int) -> void:
	if index < 0 or index >= CHARACTER_OPTIONS.size():
		return
	var character = CHARACTER_OPTIONS[index]
	if not GameSession.select_character(character.get("id")):
		return

	selected_index = index
	selected_label.text = "Selected: %s" % character.get("display_name")
	for card_index in character_cards.get_child_count():
		var card := character_cards.get_child(card_index) as VBoxContainer
		var select_button := card.get_node("SelectButton") as Button
		select_button.button_pressed = card_index == selected_index


func _on_confirm_button_pressed() -> void:
	if selected_index < 0:
		return
	get_tree().change_scene_to_file("res://scene/game.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
