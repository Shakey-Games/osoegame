extends Control

var context_menu: PopupMenu
var context_slot: Slot = null

# Preload classes for type hints
const Slot = preload("res://source/assets/scripts/slot.gd")
const Item = preload("res://source/assets/scripts/item.gd")

@onready var slot_scene = preload("res://source/assets/scenes/slot.tscn")
@onready var grid_container = $ColorRect/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
var item_scene = preload("res://source/assets/scenes/item.tscn")
@onready var scroll_container: ScrollContainer = $ColorRect/MarginContainer/VBoxContainer/ScrollContainer
@onready var col_count = grid_container.columns
@onready var color_rect: ColorRect = $ColorRect

var grid_array := []
var itemHeld = null
var currentSlot = null
var canPlace := false
var iconAnchor: Vector2

func _ready() -> void:
	for i in range(68):
		create_slot()
	EventBus.add_item.connect(add_item)
	EventBus.register_inventory(self)
	context_menu = PopupMenu.new()
	add_child(context_menu)
	context_menu.add_item("Consume", 0)
	context_menu.id_pressed.connect(_on_context_menu_selected)
	
func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Check if mouse is over a slot with an item
		var mouse_pos = get_global_mouse_position()
		for slot in grid_array:
			if slot.get_global_rect().has_point(mouse_pos) and slot.item_stored:
				_show_context_menu(slot, mouse_pos)
				return
		# If right-clicked elsewhere, hide menu
		context_menu.hide()

func _show_context_menu(slot: Slot, position: Vector2):
	context_slot = slot
	var item = slot.item_stored
	if item.is_consumable:
		context_menu.set_item_disabled(0, false)
	else:
		context_menu.set_item_disabled(0, true)
	context_menu.position = position
	context_menu.popup()

func _on_context_menu_selected(id: int):
	match id:
		0:  # Consume
			if context_slot and context_slot.item_stored:
				_consume_item(context_slot.item_stored)
	context_menu.hide()
	context_slot = null
	
func _consume_item(item: Item):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Apply effect based on item ID (or data)
	match item.item_ID:
		1:  # Medkit
			player.heal(50)  # Or read amount from data
	
	# Remove item from inventory grid
	var slots_to_clear = []
	for slot in grid_array:
		if slot.item_stored == item:
			slots_to_clear.append(slot)
	
	for slot in slots_to_clear:
		slot.state = slot.States.FREE
		slot.item_stored = null
		slot.set_colour(slot.States.DEFAULT)
	
	item.queue_free()

