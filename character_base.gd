extends CharacterBody3D
class_name CharacterBase

@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func apply_gravity(delta):

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0


func move_character():
	move_and_slide()


func face_target(target_position: Vector3):

	var direction = target_position - global_position
	direction.y = 0

	if direction.length() > 0:
		look_at(global_position + direction, Vector3.UP)
