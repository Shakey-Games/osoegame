extends Control

@onready var slot_scene = preload("res://source/assets/scenes/slot.tscn")
@onready var grid_container = $ColorRect/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
var item_scene = preload("res://source/assets/scenes/item.tscn")
@onready var scroll_container: ScrollContainer = $ColorRect/MarginContainer/VBoxContainer/ScrollContainer
@onready var col_count = grid_container.columns
@onready var color_rect: ColorRect = $ColorRect


var grid_array := []
var itemHeld = null
var currentSlot = null
var canPlace :=  false
var iconAnchor: Vector2

func _ready() -> void:
	for i in range(68):
		create_slot()
	EventBus.add_item.connect(add_item)
		
func _process(delta: float) -> void:
	if itemHeld:
		if Input.is_action_just_pressed("mouse_rightclick"):
			rotate_item()

		if Input.is_action_just_pressed("mouse_leftclick"):
			var mouse_pos = get_global_mouse_position()

			# If clicked outside panel → discard
			if not color_rect.get_global_rect().has_point(mouse_pos):
				discard_item()
				return

			# If inside panel → try placing
			place_item()
	else:
		if Input.is_action_just_pressed("mouse_leftclick"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				pick_item()

func add_item(item: int):
	print("reached here!")
	print(item)
	var newItem = item_scene.instantiate()
	add_child(newItem)
	newItem.load_item(item)
	newItem.selected = true
	itemHeld = newItem

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
	#aSlot.set_colour(aSlot.States.TAKEN)
	
func on_slot_mouse_exited(aSlot):
	clear_grid()

	# Only clear if we actually exited the current slot
	if currentSlot == aSlot:
		currentSlot = null
		canPlace = false

func _on_spawner_button_pressed() -> void:
	var newItem = item_scene.instantiate()
	add_child(newItem)
	newItem.load_item(randi_range(0,1))
	newItem.selected = true
	itemHeld = newItem

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
		#make sure the check don't wrap around boarders
		var line_switch_check = aSlot.slot_ID % col_count + grid[0]
		if line_switch_check <0 or line_switch_check >= col_count:
			continue
		
		if canPlace:
			grid_array[grid_to_check].set_colour(grid_array[grid_to_check].States.FREE)
			#save anchor for snapping
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
		
	#for changing scene tree
	itemHeld.get_parent().remove_child(itemHeld)
	grid_container.add_child(itemHeld)
	itemHeld.global_position = get_global_mouse_position()
	####
	var calculated_grid_id = currentSlot.slot_ID + iconAnchor.x * col_count + iconAnchor.y
	itemHeld._snap_to(grid_array[calculated_grid_id].global_position)
	print(calculated_grid_id)
	itemHeld.grid_anchor = currentSlot
	for grid in itemHeld.item_grids:
		var grid_to_check = currentSlot.slot_ID + grid[0] + grid[1] * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN 
		grid_array[grid_to_check].item_stored = itemHeld
	
	#put item into a data storage here
	
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
	#move node in the scene tree
	itemHeld.get_parent().remove_child(itemHeld)
	add_child(itemHeld)
	itemHeld.global_position = get_global_mouse_position()
	####
	
	for grid in itemHeld.item_grids:
		var grid_to_check = itemHeld.grid_anchor.slot_ID + grid[0] + grid[1] * col_count # use grid anchor instead of current slot to prevent bug
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
