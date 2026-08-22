extends Control

@onready var round_label: Label = $CenterContainer/PanelContainer/MarginContainer/Layout/RoundLabel
@onready var gold_label: Label = $CenterContainer/PanelContainer/MarginContainer/Layout/GoldLabel
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/Layout/ContinueButton


func _ready() -> void:
	round_label.text = "回合 %d" % GameSession.current_round
	gold_label.text = "金币：%d" % GameSession.current_coins
	continue_button.grab_focus()


func _on_continue_button_pressed() -> void:
	GameSession.current_round += 1
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/game.tscn")
