extends Node2D

@export var particle_count = 20
@export var lifetime = 1.0

func _ready():
	# Create a simple CPUParticles2D for the cherry blossom effect
	var particles = CPUParticles2D.new()
	add_child(particles)
	
	particles.amount = particle_count
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.spread = 180.0
	particles.gravity = Vector2(0, 50) # Gentle falling
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	
	# Pink/Cherry Blossom color
	particles.color = Color(1.0, 0.75, 0.8, 1.0) 
	
	particles.emitting = true
	
	# Auto-cleanup after effect is done
	await get_tree().create_timer(lifetime + 0.5).timeout
	queue_free()
