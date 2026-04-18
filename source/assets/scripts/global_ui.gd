extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var ammo_label = $AmmoLabel
@onready var soul_label = $SoulLabel
@onready var pickup_prompt = $PickupPrompt
@onready var inventory: Control = $Inventory

func _ready():
	# Connect signals
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_ammo_changed.connect(_on_ammo_changed)
	EventBus.player_soul_changed.connect(_on_soul_changed)
	EventBus.show_pickup_prompt.connect(_on_show_pickup_prompt)
	EventBus.hide_pickup_prompt.connect(_on_hide_pickup_prompt)
	#EventBus.add_item.connect(show_inventory)
	
	pickup_prompt.visible = false
	inventory.visible = false
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if inventory.visible:
			hide_inventory()
		else: 
			show_inventory(1)

func show_inventory(_item):
	print("boutta show inventory")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	inventory.visible = true
	EventBus.canMove = false

func hide_inventory():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	inventory.visible = false
	EventBus.canMove = true

func _on_health_changed(current, maximum):
	health_bar.max_value = maximum
	health_bar.value = current
	# Optional: update color
	var ratio = current / maximum
	var fill_style = health_bar.get_theme_stylebox("fill").duplicate()
	fill_style.bg_color = _get_health_color(ratio)
	health_bar.add_theme_stylebox_override("fill", fill_style)

func _on_ammo_changed(ammo):
	ammo_label.text = str(ammo)

func _on_soul_changed(soul):
	soul_label.text = str(soul)

func _on_show_pickup_prompt(prompt_text, _pickup_ref):
	pickup_prompt.text = "Press E to pick up " + prompt_text
	pickup_prompt.visible = true

func _on_hide_pickup_prompt():
	pickup_prompt.visible = false

func _get_health_color(ratio):
	if ratio > 0.6:
		return Color(0, 1, 0)
	elif ratio > 0.3:
		return Color(1, 1, 0)
	else:
		return Color(1, 0, 0)
