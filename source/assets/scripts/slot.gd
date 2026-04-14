extends TextureRect

signal slot_entered(slot)
signal slot_exited(slot)

@onready var filter: ColorRect = $StatusFilter

var slot_ID: int
var is_hovering: bool = false
enum States {DEFAULT, TAKEN, FREE}
var state = States.DEFAULT
var item_stored = null

func set_colour(a_state = States.DEFAULT) -> void:
	match a_state:
		States.DEFAULT:
			filter.color = Color(Color.WHITE, 0)
		States.TAKEN:
			filter.color = Color(Color.RED, 0.2)
		States.FREE:
			filter.color = Color(Color.GREEN, 0.2)
			
func _process(delta: float) -> void:
	if get_global_rect().has_point(get_global_mouse_position()):
		if not is_hovering:
			is_hovering = true
			emit_signal("slot_entered", self)
	else:
		if is_hovering:
			is_hovering = false 
			emit_signal("slot_exited", self)
