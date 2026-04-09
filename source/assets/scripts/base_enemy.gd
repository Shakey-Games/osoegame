extends Damageable
class_name BaseEnemy

const PICKUP_SCENE = preload("res://source/assets/scripts/pickup.tscn")

# --- Data Resource ---
@export var enemy_data: EnemyData

# --- Attack System ---
var attacks: Array[AttackData]
var attack_timers: Array[float]
var player: Node3D

# --- Movement ---
var speed: float = 3.0

# --- Health Bar (fading billboard) ---
@onready var health_bar: ProgressBar = $SubViewport/HealthBar
@onready var health_sprite: Sprite3D = $HealthSprite
var fill_style: StyleBoxFlat
var hide_timer: SceneTreeTimer
var fade_tween: Tween

func _ready():
	super()
	
	if enemy_data:
		max_health = enemy_data.max_health
		health = max_health
		speed = enemy_data.speed
		attacks = enemy_data.attacks.duplicate(true)
		attack_timers.resize(attacks.size())
		for i in attacks.size():
			attack_timers[i] = 0.0
	else:
		# Fallback melee attack
		print("Warning: No enemy_data assigned to ", name, " – using fallback")
		var default_attack = AttackData.new()
		default_attack.attack_name = "Fallback Melee"
		default_attack.attack_type = "melee"
		default_attack.damage = 10.0
		default_attack.range = 2.0
		default_attack.cooldown = 1.0
		attacks = [default_attack]
		attack_timers = [0.0]
	
	player = get_tree().get_first_node_in_group("player")
	
	# Setup floating health bar
	fill_style = health_bar.get_theme_stylebox("fill").duplicate()
	health_bar.add_theme_stylebox_override("fill", fill_style)
	health_sprite.modulate.a = 0.0  # start invisible

func _physics_process(delta):
	# Update attack cooldowns
	for i in attack_timers.size():
		if attack_timers[i] > 0:
			attack_timers[i] -= delta
	
	# Find player if lost
	if not player or not player.is_inside_tree():
		player = get_tree().get_first_node_in_group("player")
		if not player:
			apply_gravity(delta)
			move_character()
			return
	
	var distance = global_position.distance_to(player.global_position)
	
	# Check if any attack is available
	var can_attack = false
	for i in attacks.size():
		if attack_timers[i] <= 0 and _is_attack_in_range(i, distance):
			can_attack = true
			break
	
	if not can_attack:
		move_toward_player()
	else:
		velocity.x = 0
		velocity.z = 0
		_try_attack(distance)
	
	apply_gravity(delta)
	move_character()

func move_toward_player():
	var direction = player.global_position - global_position
	direction.y = 0
	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func _is_attack_in_range(attack_index: int, current_distance: float) -> bool:
	var attack = attacks[attack_index]
	match attack.attack_type:
		"melee":
			return current_distance <= attack.range
		"ranged":
			return current_distance <= attack.max_range
		"aoe":
			return current_distance <= attack.range
	return false

func _try_attack(current_distance: float):
	var ranged_available = []
	var melee_available = []
	var aoe_available = []
	
	for i in attacks.size():
		if attack_timers[i] <= 0 and _is_attack_in_range(i, current_distance):
			var attack_type = attacks[i].attack_type
			match attack_type:
				"ranged": ranged_available.append(i)
				"melee": melee_available.append(i)
				"aoe": aoe_available.append(i)
	
	# Priority: ranged > aoe > melee
	var best_index = -1
	if not ranged_available.is_empty():
		best_index = ranged_available[0]
	elif not aoe_available.is_empty():
		best_index = aoe_available[0]
	elif not melee_available.is_empty():
		best_index = melee_available[0]
	
	if best_index != -1:
		_perform_attack(best_index)

func _perform_attack(index: int):
	var attack = attacks[index]
	attack_timers[index] = attack.cooldown
	
	match attack.attack_type:
		"melee":
			var dist = global_position.distance_to(player.global_position)
			if dist <= attack.range and player.has_method("take_damage"):
				player.take_damage(attack.damage)
		"ranged":
			_shoot_projectile(attack)
		"aoe":
			var dist = global_position.distance_to(player.global_position)
			if dist <= attack.range and player.has_method("take_damage"):
				player.take_damage(attack.damage)

func _shoot_projectile(attack: AttackData):
	if not attack.projectile_scene:
		return
	var proj = attack.projectile_scene.instantiate()
	get_tree().root.add_child(proj)
	proj.global_position = global_position
	var dir = (player.global_position - global_position).normalized()
	if proj.has_method("initialize"):
		proj.initialize(dir, attack.damage, self)
	else:
		proj.linear_velocity = dir * attack.projectile_speed

# --- Health bar fading ---
func on_hit():
	super.on_hit()
	var ratio = health / max_health
	var tween = create_tween()
	tween.tween_property(health_bar, "value", ratio * 100, 0.3)
	update_health_color(ratio)
	_show_health_bar()
	if hide_timer:
		hide_timer.timeout.disconnect(_start_fade_out)
	hide_timer = get_tree().create_timer(2.0)
	hide_timer.timeout.connect(_start_fade_out)

func update_health_color(ratio: float):
	fill_style.bg_color = get_health_color(ratio)

func _show_health_bar():
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	health_sprite.modulate.a = 1.0

func _start_fade_out():
	fade_tween = create_tween()
	fade_tween.tween_property(health_sprite, "modulate:a", 0.0, 0.5)

# Override flash_hit to avoid expensive mesh search
func flash_hit():
	pass

func on_death():
	# --- Drop system ---
	if enemy_data and randf() < enemy_data.drop_chance and not enemy_data.drop_table.is_empty():
		# Calculate total weight
		var total_weight = 0.0
		for entry in enemy_data.drop_table:
			total_weight += entry.weight
		
		# Weighted random pick
		var roll = randf() * total_weight
		var accum = 0.0
		for entry in enemy_data.drop_table:
			accum += entry.weight
			if roll <= accum:
				_spawn_pickup(entry.pickup_data)
				break
	
	# --- Existing death code (keep as is) ---
	set_physics_process(false)
	set_collision_layer(0)
	set_collision_mask(0)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	await tween.finished

# Helper function (add at bottom)
func _spawn_pickup(pickup_data: PickupData):
	var pickup = PICKUP_SCENE.instantiate()
	pickup.pickup_data = pickup_data
	get_tree().root.add_child(pickup)
	pickup.global_position = global_position
