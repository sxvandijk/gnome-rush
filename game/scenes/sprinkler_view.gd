class_name SprinklerView
extends Node3D
## Placeholder garden sprinkler at the lane edge; its jet sweeps across the
## lane and shows which way (and how hard) it pushes right now.

const WATER := Color(0.45, 0.75, 1.0, 0.45)

var sprinkler: Sprinkler
var _jet: MeshInstance3D
var _lane_half_width := 6.0


func setup(p_sprinkler: Sprinkler, lane_half_width: float) -> void:
	sprinkler = p_sprinkler
	_lane_half_width = lane_half_width
	position.z = -sprinkler.z
	for side in [-1.0, 1.0]:
		var x: float = side * (lane_half_width + 0.9)
		Visuals.box(self, Vector3(0.25, 0.8, 0.25), Color(0.3, 0.3, 0.32), Vector3(x, 0.4, 0))
		Visuals.sphere(self, 0.22, Color(0.85, 0.75, 0.2), Vector3(x, 0.9, 0))
	# A sheet of water across the lane; its tilt and opacity show the push
	_jet = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(lane_half_width * 2.0, 0.05, Sprinkler.HALF_DEPTH * 2.0)
	_jet.mesh = box
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = WATER
	_jet.material_override = mat
	_jet.position.y = 0.6
	add_child(_jet)

	var arrow := Label3D.new()
	arrow.name = "Arrow"
	arrow.font_size = 140
	arrow.pixel_size = 0.006
	arrow.outline_size = 30
	arrow.modulate = Color(0.85, 0.95, 1.0)
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.position.y = 1.6
	add_child(arrow)


func update_view(time: float) -> void:
	var push := sprinkler.push_at(time)
	var strength := absf(push) / maxf(sprinkler.push, 0.01)
	_jet.rotation.z = -push * 0.04
	var mat: StandardMaterial3D = _jet.material_override
	mat.albedo_color.a = 0.15 + 0.4 * strength
	var arrow: Label3D = get_node("Arrow")
	arrow.text = "»" if push > 0.0 else "«"
	arrow.position.x = signf(push) * _lane_half_width * 0.4
	arrow.modulate.a = strength
