extends Node2D

@export var damage = 10
@export var fire_rate = 1.0
@export var range_radius = 200

var target = null
var can_fire = true

func _ready():
	# Duplicate the shape so each tower instance has its own radius
	var shape = $RangeArea/CollisionShape2D.shape.duplicate()
	shape.radius = range_radius
	$RangeArea/CollisionShape2D.shape = shape

func _process(_delta):
	# Only search for targets periodically-ish (every frame is fine for now)
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_enemy = null
	var max_progress = -1.0
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= range_radius and enemy.progress > max_progress:
				max_progress = enemy.progress
				best_enemy = enemy
	
	target = best_enemy
	
	if target and is_instance_valid(target) and can_fire:
		fire()

func fire():
	if not is_instance_valid(target):
		return
	can_fire = false
	target.hit(damage)
	# Use a one-shot timer for cooldown
	var timer = get_tree().create_timer(1.0 / fire_rate)
	timer.timeout.connect(func(): can_fire = true)
