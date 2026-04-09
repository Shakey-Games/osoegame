extends BaseEnemy
class_name RangedEnemy

@export var projectile_scene: PackedScene
@export var shoot_range: float = 10.0   # make sure this matches or exceeds attack_range
@export var projectile_speed: float = 20.0

func _ready():
	super()
	# Override attack_range from base to match shoot_range
	attack_range = shoot_range

func attack():
	var distance = global_position.distance_to(player.global_position)
	if distance <= shoot_range:
		shoot()

func shoot():
	print("Shooting at player")  # debug
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj)
	proj.global_position = global_position
	var dir = (player.global_position - global_position).normalized()
	proj.initialize(dir, attack_damage, self)
