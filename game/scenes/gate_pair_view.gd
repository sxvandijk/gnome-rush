class_name GatePairView
extends Node3D
## Two translucent gate panels with their value; green grows the army,
## red shrinks it. Call refresh() when a gate value changes and
## update_view() every frame (the split slides in chapter 3).

const HEIGHT := 2.4
const GAP := 0.15
const GREEN := Color(0.2, 0.85, 0.35, 0.45)
const RED := Color(0.95, 0.2, 0.2, 0.45)

var pair: GatePair
var _w := 6.0
var _panels := {}  # Gate -> MeshInstance3D
var _labels := {}  # Gate -> Label3D
var _middle_post: MeshInstance3D


func setup(p_pair: GatePair, lane_half_width: float) -> void:
	pair = p_pair
	_w = lane_half_width
	position.z = -pair.z
	_add_side(pair.left)
	_add_side(pair.right)
	_add_post(-_w)
	_add_post(_w)
	_middle_post = _add_post(0.0)
	if pair.shift_amp > 0.0:
		_middle_post.material_override = Visuals.material(Color(1.0, 0.8, 0.2))  # Mark sliding gates
	refresh()
	update_view(0.0)


func update_view(time: float) -> void:
	if pair.used:
		return  # Frozen once passed, so the pass animation can play
	var split := pair.split_x(time)
	_place(pair.left, (-_w + split) * 0.5, split + _w - GAP)
	_place(pair.right, (split + _w) * 0.5, _w - split - GAP)
	_middle_post.position.x = split


func refresh() -> void:
	for gate: Gate in _panels:
		var mat: StandardMaterial3D = _panels[gate].material_override
		mat.albedo_color = GREEN if gate.is_positive() else RED
		_labels[gate].text = gate.label()


func mark_passed(chosen: Gate) -> void:
	var tween := create_tween().set_parallel()
	for gate: Gate in _panels:
		var panel: MeshInstance3D = _panels[gate]
		var mat: StandardMaterial3D = panel.material_override
		var label: Label3D = _labels[gate]
		if gate == chosen:
			tween.tween_property(panel, "scale", panel.scale * 1.3, 0.25)
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.25)
			tween.tween_property(label, "modulate:a", 0.0, 0.25)
		else:
			tween.tween_property(mat, "albedo_color:a", 0.15, 0.25)
			tween.tween_property(label, "modulate:a", 0.3, 0.25)


func _place(gate: Gate, x: float, width: float) -> void:
	var panel: MeshInstance3D = _panels[gate]
	panel.position.x = x
	panel.scale.x = maxf(width, 0.01)
	_labels[gate].position.x = x


func _add_side(gate: Gate) -> void:
	var panel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, HEIGHT, 0.1)  # Width comes from scale.x
	panel.mesh = box
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	panel.material_override = mat
	panel.position.y = HEIGHT * 0.5
	add_child(panel)

	var label := Label3D.new()
	label.font_size = 200
	label.outline_size = 40
	label.pixel_size = 0.006
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.position = Vector3(0, HEIGHT * 0.55, 0.1)
	add_child(label)

	_panels[gate] = panel
	_labels[gate] = label


func _add_post(x: float) -> MeshInstance3D:
	return Visuals.box(self, Vector3(0.15, HEIGHT + 0.2, 0.15), Color(0.95, 0.95, 0.9), Vector3(x, (HEIGHT + 0.2) * 0.5, 0))
