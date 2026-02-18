extends "res://scripts/Tower.gd"

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

func _ready():
	super._ready()
	anim.play("idle")
	# Sword girls have shorter range but higher damage
	range_radius = 150
	damage = 25
	fire_rate = 1.5

func fire():
	can_fire = false
	# Play sword slash animation
	anim.play("attack")
	# Wait for the slash to "hit" (mid-animation)
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(target):
		target.hit(damage)
	
	# Return to idle
	await anim.animation_finished
	anim.play("idle")
	
	await get_tree().create_timer(1.0 / fire_rate).timeout
	can_fire = true
