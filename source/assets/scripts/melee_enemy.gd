extends BaseEnemy
class_name MeleeEnemy

func attack():
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage)
