extends "res://scripts/Tower.gd"

func _ready():
	super._ready()
	range_radius = 100
	damage = 100
	fire_rate = 0.2
	$Sprite2D.modulate = Color(0.8, 0.2, 0.2) # Red for Boom

func fire():
	if not is_instance_valid(target): return
	can_fire = false
	# Boom logic: High damage, very slow firing, area effect
	# For now, let's just do single target high damage
	target.hit(damage)
	await get_tree().create_timer(1.0 / fire_rate).timeout
	can_fire = true
