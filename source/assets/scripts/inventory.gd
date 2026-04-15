extends Control

@onready var slot_scene = preload("res://source/assets/scenes/slot.tscn")
@onready var grid_container = $ColorRect/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
var item_scene = preload("res://source/assets/scenes/item.tscn")
@onready var scroll_container: ScrollContainer = $ColorRect/MarginContainer/VBoxContainer/ScrollContainer
@onready var col_count = grid_container.columns

var grid_array := []
var itemHeld = null
var currentSlot = null
var canPlace :=  false
var iconAnchor: Vector2

func _ready() -> void:
	for i in range(68):
		create_slot()
		
func _process(delta: float) -> void:
	if itemHeld:
		if Input.is_action_just_pressed("mouse_rightclick"):
			rotate_item()
		
func create_slot() -> void:
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	grid_array.push_back(new_slot)
	grid_container.add_child(new_slot)
	new_slot.slot_entered.connect(on_slot_mouse_entered)
	new_slot.slot_exited.connect(on_slot_mouse_exited)

func on_slot_mouse_entered(a_Slot):
	iconAnchor = Vector2(10000, 10000)
	currentSlot = a_Slot
	if itemHeld:
		check_slot_availability(currentSlot)
		set_grids.call_deferred(currentSlot)
	#a_Slot.set_colour(a_Slot.States.TAKEN)
	
func on_slot_mouse_exited(a_Slot):
	clear_grid()
	#a_Slot.set_colour(a_Slot.States.DEFAULT)

func _on_spawner_button_pressed() -> void:
	var newItem = item_scene.instantiate()
	add_child(newItem)
	newItem.load_item(1)
	newItem.selected = true
	itemHeld = newItem

func check_slot_availability(aSlot) -> void:
	for grid in itemHeld.item_grids:
		var gridToCheck = aSlot.slot_ID + grid[0] + grid[1] * col_count
		var lineSwitchCheck = aSlot.slot_ID & col_count * grid[0]
		if lineSwitchCheck < 0 or lineSwitchCheck >= col_count:
			canPlace = false
			return
		if gridToCheck < 0 or gridToCheck >= grid_array.size():
			canPlace = false
			return
		if grid_array[gridToCheck].state == grid_array[gridToCheck].States.TAKEN:
			canPlace = false
			return
		canPlace = true
			
		
func set_grids(aSlot):
	for grid in itemHeld.item_grids:
		var gridToCheck = aSlot.slot_ID + grid[0] + grid[1] * col_count
		var lineSwitchCheck = aSlot.slot_ID & col_count * grid[0]
		if gridToCheck < 0 or gridToCheck >= grid_array.size():
			continue
		if lineSwitchCheck < 0 or lineSwitchCheck >= col_count:
			continue
		if canPlace:
			grid_array[gridToCheck].set_colour(grid_array[gridToCheck].States.FREE)
			if grid[1] < iconAnchor.x: iconAnchor.x = grid[1]
			if grid[0] < iconAnchor.y: iconAnchor.y = grid[0]
		else:
			grid_array[gridToCheck].set_colour(grid_array[gridToCheck].States.TAKEN)
		
func clear_grid():
	for grid in grid_array:
		grid.set_colour(grid.States.DEFAULT)

func rotate_item():
	itemHeld.rotate_item()
	clear_grid()
	if currentSlot:
		on_slot_mouse_entered(currentSlot)
