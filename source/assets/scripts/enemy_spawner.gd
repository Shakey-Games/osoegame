extends Node3D

@export var enemy_scenes: Array[PackedScene]   # list of enemy scene files
@export var spawn_weights: Array[float]       # optional, same size as enemy_scenes
@export var spawn_delay: float = 3.0
@export var max_enemies: int = 5
@export var spawn_radius: float = 5.0         # random offset around spawner

var current_enemies: int = 0

func _ready():
	# Validate weights if provided
	if not spawn_weights.is_empty() and spawn_weights.size() != enemy_scenes.size():
		print("Warning: spawn_weights size != enemy_scenes size. Using equal chance.")
		spawn_weights.clear()
	
	spawn_loop()

func spawn_loop():
	while true:
		if current_enemies < max_enemies:
			spawn_enemy()
		await get_tree().create_timer(randf_range(spawn_delay * 0.5, spawn_delay * 1.5)).timeout

func spawn_enemy():
	if enemy_scenes.is_empty():
		print("Error: No enemy scenes assigned to spawner")
		return
	
	# Choose which enemy scene to spawn
	var chosen_scene: PackedScene
	if spawn_weights.is_empty():
		# Equal chance
		chosen_scene = enemy_scenes[randi() % enemy_scenes.size()]
	else:
		chosen_scene = _get_weighted_random_scene()
	
	var enemy = chosen_scene.instantiate()
	
	# Set random position around spawner
	var offset = Vector3(
		randf_range(-spawn_radius, spawn_radius),
		0,
		randf_range(-spawn_radius, spawn_radius)
	)
	enemy.global_position = global_position + offset
	
	# Add to scene (use a container if you have one, else root)
	get_tree().root.add_child(enemy)
	
	current_enemies += 1
	
	# Connect death signal to update counter
	enemy.connect("died", Callable(self, "on_enemy_died"))

func _get_weighted_random_scene() -> PackedScene:
	var total_weight = 0.0
	for w in spawn_weights:
		total_weight += w
	
	var roll = randf() * total_weight
	var accum = 0.0
	for i in spawn_weights.size():
		accum += spawn_weights[i]
		if roll <= accum:
			return enemy_scenes[i]
	
	# Fallback (should never reach)
	return enemy_scenes[0]

func on_enemy_died():
	current_enemies -= 1
