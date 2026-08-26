class_name UpgradeConfig
extends Resource

enum EffectType {
	MAX_HEALTH,
	MOVE_SPEED_MULTIPLIER,
	DAMAGE,
	ATTACK_SPEED_MULTIPLIER,
	PICKUP_RANGE_MULTIPLIER,
	LUCK,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var effect_type: EffectType = EffectType.MAX_HEALTH
@export var effect_value: float = 0.0

