class_name MowerView
extends Node3D
## Placeholder lawnmower: red deck, spinning blade, handle.

var mower: Mower
var _blade: MeshInstance3D


func setup(p_mower: Mower) -> void:
	mower = p_mower
	position.z = -mower.z
	var w := Mower.HALF_WIDTH * 2.0
	var d := Mower.HALF_DEPTH * 2.0
	Visuals.box(self, Vector3(w, 0.35, d), Color(0.85, 0.12, 0.1), Vector3(0, 0.35, 0))
	_blade = Visuals.box(self, Vector3(w * 0.95, 0.04, 0.12), Color(0.8, 0.8, 0.85), Vector3(0, 0.12, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Visuals.box(self, Vector3(0.12, 0.3, 0.3), Color(0.1, 0.1, 0.1), Vector3(sx * w * 0.5, 0.15, sz * d * 0.35))
	Visuals.box(self, Vector3(0.08, 0.9, 0.08), Color(0.25, 0.25, 0.25), Vector3(0, 0.9, d * 0.5))


func update_view(time: float) -> void:
	position.x = mower.x_at(time)
	_blade.rotation.y = time * 25.0
