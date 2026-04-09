extends Area3D
class_name Pickup

@export var pickup_data: PickupData
@export var lifetime: float = 30.0

func _ready():
	if pickup_data == null:
		print("Pickup has no PickupData – removing")
		queue_free()
		return
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		EventBus.show_pickup_prompt.emit(pickup_data.get_display_name(), self)

func _on_body_exited(body):
	if body.is_in_group("player"):
		EventBus.hide_pickup_prompt.emit()

func pickup(player: Node):
	match pickup_data.item_type:
		PickupData.ItemType.PISTOL_AMMO:
			player.add_ammo(pickup_data.amount)
		PickupData.ItemType.HEALTH:
			player.heal(pickup_data.amount)
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
