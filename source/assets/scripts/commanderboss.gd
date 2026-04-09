extends Boss
class_name CommanderBoss

@export var phase_2_speed_multiplier: float = 1.3
@export var phase_3_speed_multiplier: float = 1.6

func _on_phase_transition(phase: int):
	super(phase)
	match phase:
		2:
			speed = enemy_data.speed * phase_2_speed_multiplier
			print("Commander speeds up (phase 2)")
		3:
			speed = enemy_data.speed * phase_3_speed_multiplier
			print("Commander speeds up (phase 3)")
