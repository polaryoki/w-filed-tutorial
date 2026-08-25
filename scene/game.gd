extends Node2D

const RESULT_TITLE_WIN := "你赢了"
const RESULT_TITLE_LOSE := "你输了"
const RESULT_MESSAGE_WIN := "你成功坚持到了倒计时结束。"
const RESULT_MESSAGE_LOSE := "玩家生命值已归零。"
const RESULT_OK_BUTTON_TEXT := "结束游戏"
# 默认敌人场景与四种敌人配置资源。

@export_group("刷怪资源")
@export var enemy_scene: PackedScene = preload("res://scene/enemy.tscn")
@export var enemy_configs: Array[EnemyConfig] = [
	preload("res://resourse/config/enemy_basic.tres"),
	preload("res://resourse/config/enemy_shelled.tres"),
	preload("res://resourse/config/enemy_fast.tres"),
	preload("res://resourse/config/enemy_bomber.tres"),
]

@export_group("刷怪节奏")

# 开局立即刷出的敌人数，用于快速验证系统是否正常工作。
@export_range(0, 100, 1, "or_greater") var initial_spawn_count: int = 1

# 每次计时器触发时生成的敌人数。
@export_range(1, 20, 1, "or_greater") var spawn_count_per_tick: int = 1

# 开局时的刷怪间隔。
@export_range(0.1, 60.0, 0.1, "or_greater") var spawn_interval: float = 1.5

# 关卡后期允许缩短到的最小刷怪间隔。
@export_range(0.1, 60.0, 0.1, "or_greater") var min_spawn_interval: float = 0.6

# 场上允许同时存在的最大敌人数，避免无限堆积。
@export_range(1, 200, 1, "or_greater") var max_alive_enemies: int = 12
@export var boss_config: Resource = preload("res://resourse/config/boss_outlaw.tres")
@export_group("关卡 UI")
# 关卡倒计时总时长，单位为秒。
@export_range(1.0, 3600.0, 1.0, "or_greater") var stage_duration: float = 10

# 主场景中的核心引用。
@onready var player: Player = $Player
@onready var enemy_container: Node2D = $EnemyContainer
@onready var enemy_spawn_points_root: Node2D = $EnemySpawnPoints
@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer
@onready var life_count_label: Label = $HUDLayer/LifeCountLabel
@onready var coin_count_label: Label = $HUDLayer/CoinCountLabel
@onready var round_count_label: Label = $HUDLayer/RoundCountLabel
@onready var character_label: Label = $HUDLayer/CharacterLabel
@onready var time_bar: Sprite2D = $HUDLayer/TimeBar
@onready var result_dialog: AcceptDialog = $AcceptDialog
@onready var bgm_player: AudioStreamPlayer = $AudioContainer/BgmPlayer
@onready var result_win_sfx_player: AudioStreamPlayer = $AudioContainer/ResultWinSfxPlayer
@onready var result_lose_sfx_player: AudioStreamPlayer = $AudioContainer/ResultLoseSfxPlayer


# 随机数生成器，专门用于挑选出生点和敌人配置。
var random_generator: RandomNumberGenerator = RandomNumberGenerator.new()
# 缓存出生点，避免每次刷怪都重新遍历场景树。
var enemy_spawn_points: Array[Marker2D] = []
# 缓存有效的敌人配置资源，自动忽略空条目。
var available_enemy_configs: Array[EnemyConfig] = []
# 当前关卡倒计时剩余秒数。
var stage_time_left: float = 0.0
# 记录时间条原始横向缩放，便于按百分比缩短。
var time_bar_full_scale_x: float = 1.0
# 记录时间条左边缘位置，保证缩放时从左往右收缩。
var time_bar_left_edge_x: float = 0.0
# 记录时间条贴图原始宽度，用于在 centered 模式下修正位置。
var time_bar_texture_width: float = 0.0
# 是否已经进入结算状态，避免重复弹出结果窗口。
var is_result_displayed: bool = false
var is_round_transitioning: bool = false
var active_boss: Boss = null
var boss_encounter: bool = false

