extends CharacterBase
class_name Damageable

@export var max_health: float = 100

var health: float

signal died

func _ready():
	health = max_health

func get_health_color(ratio: float) -> Color:
	if ratio > 0.6:
		return Color(0, 1, 0)
	elif ratio > 0.3:
		return Color(1, 1, 0)
	else:
		return Color(1, 0, 0)

func take_damage(amount: float):
	health -= amount
	on_hit()
	if health <= 0:
		die()

func on_hit():
	flash_hit()

func die():
	await on_death()
	emit_signal("died")
	
	# Small delay to allow death animations/tweens to finish
	if is_inside_tree():
		await get_tree().create_timer(0.1).timeout
	
	queue_free()

func on_death():
	pass

func flash_hit():
	pass
