extends Area3D
class_name Projectile

@export var speed: float = 50.0
@export var damage: float = 10.0
@export var lifetime: float = 5.0

var direction: Vector3
var shooter: Node
var previous_position: Vector3

func initialize(dir: Vector3, dmg: float, source: Node):
	direction = dir.normalized()
	damage = dmg
	shooter = source
	previous_position = global_position
	
	# Disable collision for a very short time to avoid hitting shooter
	collision_layer = 0
	collision_mask = 0
	await get_tree().create_timer(0.02).timeout  # shorter delay
	
	# Set to hit both player (layer 1) and enemies (layer 2)
	collision_layer = 3
	collision_mask = 1 | 2
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var new_position = global_position + direction * speed * delta
	
	# Raycast to catch fast-moving projectiles
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(previous_position, new_position)
	query.collision_mask = collision_mask
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit = result.collider
		_handle_hit(hit)
		queue_free()
		return
	
	global_position = new_position
	previous_position = new_position

func _on_body_entered(body):
	_handle_hit(body)
	queue_free()

func _handle_hit(hit_node):
	if hit_node == shooter:
		return
	var target = hit_node
	if not target.has_method("take_damage") and target.get_parent():
		target = target.get_parent()
	if target.has_method("take_damage"):
		target.take_damage(damage)
