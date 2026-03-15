extends "res://scripts/Tower.gd"

func _ready():
	range_radius = 150
	damage = 80
	fire_rate = 0.3
	super._ready()
	$Sprite2D.modulate = Color(0.8, 0.2, 0.2) # Red
