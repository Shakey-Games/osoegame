extends Resource
class_name EnemyData

@export var display_name: String = "Enemy"
@export var max_health: float = 100.0
@export var speed: float = 3.0
@export var attacks: Array[AttackData] = []

# Boss fields
@export var is_boss: bool = false
@export var phase_2_health_ratio: float = 0.5
@export var phase_3_health_ratio: float = 0.2

# Drop system
@export var drop_chance: float = 0.4          # chance to drop anything (0-1)
@export var drop_table: Array[DropEntry] = [] # possible drops with weights