# 初始化刷怪系统：缓存出生点、缓存配置、刷出初始敌人并启动定时器。
func _ready() -> void:
	random_generator.randomize()
	Engine.time_scale = 1.0
	get_tree().paused = false
	if player != null:
		player.coins = GameSession.current_coins
		_apply_character_stats()
	if player != null and not player.coins_changed.is_connected(_on_player_coins_changed):
		player.coins_changed.connect(_on_player_coins_changed)
	_configure_result_dialog()
	_setup_hud()
	_collect_enemy_spawn_points()
	_collect_enemy_configs()
	_try_spawn_boss_for_round()
	_configure_enemy_spawn_timer()
	_spawn_initial_enemies()
	_start_enemy_spawn_timer()
	print("stage_duration =", stage_duration)
	print("stage_time_left =", stage_time_left)
	print("paused =", get_tree().paused)

func _apply_character_stats() -> void:
	var resolved_stats := GameSession.resolve_character_stats()
	player.apply_character_stats(resolved_stats)
	var starting_coins := int(resolved_stats.get("starting_coins", 0))
	if starting_coins > 0:
		player.add_coins(starting_coins)




# 每帧推进关卡倒计时，并刷新 HUD 显示。
func _process(delta: float) -> void:
	if is_result_displayed:
		return

	_update_stage_timer(delta)
	_update_spawn_interval()
	_update_hud()
	_check_game_result()
	
# 配置结算弹窗，使其在暂停状态下仍可交互，并统一由代码控制显示。
func _configure_result_dialog() -> void:
	result_dialog.dialog_close_on_escape = false
	result_dialog.ok_button_text = RESULT_OK_BUTTON_TEXT
	result_dialog.hide()

	if not result_dialog.confirmed.is_connected(_on_result_dialog_exit_requested):
		result_dialog.confirmed.connect(_on_result_dialog_exit_requested)
	if not result_dialog.close_requested.is_connected(_on_result_dialog_exit_requested):
		result_dialog.close_requested.connect(_on_result_dialog_exit_requested)
	if not result_dialog.canceled.is_connected(_on_result_dialog_exit_requested):
		result_dialog.canceled.connect(_on_result_dialog_exit_requested)
		
# 缓存时间条的初始尺寸信息，并刷新一次开场 HUD。
func _setup_hud() -> void:
	stage_time_left = maxf(stage_duration, 0.0)

	time_bar_full_scale_x = time_bar.scale.x
	if time_bar.texture != null:
		time_bar_texture_width = time_bar.texture.get_width()
	if time_bar.centered:
		time_bar_left_edge_x = time_bar.position.x - (time_bar_texture_width * time_bar_full_scale_x * 0.5)
	else:
		time_bar_left_edge_x = time_bar.position.x

	_update_hud()
	
# 关卡倒计时持续递减，到 0 后保持不再继续减少。
func _update_stage_timer(delta: float) -> void:
	if stage_time_left <= 0.0:
		stage_time_left = 0.0
		return

	stage_time_left = maxf(stage_time_left - delta, 0.0)


# 统一刷新生命文本与时间条，避免 UI 更新代码散落在不同位置。
func _update_hud() -> void:
	_update_life_count_label()
	_update_coin_count_label()
	_update_round_count_label()
	_update_character_label()
	_update_time_bar()


# 将玩家当前生命值显示为"x 数字"的形式。
func _update_life_count_label() -> void:
	life_count_label.text = "x %d" % _get_player_current_health()

func _update_coin_count_label() -> void:
	if coin_count_label == null:
		return
	coin_count_label.text = "x %d" % player.get_coins()

func _on_player_coins_changed(new_amount: int) -> void:
	if coin_count_label == null:
		return
	coin_count_label.text = "x %d" % new_amount

func _update_round_count_label() -> void:
	if round_count_label == null:
		return
	round_count_label.text = "Round %d" % GameSession.current_round


func _update_character_label() -> void:
	if character_label == null:
		return
	var character = GameSession.get_selected_character()
	if character == null:
		character_label.text = "Character"
		return
	character_label.text = String(character.get("display_name"))
	
# 按倒计时百分比缩放时间条，并修正位置让它始终从左往右缩短。
func _update_time_bar() -> void:
	var fill_ratio := 0.0
	if stage_duration > 0.0:
		fill_ratio = clampf(stage_time_left / stage_duration, 0.0, 1.0)

	time_bar.scale.x = time_bar_full_scale_x * fill_ratio

	if not time_bar.centered:
		time_bar.position.x = time_bar_left_edge_x
		return

	var current_width := time_bar_texture_width * time_bar.scale.x
	time_bar.position.x = time_bar_left_edge_x + (current_width * 0.5)
	
