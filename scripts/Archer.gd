extends "res://scripts/Tower.gd"

func _ready():
	super._ready()
	range_radius = 300
	damage = 15
	fire_rate = 2.0
	$Sprite2D.modulate = Color(0.8, 0.4, 0.2) # Orange for Archer

func fire():
	if not is_instance_valid(target): return
	can_fire = false
	# Archer logic: Long range, fast firing
	target.hit(damage)
	await get_tree().create_timer(1.0 / fire_rate).timeout
	can_fire = true
