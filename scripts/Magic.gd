extends "res://scripts/Tower.gd"

func _ready():
	super._ready()
	range_radius = 200
	damage = 40
	fire_rate = 0.5
	$Sprite2D.modulate = Color(0.4, 0.2, 0.8) # Purple for Magic

func fire():
	if not is_instance_valid(target): return
	can_fire = false
	# Magic logic: High damage, slow firing
	target.hit(damage)
	await get_tree().create_timer(1.0 / fire_rate).timeout
	can_fire = true
