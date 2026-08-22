class_name RelicData
extends Resource

enum EffectType {
	STARTING_COINS,
	FIRE_INTERVAL_MULTIPLIER,
	MAX_HEALTH_BONUS,
	MOVE_SPEED_MULTIPLIER,
	INVINCIBILITY_DURATION_BONUS,
	BULLET_SPAWN_DISTANCE_BONUS,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var price: int = 0
@export var effect_type: EffectType = EffectType.STARTING_COINS
@export var effect_value: float = 0.0
