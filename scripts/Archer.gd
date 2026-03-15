extends "res://scripts/Tower.gd"

func _ready():
	range_radius = 300
	damage = 15
	fire_rate = 2.0
	super._ready()
	$Sprite2D.modulate = Color(0.8, 0.4, 0.2) # Orange
