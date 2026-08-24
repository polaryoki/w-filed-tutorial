extends Area2D
class_name Coin

@export_range(1, 999, 1, "or_greater") var value: int = 1

var magnet_target: Node2D = null
var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

# 初始化金币面值；磁吸相关行为暂不在此实现。
func setup(coin_value: int) -> void:
	value = maxi(coin_value, 1)

# 为未来磁吸系统预留目标注入接口，目前不改变金币运动。
func set_magnet_target(target: Node2D) -> void:
	magnet_target = target

func clear_magnet_target() -> void:
	magnet_target = null

func _on_body_entered(body: Node2D) -> void:
	_try_collect_from_player(body as Player)


func _on_area_entered(area: Area2D) -> void:
	_try_collect_from_player(area.get_parent() as Player)


func _try_collect_from_player(player: Player) -> void:
	if is_collected:
		return
	if player == null:
		return

	is_collected = true
	player.add_coins(value)
	queue_free()
