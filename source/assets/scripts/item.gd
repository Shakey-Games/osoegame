extends Node2D

@onready var icon: TextureRect = $Icon

var item_ID: int
var item_grids := []
var selected = false
var grid_anchor = null

func _ready() -> void:
	#load_item(1)
	#selected = true
	pass

func _process(delta: float) -> void:
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)

func load_item(a_itemID: int) -> void:
	var iconPath = "res://source/assets/textures/itemIcons/" + DataHandler.item_data[str(a_itemID)]["Name"] + ".png"
	icon.texture = load(iconPath)
	for grid in DataHandler.item_grid_data[str(a_itemID)]:
		var converterArray := []
		for i in grid:
			converterArray.push_back(int(i))
		item_grids.push_back(converterArray)
		
func rotate_item():
	for grid in item_grids:
		var temp_y = grid[0]
		grid[0] = -grid[1]
		grid[1] = temp_y
	rotation_degrees += 90
	if rotation_degrees>=360:
		rotation_degrees = 0
		
func _snap_to(destination):
	var tween = get_tree().create_tween()
	#separate cases to avoid snapping errors
	if int(rotation_degrees) % 180 == 0:
		destination += icon.size/2
	else:
		var temp_xy_switch = Vector2(icon.size.y,icon.size.x)
		destination += temp_xy_switch/2
	tween.tween_property(self, "global_position", destination, 0.15).set_trans(Tween.TRANS_SINE)
	selected = false
	
