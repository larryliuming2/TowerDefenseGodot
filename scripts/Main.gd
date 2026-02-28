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
var is_placing_tower = false
var ghost_tower = null
var current_tower_type = ""
var current_tower_cost = 0

@onready var selection_menu = preload("res://scenes/SelectionMenu.tscn").instantiate()

func _ready():
	update_ui()
	spawner_timer.timeout.connect(_on_spawner_timeout)
	$CanvasLayer/HUD/SpeedButton.pressed.connect(_on_speed_button_pressed)
	$CanvasLayer/HUD/SummonButton.pressed.connect(_on_summon_pressed)
	
	# Setup selection menu
	add_child(selection_menu)
	selection_menu.hide()
	selection_menu.get_node("VBoxContainer/ArcherButton").pressed.connect(func(): start_placing("Archer", 75))
	selection_menu.get_node("VBoxContainer/MagicButton").pressed.connect(func(): start_placing("Magic", 100))
	selection_menu.get_node("VBoxContainer/BoomButton").pressed.connect(func(): start_placing("Boom", 150))
	selection_menu.get_node("VBoxContainer/SwordGirlButton").pressed.connect(func(): start_placing("Sword", 50))
	selection_menu.get_node("VBoxContainer/CancelButton").pressed.connect(func(): selection_menu.hide())
	
	print("Tower Defense Game Started!")

func _process(_delta):
	if is_placing_tower and ghost_tower:
		# Only update ghost position on desktop with mouse movement
		# On mobile, we handle position in the touch event directly
		ghost_tower.position = get_global_mouse_position()

func _input(event):
	if not is_placing_tower:
		return
	
	# Handle mouse input (desktop)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			confirm_placement()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_placement()
	
	# Handle touch input (mobile)
	elif event is InputEventScreenTouch:
		if event.pressed:
			# Update ghost tower position to touch location first
			# Convert screen coordinates to world coordinates
			if ghost_tower:
				ghost_tower.position = get_viewport().get_canvas_transform().affine_inverse() * event.position
			confirm_placement()

func _on_speed_button_pressed():
	is_fast_forward = !is_fast_forward
	Engine.time_scale = 2.0 if is_fast_forward else 1.0
	$CanvasLayer/HUD/SpeedButton.text = "Speed: 2x" if is_fast_forward else "Speed: 1x"

func _on_summon_pressed():
	if not is_placing_tower:
		# Center the menu on the mouse
		selection_menu.position = get_global_mouse_position() - Vector2(100, 100)
		selection_menu.show()
		# Bring to front
		selection_menu.z_index = 100

func start_placing(type, cost):
	print("Starting to place: ", type, " Cost: ", cost)
	if gold >= cost:
		current_tower_type = type
		current_tower_cost = cost
		selection_menu.hide()
		is_placing_tower = true
		
		var scene_path = "res://scenes/" + type + ".tscn"
		if type == "Sword": scene_path = "res://scenes/SwordGirl.tscn"
		
		print("Loading scene: ", scene_path)
		var scene = load(scene_path)
		if scene:
			ghost_tower = scene.instantiate()
			ghost_tower.modulate.a = 0.5
			add_child(ghost_tower)
		else:
			print("Error: Could not load scene at ", scene_path)
			is_placing_tower = false
	else:
		print("Not enough gold! Have: ", gold, " Need: ", cost)
		selection_menu.hide()

func confirm_placement():
	gold -= current_tower_cost
	update_ui()
	ghost_tower.modulate.a = 1.0
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
