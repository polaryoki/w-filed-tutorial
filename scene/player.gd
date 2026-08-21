extends CharacterBody2D
class_name Player

signal coins_changed(new_amount: int)

const NORMAL_ANIMATION_PREFIX := &"normal"

const BULLET_scene := preload("res://scene/bullet.tscn")
const ARMED_ANIMATION_PREFIX := &"armed"
const DEFAULT_MOVE_SPEED_MULTIPLIER := 1.0
const DEFAULT_FIRE_RATE_MULTIPLIER := 1.0
const SPIRAL_PHASE_STEP := PI/12
const BLINK_ENABLED_SHADER_PARAMETER := &"blink_enabled"
const WORLD_COLLISION_MASK := 1

@onready var body_sprite: AnimatedSprite2D = $BodySprite

@onready var armed_effect_sprite: AnimatedSprite2D = $ArmedEffectSprite
@onready var shooting_timer: Timer = $ShootingTimer
@onready var shoot_sfx_player: AudioStreamPlayer = $AudioContainer/ShootSfxPlayer
@onready var move_sfx_player: AudioStreamPlayer = $AudioContainer/MoveSfxPlayer
@onready var pickup_sfx_player: AudioStreamPlayer = $AudioContainer/PickupSfxPlayer

var facing_suffix: StringName = &"right"

var current_move_speed_multiplier: float = DEFAULT_MOVE_SPEED_MULTIPLIER
var rapid_fire_rate_multiplier: float = DEFAULT_FIRE_RATE_MULTIPLIER
var form_fire_rate_multiplier: float = DEFAULT_FIRE_RATE_MULTIPLIER
var current_form_mode: int = PickupConfig.PlayerFormMode.NORMAL
var current_shot_pattern: int = PickupConfig.ShotPattern.NORMAL
var speed_buff_time_left: float = 0.0
var rapid_buff_time_left: float = 0.0
var form_buff_time_left: float = 0.0
var spiral_phase: float = 0.0
var coins: int = 0

# 玩家移动速度，单位是像素/秒。
@export var move_speed: float = 120.0
# 玩家最大生命值。
@export var max_health: int = 5
# 受伤后进入无敌闪烁的持续时间。
@export var invincibility_duration: float = 1.0

# 玩家当前生命值，由最大生命值初始化。
var current_health: int = 0
# 无敌剩余时间，大于 0 时忽略新的受伤请求。
var invincibility_time_left: float = 0.0
# 玩家死亡后停止移动和攻击。
var is_dead: bool = false

@export var fire_interval: float =0.18
@export var bullet_spawn_distance: float = 18.0

func _ready() -> void:
	current_health = maxi(max_health, 1)
	shooting_timer.one_shot = true
	shooting_timer.wait_time = _get_effective_fire_interval()
	_set_hurt_blink_enabled(false)
	_update_animation()
	_update_armed_effect()

func _physics_process(delta: float) -> void:
	_update_invincibility(delta)
	_update_pickup_effects(delta)

	if is_dead:
		velocity = Vector2.ZERO
		_set_move_sfx_active(false)
		return

	# 读取四个方向输入，并得到标准化后的八向输入向量
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var shoot_input := Input.get_vector("shoot_left", "shoot_right", "shoot_up", "shoot_down")
	var is_moving := move_input != Vector2.ZERO

	# CharacterBody2D 通过 velocity 配合 move_and_slide() 完成移动
	velocity = move_input * _get_effective_move_speed()
	move_and_slide()
	_set_move_sfx_active(is_moving)

	if current_shot_pattern == PickupConfig.ShotPattern.SPIRAL:
		_try_auto_spiral_shoot()
	elif shoot_input != Vector2.ZERO:
		_try_shoot(shoot_input)

	_update_facing(move_input, shoot_input)
	_update_animation()
	_update_armed_effect()
		
