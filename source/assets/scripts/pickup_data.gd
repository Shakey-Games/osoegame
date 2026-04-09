extends Resource
class_name PickupData

enum ItemType {
	PISTOL_AMMO,
	HEALTH,
	SOUL,
}

@export var item_type: ItemType = ItemType.PISTOL_AMMO
@export var amount: int = 1
@export var pickup_sound: AudioStream
@export var display_name: String = "Item"   # <-- new: custom name for prompt

# Optional: auto-fill from type if left blank
func get_display_name() -> String:
	if display_name != "":
		return display_name
	# Fallback to type name
	match item_type:
		ItemType.PISTOL_AMMO: return "Pistol Ammo"
		ItemType.HEALTH: return "Health"
		ItemType.SOUL: return "Soul"
		_: return "Item"
