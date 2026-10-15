class_name ArmyView
extends Node3D
## Draws the army with two MultiMeshes (bodies and hats). Gnomes glide
## towards their formation spot, so growing and shrinking looks smooth.

const MAX_VISIBLE := 400
const FOLLOW_X_RATE := 18.0
const FORMATION_RATE := 8.0
const HOP_HEIGHT := 0.12
const HOP_SPEED := 12.0

var _bodies: MultiMeshInstance3D
var _hats: MultiMeshInstance3D
var _label: Label3D
var _max_radius := 2.7
var _offsets := PackedVector2Array()
var _targets := PackedVector2Array()
var _time := 0.0


func setup(lane_half_width: float) -> void:
	_max_radius = lane_half_width * 0.9
	_bodies = _make_multimesh(_body_mesh(), Color(0.2, 0.35, 0.85))
	_hats = _make_multimesh(_hat_mesh(), Color(0.9, 0.15, 0.15))

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 160
	_label.outline_size = 36
	_label.pixel_size = 0.006
	_label.modulate = Color.WHITE
	_label.outline_modulate = Color(0.1, 0.2, 0.1)
	_label.position = Vector3(0, 1.6, 0)
	add_child(_label)


func update_view(count: int, center_x: float, delta: float) -> void:
	_time += delta
	position.x = lerpf(position.x, center_x, 1.0 - exp(-FOLLOW_X_RATE * delta))

	var n := mini(count, MAX_VISIBLE)
	if n != _targets.size():
		_targets = Army.formation(n, Army.fitted_spacing(n, _max_radius))
		var old := _offsets.size()
		_offsets.resize(n)
		for i in range(old, n):
			_offsets[i] = Vector2.ZERO  # New gnomes pop out of the middle

	var k := 1.0 - exp(-FORMATION_RATE * delta)
	for i in n:
		_offsets[i] = _offsets[i].lerp(_targets[i], k)
		var hop := absf(sin(_time * HOP_SPEED + i * 1.7)) * HOP_HEIGHT
		var base := Vector3(_offsets[i].x, hop, _offsets[i].y)
		_bodies.multimesh.set_instance_transform(i, Transform3D(Basis(), base + Vector3(0, 0.2, 0)))
		_hats.multimesh.set_instance_transform(i, Transform3D(Basis(), base + Vector3(0, 0.6, 0)))
	_bodies.multimesh.visible_instance_count = n
	_hats.multimesh.visible_instance_count = n

	_label.text = str(count)
	_label.position.z = -Army.formation_radius(n, Army.fitted_spacing(n, _max_radius)) * 0.3


func _make_multimesh(mesh: Mesh, color: Color) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = MAX_VISIBLE
	mm.visible_instance_count = 0
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	inst.material_override = mat
	add_child(inst)
	return inst


func _body_mesh() -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.15
	m.bottom_radius = 0.2
	m.height = 0.4
	m.radial_segments = 10
	m.rings = 1
	return m


func _hat_mesh() -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = 0.2
	m.height = 0.4
	m.radial_segments = 10
	m.rings = 1
	return m
