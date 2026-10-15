class_name GatePairView
extends Node3D
## Two translucent gate panels with their value; green grows the army,
## red shrinks it. Call refresh() when a gate value changes.

const HEIGHT := 2.4
const GREEN := Color(0.2, 0.85, 0.35, 0.45)
const RED := Color(0.95, 0.2, 0.2, 0.45)

var pair: GatePair
var _panels := {}  # Gate -> MeshInstance3D
var _labels := {}  # Gate -> Label3D


func setup(p_pair: GatePair, lane_half_width: float) -> void:
	pair = p_pair
	position.z = -pair.z
	var w := lane_half_width
	_add_side(pair.left, -w * 0.5, w - 0.15)
	_add_side(pair.right, w * 0.5, w - 0.15)
	_add_post(-w)
	_add_post(0.0)
	_add_post(w)
	refresh()


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
			tween.tween_property(panel, "scale", Vector3(1.3, 1.3, 1.3), 0.25)
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.25)
			tween.tween_property(label, "modulate:a", 0.0, 0.25)
		else:
			tween.tween_property(mat, "albedo_color:a", 0.15, 0.25)
			tween.tween_property(label, "modulate:a", 0.3, 0.25)


func _add_side(gate: Gate, x: float, width: float) -> void:
	var panel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, HEIGHT, 0.1)
	panel.mesh = box
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	panel.material_override = mat
	panel.position = Vector3(x, HEIGHT * 0.5, 0)
	add_child(panel)

	var label := Label3D.new()
	label.font_size = 200
	label.outline_size = 40
	label.pixel_size = 0.006
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.position = Vector3(x, HEIGHT * 0.55, 0.1)
	add_child(label)

	_panels[gate] = panel
	_labels[gate] = label


func _add_post(x: float) -> void:
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.15, HEIGHT + 0.2, 0.15)
	post.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.9)
	post.material_override = mat
	post.position = Vector3(x, (HEIGHT + 0.2) * 0.5, 0)
	add_child(post)
