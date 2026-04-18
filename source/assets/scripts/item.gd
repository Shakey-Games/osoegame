extends Node2D

var icon: TextureRect
var item_ID: int
var item_grids := []
var selected = false
var grid_anchor = null
var is_consumable: bool = false   # <-- NEW

func _ready() -> void:
	if not icon:
		icon = $Icon

func load_item(a_itemID: int) -> void:
	item_ID = a_itemID
	if not icon:
		icon = $Icon
	
	var item_key = str(a_itemID)
	var item_info = DataHandler.item_data[item_key]
	
	var iconPath = "res://source/assets/textures/itemIcons/" + item_info["Name"] + ".png"
	if icon:
		icon.texture = load(iconPath)
	
	# Load consumable flag
	is_consumable = item_info.get("Consumable", false)
	
	for grid in DataHandler.item_grid_data[item_key]:
		var converterArray := []
		for i in grid:
			converterArray.push_back(int(i))
		item_grids.push_back(converterArray)


func _process(delta: float) -> void:
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)

func rotate_item():
	for grid in item_grids:
		var temp_y = grid[0]
		grid[0] = -grid[1]
		grid[1] = temp_y
	rotation_degrees += 90
	if rotation_degrees >= 360:
		rotation_degrees = 0

func _snap_to(destination):
	var tween = get_tree().create_tween()
	if int(rotation_degrees) % 180 == 0:
		destination += icon.size / 2
	else:
		var temp_xy_switch = Vector2(icon.size.y, icon.size.x)
		destination += temp_xy_switch / 2
	tween.tween_property(self, "global_position", destination, 0.15).set_trans(Tween.TRANS_SINE)
	selected = false
