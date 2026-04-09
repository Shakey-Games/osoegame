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
	
	# Disable collision briefly to avoid hitting shooter
	collision_layer = 0
	collision_mask = 0
	await get_tree().create_timer(0.1).timeout
	collision_layer = 2   # projectile's own layer
	collision_mask = 1
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var new_position = global_position + direction * speed * delta
	
	# Raycast to catch anything between frames
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(previous_position, new_position)
	query.collision_mask = collision_mask  # only layers we care about
	query.exclude = [self]  # don't hit self
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit = result.collider
		_handle_hit(hit)
		queue_free()
		return
	
	# Move normally
	global_position = new_position
	previous_position = global_position

func _on_body_entered(body):
	_handle_hit(body)
	queue_free()

func _handle_hit(hit_node):
	print("Projectile hit: ", hit_node.name, " (type: ", hit_node.get_class(), ")")
	
	if hit_node == shooter:
		print("  → Ignoring shooter")
		return
	
	# Try to find a damageable parent if hit a collision shape
	var target = hit_node
	if not target.has_method("take_damage") and target.get_parent():
		target = target.get_parent()
		print("  → Checking parent: ", target.name)
	
	if target.has_method("take_damage"):
		print("  → Calling take_damage(", damage, ") on ", target.name)
		target.take_damage(damage)
	else:
		print("  → No take_damage method found on ", target.name)
