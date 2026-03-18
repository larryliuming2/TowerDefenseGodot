extends Node2D

# --- Game State ---
var gold = 200
var lives = 20
var wave = 1
var current_wave_health = 50
var is_fast_forward = false

# --- Tower Placement State ---
var is_placing_tower = false
var ghost_tower: Node2D = null
var current_tower_type = ""
var current_tower_cost = 0
var placement_origin = Vector2.ZERO

# --- Nodes & Resources ---
@onready var ui_gold = $CanvasLayer/HUD/GoldLabel
@onready var ui_lives = $CanvasLayer/HUD/LivesLabel
@onready var spawner_timer = $SpawnerTimer
@onready var canvas_layer = $CanvasLayer

var enemy_scene = preload("res://scenes/Enemy.tscn")
var summon_effect_scene = preload("res://scenes/SummonEffect.tscn")

var tower_scenes = {
	"Archer": preload("res://scenes/Archer.tscn"),
	"Magic": preload("res://scenes/Magic.tscn"),
	"Boom": preload("res://scenes/Boom.tscn"),
	"Sword": preload("res://scenes/SwordGirl.tscn")
}

var selection_menu: Control = null

func _ready():
	update_ui()
	spawner_timer.timeout.connect(_on_spawner_timeout)
	$CanvasLayer/HUD/SpeedButton.pressed.connect(_on_speed_button_pressed)
	_build_selection_menu()

func _build_selection_menu():
	selection_menu = Control.new()
	selection_menu.name = "SelectionMenu"
	selection_menu.z_index = 2000
	selection_menu.visible = false
	selection_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg = ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.1, 0.1, 0.15, 0.92)
	bg.size = Vector2(180, 220)
	bg.position = Vector2(-90, -110)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	selection_menu.add_child(bg)

	var title = Label.new()
	title.text = "Build Tower"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(-85, -105)
	title.size = Vector2(170, 30)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_menu.add_child(title)

	var tower_data = [
		{"name": "Sword", "label": "Sword (50g)", "cost": 50},
		{"name": "Archer", "label": "Archer (75g)", "cost": 75},
		{"name": "Magic", "label": "Magic (100g)", "cost": 100},
		{"name": "Boom", "label": "Boom (150g)", "cost": 150},
	]

	var y_offset = -70
	for data in tower_data:
		var btn = Button.new()
		btn.text = data["label"]
		btn.position = Vector2(-80, y_offset)
		btn.size = Vector2(160, 35)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		var tower_type = data["name"]
		var tower_cost = data["cost"]
		btn.pressed.connect(_on_tower_selected.bind(tower_type, tower_cost))
		selection_menu.add_child(btn)
		y_offset += 40

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.position = Vector2(-80, y_offset)
	cancel_btn.size = Vector2(160, 35)
	cancel_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	cancel_btn.pressed.connect(func(): selection_menu.hide())
	selection_menu.add_child(cancel_btn)

	canvas_layer.add_child(selection_menu)

func _on_tower_selected(type, cost):
	if gold < cost:
		selection_menu.hide()
		return
	start_placing(type, cost)

func _process(_delta):
	if is_placing_tower and ghost_tower:
		ghost_tower.global_position = get_global_mouse_position()

func _input(event):
	var is_click = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	var is_touch = (event is InputEventScreenTouch and event.pressed)
	var is_right_click = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed)
	var is_escape = (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed)

	# --- State 1: Currently placing a tower ---
	if is_placing_tower:
		if is_click or is_touch:
			confirm_placement()
			get_viewport().set_input_as_handled()
		elif is_right_click or is_escape:
			cancel_placement()
			get_viewport().set_input_as_handled()
		return

	# --- State 2: Menu is open ---
	if selection_menu.visible:
		if is_right_click or is_escape:
			selection_menu.hide()
			get_viewport().set_input_as_handled()
		return

	# --- State 3: Click map to open build menu ---
	if is_click or is_touch:
		placement_origin = get_global_mouse_position()
		selection_menu.global_position = get_viewport().get_mouse_position()
		selection_menu.show()
		get_viewport().set_input_as_handled()

func _on_speed_button_pressed():
	is_fast_forward = !is_fast_forward
	Engine.time_scale = 2.0 if is_fast_forward else 1.0
	$CanvasLayer/HUD/SpeedButton.text = "2x" if is_fast_forward else "1x"

# --- Placement Logic ---
func start_placing(type, cost):
	if ghost_tower:
		ghost_tower.queue_free()

	current_tower_type = type
	current_tower_cost = cost
	selection_menu.hide()
	is_placing_tower = true

	if tower_scenes.has(type):
		ghost_tower = tower_scenes[type].instantiate()
		ghost_tower.modulate = Color(1, 1, 1, 0.5)
		if ghost_tower.has_node("RangeArea"):
			ghost_tower.get_node("RangeArea").monitorable = false
			ghost_tower.get_node("RangeArea").monitoring = false
		ghost_tower.set_process(false)
		add_child(ghost_tower)
		ghost_tower.global_position = placement_origin
	else:
		is_placing_tower = false

func confirm_placement():
	if not ghost_tower:
		return

	gold -= current_tower_cost
	update_ui()

	ghost_tower.modulate = Color(1, 1, 1, 1.0)
	if ghost_tower.has_node("RangeArea"):
		ghost_tower.get_node("RangeArea").monitorable = true
		ghost_tower.get_node("RangeArea").monitoring = true
	ghost_tower.set_process(true)

	var effect = summon_effect_scene.instantiate()
	effect.global_position = ghost_tower.global_position
	add_child(effect)

	is_placing_tower = false
	ghost_tower = null

func cancel_placement():
	is_placing_tower = false
	if ghost_tower:
		ghost_tower.queue_free()
		ghost_tower = null

# --- Game Logic ---
func _on_spawner_timeout():
	spawn_enemy()

func spawn_enemy():
	if not has_node("Path2D"):
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
	get_tree().paused = true