func _process(delta: float) -> void:
	if itemHeld:
		if Input.is_action_just_pressed("mouse_rightclick"):
			rotate_item()

		if Input.is_action_just_pressed("mouse_leftclick"):
			var mouse_pos = get_global_mouse_position()
			if not color_rect.get_global_rect().has_point(mouse_pos):
				discard_item()
				return
			place_item()
	else:
		if Input.is_action_just_pressed("mouse_leftclick"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				pick_item()

func add_item(item_id: int):
	var new_item = item_scene.instantiate()
	add_child(new_item)
	new_item.load_item(item_id)
	
	# Try auto-placement
	var valid_slot = find_valid_slot_for_item(new_item)
	if valid_slot:
		place_item_at_slot(valid_slot, new_item)
		print("Item ", item_id, " added to inventory.")
	else:
		new_item.queue_free()
		print("Inventory full – cannot add item.")
		# Optional: show a temporary message
		EventBus.show_pickup_prompt.emit("Inventory Full!", null)
		await get_tree().create_timer(2.0).timeout
		EventBus.hide_pickup_prompt.emit()

func find_valid_slot_for_item(item: Item) -> Slot:
	for slot in grid_array:
		if can_place_item_at_slot(slot, item):
			return slot
	return null

func can_place_item_at_slot(slot: Slot, item: Item) -> bool:
	for grid in item.item_grids:
		var target_idx = slot.slot_ID + grid[0] + grid[1] * col_count
		var line_switch_check = slot.slot_ID % col_count + grid[0]
		
		if line_switch_check < 0 or line_switch_check >= col_count:
			return false
		if target_idx < 0 or target_idx >= grid_array.size():
			return false
		if grid_array[target_idx].state == grid_array[target_idx].States.TAKEN:
			return false
	return true

func place_item_at_slot(slot: Slot, item: Item):
	item.get_parent().remove_child(item)
	grid_container.add_child(item)
	
	# Calculate anchor offsets (smallest x and y in item's grid)
	var anchor_x = 0
	var anchor_y = 0
	for grid in item.item_grids:
		if grid[1] < anchor_x: anchor_x = grid[1]
		if grid[0] < anchor_y: anchor_y = grid[0]
	
	var anchor_slot_idx = slot.slot_ID + anchor_x * col_count + anchor_y
	var anchor_slot = grid_array[anchor_slot_idx]
	
	item._snap_to(anchor_slot.global_position)
	item.grid_anchor = anchor_slot
	
	for grid in item.item_grids:
		var target_idx = slot.slot_ID + grid[0] + grid[1] * col_count
		grid_array[target_idx].state = grid_array[target_idx].States.TAKEN
		grid_array[target_idx].item_stored = item

func can_add_item(item_id: int) -> bool:
	var dummy = item_scene.instantiate()
	dummy.load_item(item_id)
	var has_space = find_valid_slot_for_item(dummy) != null
	dummy.queue_free()
	return has_space

func create_slot() -> void:
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	grid_array.push_back(new_slot)
	grid_container.add_child(new_slot)
	new_slot.slot_entered.connect(on_slot_mouse_entered)
	new_slot.slot_exited.connect(on_slot_mouse_exited)

func on_slot_mouse_entered(aSlot):
	iconAnchor = Vector2.ZERO
	currentSlot = aSlot
	if itemHeld:
		check_slot_availability(currentSlot)
		set_grids.call_deferred(currentSlot)

func on_slot_mouse_exited(aSlot):
	clear_grid()
	if currentSlot == aSlot:
		currentSlot = null
		canPlace = false

func check_slot_availability(aSlot) -> void:
	for grid in itemHeld.item_grids:
		var grid_to_check = aSlot.slot_ID + grid[0] + grid[1] * col_count
		var line_switch_check = aSlot.slot_ID % col_count + grid[0]
		if line_switch_check < 0 or line_switch_check >= col_count:
			canPlace = false
			return
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			canPlace = false
			return
		if grid_array[grid_to_check].state == grid_array[grid_to_check].States.TAKEN:
			canPlace = false
			return
	canPlace = true

func set_grids(aSlot):
	for grid in itemHeld.item_grids:
		var grid_to_check = aSlot.slot_ID + grid[0] + grid[1] * col_count
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			continue
		var line_switch_check = aSlot.slot_ID % col_count + grid[0]
		if line_switch_check < 0 or line_switch_check >= col_count:
			continue
		if canPlace:
			grid_array[grid_to_check].set_colour(grid_array[grid_to_check].States.FREE)
			if grid[1] < iconAnchor.x: iconAnchor.x = grid[1]
			if grid[0] < iconAnchor.y: iconAnchor.y = grid[0]
		else:
			grid_array[grid_to_check].set_colour(grid_array[grid_to_check].States.TAKEN)

func clear_grid():
	for grid in grid_array:
		grid.set_colour(grid.States.DEFAULT)

func rotate_item():
	itemHeld.rotate_item()
	clear_grid()
	if currentSlot:
		on_slot_mouse_entered(currentSlot)

func place_item():
	if not currentSlot:
		return
	check_slot_availability(currentSlot)
	if not canPlace:
		return
	itemHeld.get_parent().remove_child(itemHeld)
	grid_container.add_child(itemHeld)
	itemHeld.global_position = get_global_mouse_position()
	var calculated_grid_id = currentSlot.slot_ID + iconAnchor.x * col_count + iconAnchor.y
	itemHeld._snap_to(grid_array[calculated_grid_id].global_position)
	itemHeld.grid_anchor = currentSlot
	for grid in itemHeld.item_grids:
		var grid_to_check = currentSlot.slot_ID + grid[0] + grid[1] * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN
		grid_array[grid_to_check].item_stored = itemHeld
	itemHeld = null
	clear_grid()

func pick_item():
	if not currentSlot:
		return
	var picked_item = currentSlot.item_stored
	if not picked_item:
		return
	itemHeld = currentSlot.item_stored
	itemHeld.selected = true
	itemHeld.get_parent().remove_child(itemHeld)
	add_child(itemHeld)
	itemHeld.global_position = get_global_mouse_position()
	for grid in itemHeld.item_grids:
		var grid_to_check = itemHeld.grid_anchor.slot_ID + grid[0] + grid[1] * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.FREE
		grid_array[grid_to_check].item_stored = null
	check_slot_availability(currentSlot)
	set_grids.call_deferred(currentSlot)

func discard_item():
	if itemHeld:
		itemHeld.queue_free()
		itemHeld = null
		currentSlot = null
		canPlace = false
		clear_grid()
