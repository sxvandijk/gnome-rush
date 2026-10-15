extends Node3D
## Placeholder scene for the first IPA: a lawn, a small crowd of bobbing
## gnome cones, a light, a camera and a title. Replaced by the real runner
## scene later in M1.

const GNOME_COUNT := 12

var _gnomes: Array[Node3D] = []
var _time := 0.0


func _ready() -> void:
	_add_environment()
	_add_lawn()
	_add_gnomes()
	_add_camera()
	_add_title()


func _process(delta: float) -> void:
	_time += delta
	for i in _gnomes.size():
		var gnome := _gnomes[i]
		gnome.position.y = 0.5 + absf(sin(_time * 6.0 + i * 0.7)) * 0.25


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.8, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 0.9)
	env.ambient_light_energy = 0.6
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)


func _add_lawn() -> void:
	var lawn := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8, 40)
	lawn.mesh = plane
	lawn.material_override = _material(Color(0.35, 0.7, 0.3))
	lawn.position.z = -15
	add_child(lawn)


func _add_gnomes() -> void:
	var body_mat := _material(Color(0.2, 0.35, 0.8))
	var hat_mat := _material(Color(0.85, 0.15, 0.15))
	for i in GNOME_COUNT:
		var gnome := Node3D.new()
		var col := i % 4
		var row := i / 4
		gnome.position = Vector3((col - 1.5) * 0.9, 0.5, -row * 0.9)

		var body := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.3
		cyl.height = 0.6
		body.mesh = cyl
		body.material_override = body_mat
		gnome.add_child(body)

		var hat := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.3
		cone.height = 0.6
		hat.mesh = cone
		hat.material_override = hat_mat
		hat.position.y = 0.6
		gnome.add_child(hat)

		add_child(gnome)
		_gnomes.append(gnome)


func _add_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 5, 6)
	cam.rotation_degrees = Vector3(-35, 0, 0)
	cam.fov = 60
	add_child(cam)


func _add_title() -> void:
	var layer := CanvasLayer.new()
	var label := Label.new()
	label.text = "Gnome Rush\nM1"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 96)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.2, 0.1))
	label.add_theme_constant_override("outline_size", 16)
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 200
	layer.add_child(label)
	add_child(layer)


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat
