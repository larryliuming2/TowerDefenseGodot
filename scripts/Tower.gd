extends Node2D

@export var damage = 10
@export var fire_rate = 1.0 # Shots per second
@export var range_radius = 200

var target = null
var can_fire = true

func _ready():
	$RangeArea/CollisionShape2D.shape.radius = range_radius

func _process(_delta):
	if target and is_instance_valid(target):
		if can_fire:
			fire()
	else:
		find_target()

func find_target():
	var enemies = $RangeArea.get_overlapping_areas()
	if enemies.size() > 0:
		var best_enemy = null
		var max_progress = -1
		for area in enemies:
			var enemy = area.get_parent()
			# Check if the parent is an Enemy (PathFollow2D)
			if enemy is PathFollow2D:
				if enemy.progress > max_progress:
					max_progress = enemy.progress
					best_enemy = enemy
		target = best_enemy
	else:
		target = null

func fire():
	can_fire = false
	# Visuals: Show attack animation/projectile here
	target.hit(damage)
	await get_tree().create_timer(1.0 / fire_rate).timeout
	can_fire = true
