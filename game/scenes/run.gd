extends Node3D
## Runner scene: builds the lawn, gates, army, camera and HUD for one level
## and drives them from a RunState. All rules live in game/logic.

const LEVEL_PATH := "res://levels/test_001.json"
## How many lane widths one full-screen-width drag moves the army.
const DRAG_LANE_WIDTHS_PER_SCREEN := 1.3
const CAMERA_HEIGHT := 7.0
const CAMERA_BACK := 7.5
const CAMERA_LOOK_AHEAD := 7.0
const CAMERA_RATE := 6.0

var _level: LevelData
var _run: RunState
var _army_view: ArmyView
var _gate_views := {}  # GatePair -> GatePairView
var _camera: Camera3D
var _hud: Hud
var _result_shown := false


func _ready() -> void:
	_level = LevelData.load_json(LEVEL_PATH)
	assert(_level != null, "Could not load %s" % LEVEL_PATH)
	_run = RunState.new(_level)
	_run.pair_passed.connect(_on_pair_passed)

	_add_environment()
	_add_track()
	for pair in _run.pairs:
		var view := GatePairView.new()
		add_child(view)
		view.setup(pair, _level.lane_half_width)
		_gate_views[pair] = view

	_army_view = ArmyView.new()
	add_child(_army_view)
	_army_view.setup(_level.lane_half_width)

	_camera = Camera3D.new()
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.fov = 62
	add_child(_camera)
	_update_camera(1.0)

	_hud = Hud.new()
	add_child(_hud)
	_hud.retry_pressed.connect(func() -> void: get_tree().reload_current_scene())


func _unhandled_input(event: InputEvent) -> void:
	if _run.is_finished():
		return
	var dx := 0.0
	if event is InputEventScreenDrag:
		dx = event.relative.x
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		# Touch also produces emulated mouse events; count each drag once.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		dx = event.relative.x
	else:
		return
	var screen_w := get_viewport().get_visible_rect().size.x
	var lane_w := _level.lane_half_width * 2.0
	_run.army.set_center_x(_run.army.center_x + dx / screen_w * lane_w * DRAG_LANE_WIDTHS_PER_SCREEN)


func _process(delta: float) -> void:
	_run.advance(_level.speed * delta)
	_army_view.position.z = -_run.distance
	_army_view.update_view(_run.army.count, _run.army.center_x, delta)
	_update_camera(1.0 - exp(-CAMERA_RATE * delta))

	if _run.is_finished() and not _result_shown:
		_result_shown = true
		_hud.show_result(_run.is_won(), _run.army.count)


func _on_pair_passed(pair: GatePair, gate: Gate) -> void:
	_gate_views[pair].mark_passed(gate)


func _update_camera(weight: float) -> void:
	var target := _army_view.position
	var x := target.x * 0.6
	var pos := Vector3(x, CAMERA_HEIGHT, target.z + CAMERA_BACK)
	_camera.position = _camera.position.lerp(pos, weight)
	_camera.look_at(Vector3(_camera.position.x, 0, _camera.position.z - CAMERA_BACK - CAMERA_LOOK_AHEAD))


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.8, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 0.9)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.8, 1.0)
	env.fog_density = 0.004
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)


func _add_track() -> void:
	var w := _level.lane_half_width
	var length := _level.length + 40.0
	var mid_z := -_level.length * 0.5

	_add_box(Vector3(60, 0.1, length + 40), Vector3(0, -0.1, mid_z), Color(0.3, 0.6, 0.25))
	_add_box(Vector3(w * 2.0, 0.1, length), Vector3(0, -0.05, mid_z), Color(0.45, 0.75, 0.35))
	# Low hedges along both edges of the lane
	for side in [-1.0, 1.0]:
		_add_box(Vector3(0.4, 0.5, length), Vector3(side * (w + 0.2), 0.25, mid_z), Color(0.2, 0.45, 0.2))
	# Finish line
	_add_box(Vector3(w * 2.0, 0.12, 1.0), Vector3(0, 0.0, -_level.length), Color(0.95, 0.95, 0.95))


func _add_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)
