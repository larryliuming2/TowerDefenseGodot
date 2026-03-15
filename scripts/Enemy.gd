extends PathFollow2D

@export var speed = 100
@export var health = 50
@export var reward = 10

func _ready():
	add_to_group("enemies")

func _process(delta):
	progress += speed * delta
	if progress_ratio >= 1.0:
		# Enemy reached the end - find Main node safely
		var main = get_tree().current_scene
		if main and main.has_method("take_damage"):
			main.take_damage(1)
		queue_free()

func hit(damage):
	health -= damage
	# Flash red on hit
	modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	
	if health <= 0:
		var main = get_tree().current_scene
		if main and main.has_method("add_gold"):
			main.add_gold(reward)
		queue_free()
