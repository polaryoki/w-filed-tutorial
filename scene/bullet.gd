extends Area2D
class_name Bullet

const WORLD_COLLISION_MASK := 1

@export var speed: float = 320.0
@export var max_lifetime : float = 2.0
var damage: int = 1
var piercing: int = 1
var travelled_distance: float = 0.0
var max_range: float = 640.0

var direction: Vector2 = Vector2.RIGHT

var remaining_lifetime: float = 0.0

func _ready() -> void:
	remaining_lifetime = max_lifetime
	area_entered.connect(_on_area_entered)
	
func setup(initial_direction:Vector2) -> void:
	if initial_direction != Vector2.ZERO:
		direction = initial_direction.normalized()
		
	rotation = direction.angle()

func setup_weapon_stats(new_damage: int, new_piercing: int, new_speed: float, new_range: float) -> void:
	damage = maxi(new_damage, 1)
	piercing = maxi(new_piercing, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_range, 1.0)
	
func _physics_process(delta: float) -> void:
	var current_position := global_position
	var next_position := current_position + direction * speed * delta
	
	if _will_hit_world(current_position,next_position):
		queue_free()
		return
		
	global_position = next_position
	travelled_distance += current_position.distance_to(next_position)
	
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0 or travelled_distance >= max_range:
		queue_free()
		
func _will_hit_world(from_position: Vector2, to_position: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return false
		
	var query := PhysicsRayQueryParameters2D.create(
		from_position,
		to_position,
		WORLD_COLLISION_MASK
	)	
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var hit_result: Dictionary = space_state.intersect_ray(query)
	return not hit_result.is_empty()

func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		return
	if piercing > 1:
		piercing -= 1
		return
	queue_free()
