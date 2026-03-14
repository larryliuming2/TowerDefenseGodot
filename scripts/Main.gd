extends Node2D

# --- Game State ---
var gold = 100
var lives = 20
var wave = 1
var current_wave_health = 50
var is_fast_forward = false

# --- Tower Placement State ---
var is_placing_tower = false
var ghost_tower: Node2D = null
var current_tower_type = ""
var current_tower_cost = 0

# --- Nodes & Resources ---
@onready var ui_gold = $CanvasLayer/HUD/GoldLabel
@onready var ui_lives = $CanvasLayer/HUD/LivesLabel
@onready var spawner_timer = $SpawnerTimer
@onready var selection_menu = preload("res://scenes/SelectionMenu.tscn").instantiate()

var enemy_scene = preload("res://scenes/Enemy.tscn")
var summon_effect_scene = preload("res://scenes/SummonEffect.tscn")

# Tower scenes dictionary for easier lookup
var tower_scenes = {
	"Archer": preload("res://scenes/Archer.tscn"),
	"Magic": preload("res://scenes/Magic.tscn"),
	"Boom": preload("res://scenes/Boom.tscn"),
	"Sword": preload("res://scenes/SwordGirl.tscn")
}

func _ready():
	update_ui()
	
	# Connect Timers & Buttons
	spawner_timer.timeout.connect(_on_spawner_timeout)
	$CanvasLayer/HUD/SpeedButton.pressed.connect(_on_speed_button_pressed)
	$CanvasLayer/HUD/SummonButton.pressed.connect(_on_summon_pressed)
	
	# Setup selection menu
	add_child(selection_menu)
	selection_menu.hide()
	selection_menu.z_index = 1000
	selection_menu.top_level = true
	
	# Connect menu buttons using a helper to avoid duplication
	_setup_menu_button("ArcherButton", "Archer", 75)
	_setup_menu_button("MagicButton", "Magic", 100)
	_setup_menu_button("BoomButton", "Boom", 150)
	_setup_menu_button("SwordGirlButton", "Sword", 50)
	
	var cancel_btn = selection_menu.get_node_or_null("VBoxContainer/CancelButton")
	if cancel_btn:
		cancel_btn.pressed.connect(func(): selection_menu.hide())
	
	print("Tower Defense Game Initialized!")

func _setup_menu_button(node_name, type, cost):
	var btn = selection_menu.get_node_or_null("VBoxContainer/" + node_name)
	if btn:
		btn.pressed.connect(func(): start_placing(type, cost))

func _process(_delta):
	if is_placing_tower and ghost_tower:
		# Smooth follow mouse/touch
		var target_pos = get_global_mouse_position()
		# Optional: Add grid snapping here if desired (e.g., target_pos = target_pos.snapped(Vector2(32, 32)))
		ghost_tower.global_position = target_pos

func _unhandled_input(event):
	# Using _unhandled_input prevents placement when clicking on UI elements
	if not is_placing_tower:
		return
	
	# Confirm Placement (Left Click or Touch Start)
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or \
	   (event is InputEventScreenTouch and event.pressed):
		confirm_placement()
		# Mark input as handled so it doesn't propagate
		get_viewport().set_input_as_handled()
		
	# Cancel Placement (Right Click or Escape)
	elif (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed) or \
		 (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		cancel_placement()
		get_viewport().set_input_as_handled()

# --- UI Handlers ---
func _on_speed_button_pressed():
	is_fast_forward = !is_fast_forward
	Engine.time_scale = 2.0 if is_fast_forward else 1.0
	$CanvasLayer/HUD/SpeedButton.text = "Speed: 2x" if is_fast_forward else "Speed: 1x"

func _on_summon_pressed():
	if is_placing_tower:
		cancel_placement()
	
	# Toggle menu visibility
	if selection_menu.visible:
		selection_menu.hide()
	else:
		# Position menu near the button or center
		var mouse_pos = get_global_mouse_position()
		selection_menu.global_position = mouse_pos - Vector2(100, 100)
		selection_menu.show()
		print("Menu opened at: ", selection_menu.global_position)

# --- Placement Logic ---
func start_placing(type, cost):
	print("Attempting to place: ", type, " (Cost: ", cost, ")")
	
	if gold < cost:
		print("Insufficient funds! Gold: ", gold)
		selection_menu.hide()
		return
		
	# Clean up previous ghost if exists
	if ghost_tower:
		ghost_tower.queue_free()
		
	current_tower_type = type
	current_tower_cost = cost
	selection_menu.hide()
	is_placing_tower = true
	
	# Instantiate ghost
	if tower_scenes.has(type):
		ghost_tower = tower_scenes[type].instantiate()
		ghost_tower.modulate = Color(1, 1, 1, 0.5) # Semi-transparent
		# Disable collision/processing on ghost if needed
		if ghost_tower.has_node("Area2D"):
			ghost_tower.get_node("Area2D").monitorable = false
			ghost_tower.get_node("Area2D").monitoring = false
		
		add_child(ghost_tower)
		ghost_tower.global_position = get_global_mouse_position()
	else:
		print("Error: Tower scene not found for ", type)
		is_placing_tower = false

func confirm_placement():
	if not ghost_tower: return
	
	print("Confirming placement of ", current_tower_type)
	
	# Deduct gold
	gold -= current_tower_cost
	update_ui()
	
	# Finalize tower
	ghost_tower.modulate = Color(1, 1, 1, 1.0)
	if ghost_tower.has_node("Area2D"):
		ghost_tower.get_node("Area2D").monitorable = true
		ghost_tower.get_node("Area2D").monitoring = true
	
	# Visual feedback
	var effect = summon_effect_scene.instantiate()
	effect.global_position = ghost_tower.global_position
	add_child(effect)
	
	# Reset state
	is_placing_tower = false
	ghost_tower = null
	print("Tower deployed. Remaining gold: ", gold)

func cancel_placement():
	print("Placement cancelled.")
	is_placing_tower = false
	if ghost_tower:
		ghost_tower.queue_free()
		ghost_tower = null

# --- Game Logic ---
func _on_spawner_timeout():
	spawn_enemy()

func spawn_enemy():
	if not has_node("Path2D"):
		print("Error: Path2D not found in Main scene!")
		return
		
	var enemy = enemy_scene.instantiate()
	enemy.health = current_wave_health
	$Path2D.add_child(enemy)
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
	# Engine.paused = true # Optional: Pause the game
