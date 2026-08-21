extends Area2D
class_name Coin

@export_range(1, 999, 1, "or_greater") var value: int = 1

var magnet_target: Node2D = null
var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# 初始化金币面值；磁吸相关行为暂不在此实现。
func setup(coin_value: int) -> void:
	value = maxi(coin_value, 1)

# 为未来磁吸系统预留目标注入接口，目前不改变金币运动。
func set_magnet_target(target: Node2D) -> void:
	magnet_target = target

func clear_magnet_target() -> void:
	magnet_target = null

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return

	var player := body as Player
	if player == null:
		return

	is_collected = true
	player.add_coins(value)
	queue_free()
