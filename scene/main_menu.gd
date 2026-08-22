extends Control

@onready var start_button: Button = $CenterContainer/MenuPanel/MarginContainer/MenuLayout/StartButton
@onready var settings_dialog: AcceptDialog = $SettingsDialog


func _ready() -> void:
	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/game.tscn")


func _on_settings_button_pressed() -> void:
	settings_dialog.popup_centered()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
