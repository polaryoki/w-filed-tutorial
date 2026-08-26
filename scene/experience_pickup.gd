extends Area2D
class_name ExperiencePickup

@export_range(1, 999, 1, "or_greater") var value: int = 1
var is_collected := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(experience_value: int) -> void:
	value = maxi(experience_value, 1)

func _on_body_entered(body: Node2D) -> void:
	_try_collect(body as Player)

func _on_area_entered(area: Area2D) -> void:
	_try_collect(area.get_parent() as Player)

func _try_collect(player: Player) -> void:
	if is_collected or player == null:
		return
	is_collected = true
	GameSession.add_experience(value)
	queue_free()