func _update_animation() -> void:
	var animation_name := StringName("%s_%s" % [_get_animation_prefix(),facing_suffix])
	
	if not body_sprite.sprite_frames.has_animation(animation_name):
		var fallback_animation_name := StringName("%s_%s" % [NORMAL_ANIMATION_PREFIX, facing_suffix])
		if not body_sprite.sprite_frames.has_animation(fallback_animation_name):
			push_warning("Missing player animation: %s" % animation_name)
			return
		animation_name = fallback_animation_name
		
	if body_sprite.animation != animation_name:
		body_sprite.play(animation_name)
		
func _update_facing(move_input: Vector2, shoot_input: Vector2) -> void:
	if current_shot_pattern == PickupConfig.ShotPattern.SPIRAL:
		if move_input != Vector2.ZERO:
			facing_suffix = _vector_to_facing_suffix(move_input)
		return
		
	if shoot_input != Vector2.ZERO:
		facing_suffix = _vector_to_facing_suffix(shoot_input)
	elif move_input != Vector2.ZERO:
		facing_suffix = _vector_to_facing_suffix(move_input)
		
func _try_shoot(shoot_input: Vector2) -> void:
	if not shooting_timer.is_stopped():
		return
		
	var shoot_direction := shoot_input.normalized()
	var has_spawned_bullet := _fire_bullets(shoot_direction)
	if has_spawned_bullet:
		_play_sfx(shoot_sfx_player)
	shooting_timer.start(_get_effective_fire_interval())
		
		
func apply_pickup(config: PickupConfig) -> bool:
	if config == null:
		return false
		
	var applied := false
	var should_refresh_shooting_timer := false
	var buff_duration := maxf(config.duration, 0.0)
	var has_form_override := (
		config.player_form_mode != PickupConfig.PlayerFormMode.NORMAL
		or config.shot_pattern != PickupConfig.ShotPattern.NORMAL
	)
	var has_fire_rate_override := not is_equal_approx(
		config.fire_rate_multiplier,
		DEFAULT_FIRE_RATE_MULTIPLIER
	)
	
	if not is_equal_approx(config.move_speed_multiplier, DEFAULT_MOVE_SPEED_MULTIPLIER):
		current_move_speed_multiplier = config.move_speed_multiplier
		speed_buff_time_left = buff_duration
		applied = true
		
	# 普通射速道具与形态专属射速开维护，避免螺旋形态的射速被其他 Buff 状态覆盖。
	if has_fire_rate_override and not has_form_override:
		rapid_fire_rate_multiplier = config.fire_rate_multiplier
		rapid_buff_time_left = buff_duration
		should_refresh_shooting_timer = true
		applied = true
		
	if has_form_override:
		current_form_mode = config.player_form_mode
		current_shot_pattern = config.shot_pattern
		form_fire_rate_multiplier = (
			config.fire_rate_multiplier if has_fire_rate_override else DEFAULT_FIRE_RATE_MULTIPLIER
		)
		form_buff_time_left = buff_duration
		spiral_phase = 0.0
		should_refresh_shooting_timer = true
		applied = true
		
	if should_refresh_shooting_timer:
		_refresh_shooting_timer_wait_time()
	if applied:
		_play_sfx(pickup_sfx_player)
	return applied	

func add_coins(amount: int) -> void:
	if amount <= 0:
		return

	coins += amount
	coins_changed.emit(coins)

func get_coins() -> int:
	return coins

		
		
func _get_effective_move_speed() -> float:
	return move_speed * current_move_speed_multiplier
		
# 敌人或其他伤害来源统一通过这个入口让玩家受伤。
func apply_damage(amount: int) -> bool:
	if is_dead:
		return false
	if amount <= 0:
		return false
	if invincibility_time_left > 0.0:
		return false

	current_health = maxi(current_health - amount, 0)
	if current_health <= 0:
		_die()
		return true

	_start_invincibility()
	return true
	
	# 获取玩家当前生命值。