# 根据当前游戏状态判断是否触发胜利或失败结算。
func _check_game_result() -> void:
	if is_round_transitioning:
		return
	if _get_player_current_health() <= 0:
		_show_result_dialog(RESULT_TITLE_LOSE, RESULT_MESSAGE_LOSE)
		return

	if stage_time_left <= 0.0:
		_complete_round()


func _complete_round() -> void:
	if is_round_transitioning:
		return
	if boss_encounter and active_boss != null and not active_boss.is_defeated:
		# A boss round cannot silently stall when the normal round timer expires.
		# Treat the elapsed round limit as the explicit boss timeout path.
		_on_boss_timeout()
		return
	is_round_transitioning = true
	is_result_displayed = true
	GameSession.current_coins = player.get_coins()
	_stop_world()
	_change_scene_after_stop("res://scene/shop.tscn")

func _try_spawn_boss_for_round() -> void:
	if boss_config == null or GameSession.current_round != int(boss_config.get("spawn_round")):
		return
	active_boss = Boss.new()
	active_boss.setup(boss_config)
	active_boss.position = enemy_spawn_points[0].position if not enemy_spawn_points.is_empty() else Vector2.ZERO
	enemy_container.add_child(active_boss)
	boss_encounter = true
	active_boss.defeated.connect(_on_boss_defeated)
	active_boss.timed_out.connect(_on_boss_timeout)
	active_boss.attack_telegraph.connect(_on_boss_telegraph)

func _on_boss_telegraph(_mode: StringName, _duration: float) -> void:
	if enemy_spawn_timer != null:
		enemy_spawn_timer.paused = true

func _on_boss_defeated(reward: int) -> void:
	if not boss_encounter or is_round_transitioning:
		return
	GameSession.add_boss_reward(reward)
	boss_encounter = false
	_complete_round()

func _on_boss_timeout() -> void:
	if not is_result_displayed:
		_show_result_dialog(RESULT_TITLE_LOSE, "Boss battle timed out")


# 弹出结算窗口前暂停整个世界，并将焦点交给确定按钮。
func _show_result_dialog(result_title: String, result_message: String) -> void:
	if is_result_displayed:
		return
	is_result_displayed = true
	result_dialog.title = result_title
	result_dialog.dialog_text = result_message
	_play_result_audio(result_title)
	_stop_world()
	result_dialog.popup_centered()
	
	var ok_button := result_dialog.get_ok_button()
	if ok_button != null:
		ok_button.grab_focus()
		
# 统一停止刷怪、冻结场景树，让结算窗口成为唯一可交互内容。
func _stop_world() -> void:
	enemy_spawn_timer.stop()
	player.stop_runtime_audio()
	Engine.time_scale = 0.0
	get_tree().paused = true

# 结算前先停止背景音乐，再播放对应的胜利或失败音效。
func _play_result_audio(result_title: String) -> void:
	if bgm_player.playing:
		bgm_player.stop()

	if result_title == RESULT_TITLE_WIN:
		_play_sfx(result_win_sfx_player)
		return

	if result_title == RESULT_TITLE_LOSE:
		_play_sfx(result_lose_sfx_player)

# 一次性音效统一使用“停止后重新播放”的方式，保证重复触发时能从头开始。
func _play_sfx(audio_player: AudioStreamPlayer) -> void:
	if audio_player == null or audio_player.stream == null:
		return

	audio_player.stop()
	audio_player.play()

# 结算窗口的所有关闭路径都统一结束游戏，保持单局流程最简。
func _on_result_dialog_exit_requested() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	GameSession.reset_run()
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")


func _change_scene_after_stop(scene_path: String) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)


# 通过玩家对外暴露的接口读取当前生命值，避免 Game 直接依赖玩家内部变量。
func _get_player_current_health() -> int:
	return player.get_current_health()		

	
	# 从 EnemySpawnPoints 节点下收集所有 Marker2D 作为可选出生点。
func _collect_enemy_spawn_points() -> void:
	enemy_spawn_points.clear()

	for child in enemy_spawn_points_root.get_children():
		var spawn_point := child as Marker2D
		if spawn_point != null:
			enemy_spawn_points.append(spawn_point)

	if enemy_spawn_points.is_empty():
		push_warning("EnemySpawnPoints 下没有可用的 Marker2D 刷新点。")


