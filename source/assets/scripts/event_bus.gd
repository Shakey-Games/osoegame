extends Node

var canMove = true

# Pickup prompts
signal show_pickup_prompt(prompt_text, pickup_ref)
signal hide_pickup_prompt

# Player stats
signal player_health_changed(current_health, max_health)
signal player_ammo_changed(current_ammo)
signal player_soul_changed(current_soul)

signal add_item(item)
	
