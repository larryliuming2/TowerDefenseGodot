extends "res://scripts/Tower.gd"

func _ready():
	range_radius = 200
	damage = 40
	fire_rate = 0.5
	super._ready()
	$Sprite2D.modulate = Color(0.4, 0.2, 0.8) # Purple
