extends Node2D

var gold = 100
var lives = 20
var wave = 1

@onready var ui_gold = $CanvasLayer/HUD/GoldLabel
@onready var ui_lives = $CanvasLayer/HUD/LivesLabel
@onready var spawner_timer = $SpawnerTimer

var enemy_scene = preload("res://scenes/Enemy.tscn")
var current_wave_health = 50

var is_fast_forward = false

func _ready():
	update_ui()
	spawner_timer.timeout.connect(_on_spawner_timeout)
	$CanvasLayer/HUD/SpeedButton.pressed.connect(_on_speed_button_pressed)
	$CanvasLayer/HUD/SummonButton.pressed.connect(_on_summon_pressed)
	print("Tower Defense Game Started!")

func _on_speed_button_pressed():
	is_fast_forward = !is_fast_forward
	Engine.time_scale = 2.0 if is_fast_forward else 1.0
	$CanvasLayer/HUD/SpeedButton.text = "Speed: 2x" if is_fast_forward else "Speed: 1x"

var is_placing_tower = false
var ghost_tower = null

func _process(_delta):
	if is_placing_tower and ghost_tower:
		ghost_tower.position = get_global_mouse_position()
		if Input.is_action_just_pressed("click"): # We'll define this in next step
			confirm_placement()

func _on_summon_pressed():
	if gold >= 50 and not is_placing_tower:
		is_placing_tower = true
		ghost_tower = load("res://scenes/SwordGirl.tscn").instantiate()
		ghost_tower.modulate.a = 0.5 # Make it semi-transparent
		add_child(ghost_tower)

func _input(event):
	if is_placing_tower and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			confirm_placement()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_placement()

func confirm_placement():
	gold -= 50
	update_ui()
	ghost_tower.modulate.a = 1.0 # Make it solid
	# Add the cherry blossom effect!
	var effect = load("res://scenes/SummonEffect.tscn").instantiate()
	effect.position = ghost_tower.position
	add_child(effect)
	
	is_placing_tower = false
	ghost_tower = null

func cancel_placement():
	is_placing_tower = false
	ghost_tower.queue_free()
	ghost_tower = null

func _on_spawner_timeout():
	spawn_enemy()

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.health = current_wave_health
	$Path2D.add_child(enemy)
	
	# Every 10 enemies, increase health for the next ones
	current_wave_health += 5 

func update_ui():
	ui_gold.text = "Gold: " + str(gold)
	ui_lives.text = "Lives: " + str(lives)

func take_damage(amount):
	lives -= amount
	update_ui()
	if lives <= 0:
		game_over()

func add_gold(amount):
	gold += amount
	update_ui()

func game_over():
	print("Game Over!")
	# Add game over UI logic here
