extends BaseEnemy
class_name Boss

# Phase tracking
var current_phase: int = 1
var phase_transition_played: bool = false

# Boss UI
var boss_ui_node: Control = null
var boss_name_label: Label = null
var boss_health_bar: ProgressBar = null
var boss_fill_style: StyleBoxFlat = null

func _ready():
	super()
	
	if not enemy_data.is_boss:
		print("Warning: ", name, " has Boss script but enemy_data.is_boss = false")
		return
	
	# Disable floating health bar above head
	if health_sprite:
		health_sprite.visible = false
	if health_bar:
		health_bar.visible = false
	
	await get_tree().process_frame
	_create_boss_ui()

func _create_boss_ui():
	var ui_scene = load("res://source/assets/scenes/boss_ui.tscn")
	if not ui_scene:
		print("BossUI.tscn not found – skipping boss UI")
		return
	
	var canvas_layer = get_tree().root.get_node_or_null("BossUILayer")
	if not canvas_layer:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "BossUILayer"
		canvas_layer.layer = 10
		get_tree().root.add_child(canvas_layer)
	
	boss_ui_node = ui_scene.instantiate()
	canvas_layer.add_child(boss_ui_node)
	
	boss_name_label = boss_ui_node.get_node("VBoxContainer/NameLabel")
	boss_health_bar = boss_ui_node.get_node("VBoxContainer/HealthBar")
	
	boss_name_label.text = enemy_data.display_name
	boss_health_bar.max_value = max_health
	boss_health_bar.value = health
	
	# Copy style from floating health bar
	if health_bar and health_bar.get_theme_stylebox("fill") is StyleBoxFlat:
		boss_fill_style = health_bar.get_theme_stylebox("fill").duplicate()
		boss_health_bar.add_theme_stylebox_override("fill", boss_fill_style)
	
	# Use shared health color logic
	boss_fill_style.bg_color = get_health_color(health / max_health)
	boss_ui_node.visible = true

func _update_boss_ui():
	if not boss_health_bar:
		return
	
	var tween = create_tween()
	tween.tween_property(boss_health_bar, "value", health, 0.3)
	if boss_fill_style:
		boss_fill_style.bg_color = get_health_color(health / max_health)

func _hide_boss_ui():
	if boss_ui_node:
		boss_ui_node.queue_free()
		boss_ui_node = null

# Override to prevent floating health bar from showing
func _show_health_bar():
	pass

func take_damage(amount: float):
	super.take_damage(amount)
	_update_boss_ui()
	
	var ratio = health / max_health
	if not phase_transition_played:
		if ratio <= enemy_data.phase_3_health_ratio and current_phase < 3:
			current_phase = 3
			phase_transition_played = true
			_on_phase_transition(3)
		elif ratio <= enemy_data.phase_2_health_ratio and current_phase < 2:
			current_phase = 2
			phase_transition_played = true
			_on_phase_transition(2)
		else:
			phase_transition_played = false

func _on_phase_transition(phase: int):
	print(name, " enters phase ", phase)

func on_death():
	_on_boss_defeated()
	_hide_boss_ui()
	super.on_death()

func _on_boss_defeated():
	print(name, " defeated!")
