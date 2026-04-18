extends Area3D
class_name Pickup

@export var pickup_data: PickupData
@export var lifetime: float = 30.0

func _ready():
	if pickup_data == null:
		print("Pickup has no PickupData – removing")
		queue_free()
		return
	
	# Snap to ground before becoming visible
	_snap_to_ground()
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _snap_to_ground():
	# Raycast downward from the pickup's current position
	var space_state = get_world_3d().direct_space_state
	var ray_start = global_position + Vector3.UP * 0.5   # start slightly above
	var ray_end = global_position + Vector3.DOWN * 10.0  # down up to 10 units
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0xFFFFFFFF)  # all collision layers
	var result = space_state.intersect_ray(query)
	if result:
		# Place pickup exactly on the ground
		global_position = result.position
	else:
		# If no ground found, keep original position (fallback)
		print("No ground found for pickup, staying at ", global_position)

func _on_body_entered(body):
	if body.is_in_group("player"):
		EventBus.show_pickup_prompt.emit(pickup_data.get_display_name(), self)

func _on_body_exited(body):
	if body.is_in_group("player"):
		EventBus.hide_pickup_prompt.emit()
#
func pickup(player: Node):
	match pickup_data.item_type:
		PickupData.ItemType.PISTOL_AMMO:
			player.add_ammo(pickup_data.amount)
			EventBus.emit_signal("add_item", 0)
		PickupData.ItemType.HEALTH:
			player.heal(pickup_data.amount)
			EventBus.emit_signal("add_item", 1)
		PickupData.ItemType.SOUL:
			player.add_soul(pickup_data.amount)
		_:
			print("Unknown item type")
	
	if pickup_data.pickup_sound:
		var audio = AudioStreamPlayer3D.new()
		audio.stream = pickup_data.pickup_sound
		audio.autoplay = true
		add_child(audio)
		await audio.finished
		audio.queue_free()
	
	queue_free()