func get_current_health() -> int:
	return current_health		
		
func _fire_bullets(base_direction:Vector2) -> bool:
	if current_shot_pattern == PickupConfig.ShotPattern.SPIRAL:
		var has_spawned_forward_bullet := _spawn_bullet(base_direction)
		var has_spawned_backward_bullet := _spawn_bullet(base_direction.rotated(PI))
		spiral_phase = wrapf(spiral_phase + SPIRAL_PHASE_STEP, 0.0, TAU)
		return has_spawned_forward_bullet or has_spawned_backward_bullet
		
	return _spawn_bullet(base_direction)
	
func _spawn_bullet(shoot_direction: Vector2) ->bool:
	if not _can_spawn_bullet(shoot_direction):
		return false
	
	var bullet := BULLET_scene.instantiate() as Bullet
	if bullet == null:
		return false
		
	bullet.top_level = true
	bullet.setup(shoot_direction)
	
	var spawn_parent := get_tree().current_scene
	if spawn_parent == null:
		return false
		
	spawn_parent.add_child(bullet)
	bullet.global_position = global_position + shoot_direction * bullet_spawn_distance
	return true
	
# 发射前先检查从玩家中心到子弹出生点的路径是否被世界碰撞挡住。
func _can_spawn_bullet(shoot_direction: Vector2) -> bool:
	var spawn_position := global_position + shoot_direction * bullet_spawn_distance
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return true

	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		spawn_position,
		WORLD_COLLISION_MASK
	)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [get_rid()]

	var hit_result: Dictionary = space_state.intersect_ray(query)
	return hit_result.is_empty()	
	
func _try_auto_spiral_shoot() -> void:
	if not shooting_timer.is_stopped():
		return
		
	var spiral_direction := Vector2.RIGHT.rotated(spiral_phase)
	var has_spawned_bullet := _fire_bullets(spiral_direction)
	if has_spawned_bullet:
		_play_sfx(shoot_sfx_player)
	shooting_timer.start(_get_effective_fire_interval())
		
# 每帧更新道具 Buff 剩余时间，并在到期后恢复默认状态。
func _update_pickup_effects(delta: float) -> void:
	if speed_buff_time_left > 0.0:
		speed_buff_time_left = maxf(speed_buff_time_left - delta, 0.0)
	if speed_buff_time_left <= 0.0:
		current_move_speed_multiplier = DEFAULT_MOVE_SPEED_MULTIPLIER




	if rapid_buff_time_left > 0.0:
		rapid_buff_time_left = maxf(rapid_buff_time_left - delta, 0.0)
		if rapid_buff_time_left <= 0.0:
			rapid_fire_rate_multiplier = DEFAULT_FIRE_RATE_MULTIPLIER
			_refresh_shooting_timer_wait_time()


	if form_buff_time_left > 0.0:
		form_buff_time_left = maxf(form_buff_time_left - delta, 0.0)
		if form_buff_time_left <= 0.0:
			current_form_mode = PickupConfig.PlayerFormMode.NORMAL
			current_shot_pattern = PickupConfig.ShotPattern.NORMAL
			form_fire_rate_multiplier = DEFAULT_FIRE_RATE_MULTIPLIER
			spiral_phase = 0.0
			_refresh_shooting_timer_wait_time()		
		
# 更新玩家无敌时间，并在结束时关闭闪烁效果。
func _update_invincibility(delta: float) -> void:
	if invincibility_time_left <= 0.0:
		return

	invincibility_time_left = maxf(invincibility_time_left - delta, 0.0)
	if invincibility_time_left > 0.0:
		return

	_set_hurt_blink_enabled(false)		
		
func _get_effective_fire_interval() -> float:
	return maxf(fire_interval / _get_effective_fire_rate_multiplier(), 0.01)
	
