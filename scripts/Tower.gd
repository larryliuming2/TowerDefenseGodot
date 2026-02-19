extends Node2D

@export var damage = 10
@export var fire_rate = 1.0 # Shots per second
@export var range_radius = 200

var target = null
var can_fire = true

func _ready():
	$RangeArea/CollisionShape2D.shape.radius = range_radius

func find_target():
	var best_enemy = null
	var max_progress = -1
	
	# Get all enemies in the scene
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= range_radius:
				# Target the one furthest along the path
				if enemy.progress > max_progress:
					max_progress = enemy.progress
					best_enemy = enemy
	
	target = best_enemy

func _process(_delta):
	find_target() # Keep looking for the best target every frame
	if target and is_instance_valid(target):
		if can_fire:
			fire()

func fire():
	can_fire = false
	# Visuals: Show attack animation/projectile here
	target.hit(damage)
	await get_tree().create_timer(1.0 / fire_rate).timeout
	can_fire = true
