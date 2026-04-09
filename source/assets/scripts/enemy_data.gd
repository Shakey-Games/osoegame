extends Resource
class_name EnemyData

@export var display_name: String = "Enemy"
@export var max_health: float = 100.0
@export var speed: float = 3.0
@export var attacks: Array[AttackData] = []

# Boss-specific fields (ignored for normal enemies)
@export var is_boss: bool = false
@export var phase_2_health_ratio: float = 0.5   # triggers at 50% health
@export var phase_3_health_ratio: float = 0.2   # triggers at 20% health
