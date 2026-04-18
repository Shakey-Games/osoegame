extends Area3D
class_name Pickup

@export var pickup_data: PickupData
@export var lifetime: float = 30.0

func _ready():
	if pickup_data == null:
		print("Pickup has no PickupData – removing")
		queue_free()
		return
	
	_snap_to_ground()
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _snap_to_ground():
	var space_state = get_world_3d().direct_space_state
	var ray_start = global_position + Vector3.UP * 0.5
	var ray_end = global_position + Vector3.DOWN * 10.0
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0xFFFFFFFF)
	var result = space_state.intersect_ray(query)
	if result:
		global_position = result.position
	else:
		print("No ground found for pickup, staying at ", global_position)

func _on_body_entered(body):
	if body.is_in_group("player"):
		EventBus.show_pickup_prompt.emit(pickup_data.get_display_name(), self)

func _on_body_exited(body):
	if body.is_in_group("player"):
		EventBus.hide_pickup_prompt.emit()

func pickup(player: Node):
	# Determine if this item goes into inventory
	var inv_item_id = _get_inventory_item_id()
	
	# If it's an inventory item, check space first
	if inv_item_id >= 0:
		if not EventBus.can_add_item_to_inventory(inv_item_id):
			# Inventory full – abort pickup
			EventBus.show_pickup_prompt.emit("Inventory Full!", self)
			# Optionally play a "fail" sound
			return
	
	# Proceed with normal pickup effects
	match pickup_data.item_type:
		PickupData.ItemType.PISTOL_AMMO:
			player.add_ammo(pickup_data.amount)
			EventBus.add_item.emit(inv_item_id)
		PickupData.ItemType.HEALTH:
			player.heal(pickup_data.amount)
			EventBus.add_item.emit(inv_item_id)
		PickupData.ItemType.SOUL:
			player.add_soul(pickup_data.amount)
			# Souls don't go into inventory, so no add_item emit
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

func _get_inventory_item_id() -> int:
	# Use the new field if you added it to PickupData
	if pickup_data.inventory_item_id >= 0:
		return pickup_data.inventory_item_id
	
	# Fallback mapping based on item_type (adjust IDs to match your JSON)
	match pickup_data.item_type:
		PickupData.ItemType.PISTOL_AMMO:
			return 0
		PickupData.ItemType.HEALTH:
			return 1
		_:
			return -1   # Not storable
