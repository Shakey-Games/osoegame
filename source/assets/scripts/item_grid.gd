extends GridContainer

@export var inventory_slot_scene: PackedScene
@export var dimensions: Vector2i
var slot_data: Array[Node] = []

const SLOT_SIZE: int  = 32

func _ready() -> void:
	create_slots()
	init_slot_data()
	
func create_slots() -> void:
	self.columns = dimensions.x
	for x in dimensions.x:
		for y in dimensions.y:
			var inventory_slot = inventory_slot_scene.instantiate()
			add_child(inventory_slot)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			var index = get_slot_index_from_coords(get_global_mouse_position())
			print(index, get_coords_index_from_slot_index(index))

func init_slot_data() -> void:
	slot_data.resize(dimensions.x * dimensions.y)
	slot_data.fill(null)
	
func get_slot_index_from_coords(coords: Vector2i) -> int:
	coords -= Vector2i(self.global_position)
	coords = coords / SLOT_SIZE
	var index = coords.x + coords.y * columns
	if index > dimensions.x * dimensions.y || index < 0:
		return -1
	return index
	
func get_coords_index_from_slot_index(index: int) -> Vector2i:
	var row = index / self.columns
	var columns = index % self.columns 
	return Vector2i(global_position) + Vector2i(columns * SLOT_SIZE, row * SLOT_SIZE)
