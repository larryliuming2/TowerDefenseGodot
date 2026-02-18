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

func _on_summon_pressed():
	if gold >= 50:
		gold -= 50
		update_ui()
		# For now, we'll place at a random spot or follow mouse in next step
		spawn_tower(get_global_mouse_position())

func spawn_tower(pos):
	var tower = load("res://scenes/SwordGirl.tscn").instantiate()
	tower.position = pos
	add_child(tower)
	# Add the cherry blossom effect!
	var effect = load("res://scenes/SummonEffect.tscn").instantiate()
	effect.position = pos
	add_child(effect)

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
