extends "res://scripts/Tower.gd"

func _ready():
	range_radius = 150
	damage = 25
	fire_rate = 1.5
	super._ready()
	# Play idle animation if available
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("idle")

func fire():
	if not is_instance_valid(target):
		return
	can_fire = false
	
	# Attack animation
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("attack")
		await $AnimationPlayer.animation_finished
		$AnimationPlayer.play("idle")
	
	if is_instance_valid(target):
		target.hit(damage)
	
	var timer = get_tree().create_timer(1.0 / fire_rate)
	timer.timeout.connect(func(): can_fire = true)
