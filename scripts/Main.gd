extends Node2D

const VERSION = "v0.3.0-20260318"

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
var menu_base_texture = preload("res://assets/sprites/defenders/menu_base.png")

func _ready():
	update_ui()
	spawner_timer.timeout.connect(_on_spawner_timeout)
	$CanvasLayer/HUD/SpeedButton.pressed.connect(_on_speed_button_pressed)
	_build_selection_menu()
	_add_version_label()

func _add_version_label():
	var ver_label = Label.new()
	ver_label.text = VERSION
	ver_label.add_theme_font_size_override("font_size", 12)
	ver_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	ver_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	ver_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	ver_label.anchor_left = 1.0
	ver_label.anchor_top = 1.0
	ver_label.anchor_right = 1.0
	ver_label.anchor_bottom = 1.0
	ver_label.offset_left = -120
	ver_label.offset_top = -25
	ver_label.offset_right = -5
	ver_label.offset_bottom = -5
	ver_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(ver_label)

func _build_selection_menu():
	# Menu size: scale 410x410 image down to 200x200
	var menu_size = 200.0
	var half = menu_size / 2.0

	selection_menu = Control.new()
	selection_menu.name = "SelectionMenu"
	selection_menu.z_index = 2000
	selection_menu.visible = false
	selection_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Background image (cross shape)
	var bg = TextureRect.new()
	bg.texture = menu_base_texture
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(menu_size, menu_size)
	bg.position = Vector2(-half, -half)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	selection_menu.add_child(bg)

	# Tower buttons positioned on each arm of the cross
	# Top: Archer (75g)
	_add_menu_button("Archer", 75, Vector2(-35, -half), Vector2(70, 55))
	# Bottom: Sword (50g)
	_add_menu_button("Sword", 50, Vector2(-35, half - 55), Vector2(70, 55))
	# Left: Magic (100g)
	_add_menu_button("Magic", 100, Vector2(-half, -35), Vector2(55, 70))
	# Right: Boom (150g)
	_add_menu_button("Boom", 150, Vector2(half - 55, -35), Vector2(55, 70))

	canvas_layer.add_child(selection_menu)

func _add_menu_button(tower_type: String, cost: int, pos: Vector2, btn_size: Vector2):
	var btn = Button.new()
	btn.position = pos
	btn.size = btn_size
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0)  # Fully transparent button
	btn.pressed.connect(_on_tower_selected.bind(tower_type, cost))
	selection_menu.add_child(btn)

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
