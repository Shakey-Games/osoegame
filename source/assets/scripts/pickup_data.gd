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
@export var display_name: String = "Item"
@export var inventory_item_id: int = -1   # -1 = not storable in inventory

func get_display_name() -> String:
	if display_name != "":
		return display_name
	match item_type:
		ItemType.PISTOL_AMMO: return "Pistol Ammo"
		ItemType.HEALTH: return "Health"
		ItemType.SOUL: return "Soul"
		_: return "Item"
