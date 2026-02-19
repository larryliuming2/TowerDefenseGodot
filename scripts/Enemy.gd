extends PathFollow2D

@export var speed = 100
@export var health = 50
@export var reward = 10

func _ready():
	add_to_group("enemies")

func _process(delta):
	progress += speed * delta
	if progress_ratio >= 1.0:
		# Enemy reached the end!
		get_tree().root.get_node("Main").take_damage(1)
		queue_free()

func hit(damage):
	health -= damage
	if health <= 0:
		get_tree().root.get_node("Main").add_gold(reward)
		queue_free()
