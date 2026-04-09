extends Resource
class_name AttackData

@export var attack_name: String = "Basic Melee"
@export var attack_type: String = "melee"   # melee, ranged, aoe
@export var damage: float = 10.0
@export var range: float = 2.0              # melee range or min range for ranged
@export var max_range: float = 2.0          # for ranged: max distance
@export var cooldown: float = 1.0
@export var projectile_scene: PackedScene   # only for ranged
@export var projectile_speed: float = 20.0  # only for ranged
@export var aoe_radius: float = 0.0         # for aoe attacks
