extends Area2D
class_name Boss

const BossConfigScript = preload("res://resourse/config/boss_config.gd")

signal phase_changed(phase: int)
signal attack_telegraph(mode: StringName, duration: float)
signal defeated(reward_coins: int)
signal timed_out
signal attack_requested(mode: StringName)

@export var config: Resource
var current_health: int
var current_phase: int = 0
var attack_cooldown: float = 0.0
var elapsed: float = 0.0
var is_defeated: bool = false

func setup(boss_config: Resource) -> void:
	config = boss_config
	current_health = config.max_health if config != null else 1
	current_phase = 0
	attack_cooldown = 0.0
	elapsed = 0.0
	is_defeated = false

func _ready() -> void:
	monitoring = true
	monitorable = true
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape_node.shape = circle
	add_child(shape_node)
	area_entered.connect(_on_area_entered)
	if config != null and current_health <= 0:
		setup(config)

func _process(delta: float) -> void:
	if is_defeated or config == null:
		return
	elapsed += delta
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	if config.time_limit > 0.0 and elapsed >= config.time_limit:
		timed_out.emit()
		return
	if attack_cooldown <= 0.0:
		attack_cooldown = maxf(config.attack_interval, 0.05)
		attack_telegraph.emit(config.attack_modes[current_phase], config.telegraph_duration)
		attack_requested.emit(config.attack_modes[current_phase])

func apply_damage(amount: int) -> bool:
	if is_defeated or amount <= 0:
		return false
	current_health = maxi(current_health - amount, 0)
	var next_phase: int = config.phase_for_health(current_health)
	if next_phase != current_phase:
		current_phase = next_phase
		phase_changed.emit(current_phase)
	if current_health == 0:
		is_defeated = true
		defeated.emit(config.reward_coins)
	return true

func _on_area_entered(area: Area2D) -> void:
	var bullet := area as Bullet
	if bullet == null:
		return
	if apply_damage(bullet.damage):
		bullet.queue_free()
