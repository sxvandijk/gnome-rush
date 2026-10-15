class_name AcornView
extends Node3D
## Draws all flying acorns with one MultiMesh.

const HEIGHT := 0.6

var _acorns: MultiMeshInstance3D


func _ready() -> void:
	var m := SphereMesh.new()
	m.radius = 0.09
	m.height = 0.22
	m.radial_segments = 6
	m.rings = 3
	_acorns = Visuals.multimesh(self, m, Color(0.55, 0.33, 0.12), RunState.MAX_ACORNS)


func update_view(acorns: PackedVector2Array) -> void:
	var n := mini(acorns.size(), RunState.MAX_ACORNS)
	for i in n:
		var a := acorns[i]
		_acorns.multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(a.x, HEIGHT, -a.y)))
	_acorns.multimesh.visible_instance_count = n