func _get_effective_fire_rate_multiplier() -> float:
	if _has_active_form_override():
		return maxf(form_fire_rate_multiplier, 0.01)
		
	return maxf(rapid_fire_rate_multiplier, 0.01)	
	
func _has_active_form_override() -> bool:
	return(
		current_form_mode != PickupConfig.PlayerFormMode.NORMAL
		or current_shot_pattern != PickupConfig.ShotPattern.NORMAL
	)
		
# 统一刷新射击计时器的基础间隔，避免 Buff 生效后仍使用旧数值。
func _refresh_shooting_timer_wait_time() -> void:
	var new_interval := _get_effective_fire_interval()
	shooting_timer.wait_time = new_interval


	# 如果玩家在冷却途中拾取了更快的射速 Buff，需要让当前这次冷却也立刻缩短。
	if shooting_timer.is_stopped():
		return

	if shooting_timer.time_left <= new_interval:
		return


	shooting_timer.start(new_interval)
		
# 开启玩家受伤后的无敌闪烁状态。
func _start_invincibility() -> void:
	invincibility_time_left = maxf(invincibility_duration, 0.0)
	_set_hurt_blink_enabled(invincibility_time_left > 0.0)

# 统一设置玩家受击闪烁开关，便于后续与其他表现逻辑解耦。
func _set_hurt_blink_enabled(enabled: bool) -> void:
	var sprite_material := body_sprite.material as ShaderMaterial
	if sprite_material != null:
		sprite_material.set_shader_parameter(BLINK_ENABLED_SHADER_PARAMETER, enabled)

# 玩家生命值归零时进入死亡状态。
func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	invincibility_time_left = 0.0
	_set_hurt_blink_enabled(false)
	shooting_timer.stop()
	_set_move_sfx_active(false)
	armed_effect_sprite.visible = false
	armed_effect_sprite.stop()		
		
func _get_animation_prefix() -> StringName:
	if current_form_mode == PickupConfig.PlayerFormMode.ARMED:
		return ARMED_ANIMATION_PREFIX
		
	return NORMAL_ANIMATION_PREFIX
	
func _update_armed_effect() -> void:
	var is_armed := current_form_mode == PickupConfig.PlayerFormMode.ARMED
	
	if not is_armed:
		if armed_effect_sprite.visible:
			armed_effect_sprite.visible = false
		if armed_effect_sprite.is_playing():
			armed_effect_sprite.stop()
		return
		
	if not armed_effect_sprite.visible:
		armed_effect_sprite.visible = true
	if armed_effect_sprite.is_playing():
		return
	if armed_effect_sprite.sprite_frames == null:
		return
		
	if armed_effect_sprite.sprite_frames.has_animation(&"default"):
		armed_effect_sprite.play(&"default")
		
# 主场景在结算时可调用这个接口，统一关闭玩家仍在播放的运行时音频。
func stop_runtime_audio() -> void:
	_set_move_sfx_active(false)
	if shoot_sfx_player != null and shoot_sfx_player.playing:
		shoot_sfx_player.stop()
	if pickup_sfx_player != null and pickup_sfx_player.playing:
		pickup_sfx_player.stop()

# 根据移动状态启停移动音效。
func _set_move_sfx_active(active: bool) -> void:
	if move_sfx_player == null or move_sfx_player.stream == null:
		return

	if active:
		if not move_sfx_player.playing:
			move_sfx_player.play()
		return

	if move_sfx_player.playing:
		move_sfx_player.stop()
		
# 一次性音效统一使用重播逻辑，避免快速触发时无法从头开始。
func _play_sfx(audio_player: AudioStreamPlayer) -> void:
	if audio_player == null or audio_player.stream == null:
		return

	audio_player.stop()
	audio_player.play()		
		
func _vector_to_facing_suffix(direction: Vector2) -> StringName:
	if abs(direction.x) >= abs(direction.y):
		return &"right" if direction.x > 0.0 else &"left"
		
	return &"down" if direction.y > 0.0 else &"up"			