# 缓存有效的敌人配置资源，便于后续随机挑选。
func _collect_enemy_configs() -> void:
	available_enemy_configs.clear()

	for enemy_config in enemy_configs:
		if enemy_config != null:
			available_enemy_configs.append(enemy_config)

	if available_enemy_configs.is_empty():
		push_warning("Game 场景没有可用的敌人配置资源。")
		
		# 统一配置主场景中的刷怪计时器。
func _configure_enemy_spawn_timer() -> void:
	enemy_spawn_timer.one_shot = false
	enemy_spawn_timer.wait_time = _get_current_spawn_interval()

	if not enemy_spawn_timer.timeout.is_connected(_on_enemy_spawn_timer_timeout):
		enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)
		
		# 根据游戏运行时间逐渐缩短刷怪间隔，让后期节奏自然加快。
func _update_spawn_interval() -> void:
	var current_interval := _get_current_spawn_interval()
	if is_equal_approx(enemy_spawn_timer.wait_time, current_interval):
		return

	enemy_spawn_timer.wait_time = current_interval

	# 如果当前这一轮倒计时比新的间隔还长，就立刻切到更快的节奏。
	if enemy_spawn_timer.is_stopped():
		return
	if enemy_spawn_timer.time_left <= current_interval:
		return

	enemy_spawn_timer.start(current_interval)
	
	# 通过游戏运行时间计算当前刷怪间隔。
func _get_current_spawn_interval() -> float:
	var start_interval := maxf(spawn_interval, 0.1)
	var end_interval := minf(maxf(min_spawn_interval, 0.1), start_interval)
	
	if stage_duration <= 0.0:
		return end_interval
	
	var difficulty_ratio := 1.0 - clampf(stage_time_left / stage_duration, 0.0, 1.0)
	return lerpf(start_interval, end_interval, difficulty_ratio)





	
	# 开局先刷出一小批敌人，方便立即看到运行效果。
func _spawn_initial_enemies() -> void:
	for _spawn_index in range(initial_spawn_count):
		if not _try_spawn_enemy():
			break


# 当前刷怪系统准备完成后再启动定时器。
func _start_enemy_spawn_timer() -> void:
	if not _is_spawn_system_ready():
		return

	enemy_spawn_timer.start()
	
	# 每次计时器触发时，按设定数量尝试刷新敌人。
func _on_enemy_spawn_timer_timeout() -> void:
	for _spawn_index in range(spawn_count_per_tick):
		if not _try_spawn_enemy():
			break
			
			# 尝试生成一个敌人，并自动完成位置和玩家目标初始化。
func _try_spawn_enemy() -> bool:
	if not _is_spawn_system_ready():
		return false
	if _get_alive_enemy_count() >= max_alive_enemies:
		return false

	var spawn_point := _pick_spawn_point()
	if spawn_point == null:
		return false

	var enemy_config := _pick_enemy_config()
	if enemy_config == null:
		return false

	var enemy_instance := enemy_scene.instantiate() as Enemy
	if enemy_instance == null:
		push_warning("敌人场景实例化失败，请检查 enemy_scene 设置。")
		return false

	enemy_container.add_child(enemy_instance)
	enemy_instance.global_position = spawn_point.global_position
	enemy_instance.setup(enemy_config, player)

	return true
	
	# 只要玩家、敌人场景、配置和出生点都有效，就允许继续刷怪。
func _is_spawn_system_ready() -> bool:
	return (
		player != null
		and enemy_scene != null
		and not enemy_spawn_points.is_empty()
		and not available_enemy_configs.is_empty()
	)


# 随机挑选一个出生点。
func _pick_spawn_point() -> Marker2D:
	if enemy_spawn_points.is_empty():
		return null

	var random_index := random_generator.randi_range(0, enemy_spawn_points.size() - 1)
	return enemy_spawn_points[random_index]


# 随机挑选一个敌人配置。
func _pick_enemy_config() -> EnemyConfig:
	if available_enemy_configs.is_empty():
		return null

	var random_index := random_generator.randi_range(0, available_enemy_configs.size() - 1)
	return available_enemy_configs[random_index]
	
	# 当前场上敌人数只统计 Enemy，避免掉落道具也挂在容器下时影响刷怪上限。
func _get_alive_enemy_count() -> int:
	var alive_enemy_count := 0

	for child in enemy_container.get_children():
		if child is Enemy:
			alive_enemy_count += 1

	return alive_enemy_count
