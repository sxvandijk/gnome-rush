class_name MoleGroupView
extends Node3D
## A group of moles in the same sunflower layout as the army.

var group: MoleGroup
var _bodies: MultiMeshInstance3D
var _noses: MultiMeshInstance3D
var _label: Label3D
var _shown := -1
var _time := 0.0


func setup(p_group: MoleGroup) -> void:
	group = p_group
	position = Vector3(group.x, 0, -group.z)
	var body := SphereMesh.new()
	body.radius = 0.17
	body.height = 0.4
	body.radial_segments = 8
	body.rings = 4
	var nose := SphereMesh.new()
	nose.radius = 0.05
	nose.height = 0.1
	nose.radial_segments = 6
	nose.rings = 3
	var capacity := mini(group.count, Army.MAX_VISIBLE)
	_bodies = Visuals.multimesh(self, body, Color(0.32, 0.24, 0.2), capacity)
	_noses = Visuals.multimesh(self, nose, Color(1.0, 0.55, 0.65), capacity)
	_label = Visuals.count_label(self, 1.3, 130)
	_label.modulate = Color(1.0, 0.75, 0.6)


func update_view(delta: float, fighting: bool) -> void:
	_time += delta
	var n := mini(group.count, Army.MAX_VISIBLE)
	var points := Army.formation(n)
	for i in n:
		var wobble := absf(sin(_time * (14.0 if fighting else 4.0) + i)) * (0.12 if fighting else 0.04)
		var p := Vector3(points[i].x, 0.18 + wobble, -points[i].y)
		_bodies.multimesh.set_instance_transform(i, Transform3D(Basis(), p))
		_noses.multimesh.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, 0.05, 0.17)))
	_bodies.multimesh.visible_instance_count = n
	_noses.multimesh.visible_instance_count = n
	_label.text = str(group.count)
	visible = group.count > 0
