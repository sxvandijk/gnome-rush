extends Node3D
## Runner scene: builds the lawn, gates, obstacles, boss, army, camera and
## HUD for one run (level, daily challenge or endless) and drives them from a
## RunState. All rules live in game/logic; this script shows them, feeds in
## the steering and applies the player's upgrades and skin.

## Lane units the army target moves for a drag across the full screen width.
const DRAG_UNITS_PER_SCREEN := 13.0
const CAMERA_X_FOLLOW := 0.35
const CAMERA_HEIGHT := 8.6
const CAMERA_BACK := 10.5
const CAMERA_LOOK_AHEAD := 9.0
const HEDGE_X := 6.65
## Per chapter: [lawn, lane, hedge, surroundings]
const THEMES := [
	[Color(0.3, 0.6, 0.25), Color(0.45, 0.75, 0.35), Color(0.2, 0.45, 0.2), Color(0.55, 0.8, 1.0)],
	[Color(0.45, 0.32, 0.2), Color(0.5, 0.7, 0.3), Color(0.35, 0.55, 0.15), Color(0.65, 0.82, 0.95)],
	[Color(0.2, 0.45, 0.6), Color(0.45, 0.72, 0.5), Color(0.25, 0.5, 0.35), Color(0.6, 0.85, 0.95)],
]

var _level: LevelData
var _run: RunState
var _army_view: ArmyView
var _acorn_view: AcornView
var _gate_views := {}  # GatePair -> GatePairView
var _mole_views: Array[MoleGroupView] = []
var _mower_views: Array[MowerView] = []
var _sprinkler_views: Array[SprinklerView] = []
var _boss_view: BossView
var _camera: Camera3D
var _hud: Hud
var _result_shown := false
## Development: `-- --autopilot` lets the validator's pilot play the level.
var _autopilot: LevelValidator.Plan = null


func _ready() -> void:
	_hud = Hud.new()
	add_child(_hud)
	_hud.retry_pressed.connect(func() -> void: get_tree().reload_current_scene())
	_hud.next_pressed.connect(Game.play_next)
	_hud.map_pressed.connect(Game.show_map)
	_hud.set_title(Game.run_title())

	_level = Game.level_for_run()
	if _level == null:
		set_process(false)
		_hud.show_message("%s kon niet geladen worden" % Game.run_title())
		return
	_run = RunState.new(_level)
	var progress := Game.progress
	_run.fire_rate = progress.fire_rate()
	_run.acorn_boss_damage = progress.boss_damage()
	_run.army.add(progress.start_bonus())
	if "--autopilot" in OS.get_cmdline_user_args():
		_autopilot = LevelValidator.make_plan(_level)
	_run.pair_passed.connect(func(pair: GatePair, gate: Gate) -> void: _gate_views[pair].mark_passed(gate))
	_run.gate_hit.connect(func(pair: GatePair, _gate: Gate) -> void: _gate_views[pair].refresh())

	_add_environment()
	_add_track()
	for pair in _run.pairs:
		var view := GatePairView.new()
		add_child(view)
		view.setup(pair, _level.lane_half_width)
		_gate_views[pair] = view
	for group in _run.moles:
		var view := MoleGroupView.new()
		add_child(view)
		view.setup(group)
		_mole_views.append(view)
	for mower in _run.mowers:
		var view := MowerView.new()
		add_child(view)
		view.setup(mower)
		_mower_views.append(view)
	for sprinkler in _run.sprinklers:
		var view := SprinklerView.new()
		add_child(view)
		view.setup(sprinkler, _level.lane_half_width)
		_sprinkler_views.append(view)
	if _run.boss:
		_boss_view = BossView.new()
		add_child(_boss_view)
		_boss_view.setup(_run.boss)

	_army_view = ArmyView.new()
	_army_view.skin = Skins.get_skin(progress.skin)
	add_child(_army_view)
	_acorn_view = AcornView.new()
	add_child(_acorn_view)

	_camera = Camera3D.new()
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.fov = 64
	add_child(_camera)
	_update_views(0.0)


func _unhandled_input(event: InputEvent) -> void:
	if _run == null or _run.is_finished():
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
	_run.set_target_x(_run.target_x + dx / screen_w * DRAG_UNITS_PER_SCREEN)


func _process(delta: float) -> void:
	if _autopilot:
		_run.set_target_x(LevelValidator.pilot_target(_run, _autopilot))
	_run.update(delta)
	_update_views(delta)
	if Game.mode == Game.Mode.ENDLESS:
		_hud.set_counter("Rij %d" % _run.rows_passed())
	if _run.is_finished() and not _result_shown:
		_result_shown = true
		var result := Game.finish_run(_run)
		_hud.show_result(result, _run.army.count, Game.mode == Game.Mode.ENDLESS, Game.has_next())


func _update_views(delta: float) -> void:
	_army_view.update_view(_run.army.count, _run.army.center_x, _run.distance, delta)
	_acorn_view.update_view(_run.acorns)
	for view in _mole_views:
		view.update_view(delta, _run.fighting == view.group)
	for view in _mower_views:
		view.update_view(_run.time)
	for view in _sprinkler_views:
		view.update_view(_run.time)
	for pair in _gate_views:
		_gate_views[pair].update_view(_run.time)
	if _boss_view:
		_boss_view.update_view(delta, _run.at_boss)

	var cx := _run.army.center_x * CAMERA_X_FOLLOW
	_camera.position = Vector3(cx, CAMERA_HEIGHT, -_run.distance + CAMERA_BACK)
	_camera.look_at(Vector3(cx, 0, -_run.distance - CAMERA_LOOK_AHEAD))


func _theme() -> Array:
	return THEMES[(maxi(_level.chapter, 1) - 1) % THEMES.size()]


func _end_z() -> float:
	return _run.boss.z if _run.boss else _level.length


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _theme()[3]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 0.9)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = _theme()[3]
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
	var length := _end_z() + 40.0
	var mid_z := -length * 0.5 + 20.0

	var theme := _theme()
	Visuals.box(self, Vector3(80, 0.1, length + 40), theme[0], Vector3(0, -0.1, mid_z))
	Visuals.box(self, Vector3(w * 2.0, 0.1, length), theme[1], Vector3(0, -0.05, mid_z))
	for side in [-1.0, 1.0]:
		Visuals.box(self, Vector3(0.6, 0.7, length), theme[2], Vector3(side * HEDGE_X, 0.35, mid_z))
	if not _run.boss:
		Visuals.box(self, Vector3(w * 2.0, 0.12, 1.0), Color(0.95, 0.95, 0.95), Vector3(0, 0.0, -_level.length))
