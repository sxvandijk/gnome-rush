class_name ArmyView
extends Node3D
## Draws the army with two MultiMeshes (bodies and hats). Gnomes glide
## towards their formation spot, so growing and shrinking looks smooth.

const FORMATION_RATE := 8.0
const HOP_HEIGHT := 0.1
const HOP_SPEED := 12.0
const BODY_HEIGHT := 0.5
const HAT_HEIGHT := 0.4

var _bodies: MultiMeshInstance3D
var _hats: MultiMeshInstance3D
var _label: Label3D
var _offsets := PackedVector2Array()
var _targets := PackedVector2Array()
var _time := 0.0


func _ready() -> void:
	_bodies = Visuals.multimesh(self, _cone(0.11, 0.15, BODY_HEIGHT), Color(0.2, 0.35, 0.85), Army.MAX_VISIBLE)
	_hats = Visuals.multimesh(self, _cone(0.0, 0.15, HAT_HEIGHT), Color(0.9, 0.15, 0.15), Army.MAX_VISIBLE)
	_label = Visuals.count_label(self, 1.7)


## x is the army centre from the logic (already smoothed); d its distance.
func update_view(count: int, x: float, d: float, delta: float) -> void:
	_time += delta
	position = Vector3(x, 0, -d)

	var n := mini(count, Army.MAX_VISIBLE)
	if n != _targets.size():
		_targets = Army.formation(n)
		var old := _offsets.size()
		_offsets.resize(n)
		for i in range(old, n):
			_offsets[i] = Vector2.ZERO  # New gnomes pop out of the middle

	var k := 1.0 - exp(-FORMATION_RATE * delta)
	for i in n:
		_offsets[i] = _offsets[i].lerp(_targets[i], k)
		var hop := absf(sin(_time * HOP_SPEED + i * 1.7)) * HOP_HEIGHT
		var base := Vector3(_offsets[i].x, hop, -_offsets[i].y)
		_bodies.multimesh.set_instance_transform(i, Transform3D(Basis(), base + Vector3(0, BODY_HEIGHT * 0.5, 0)))
		_hats.multimesh.set_instance_transform(i, Transform3D(Basis(), base + Vector3(0, BODY_HEIGHT + HAT_HEIGHT * 0.5, 0)))
	_bodies.multimesh.visible_instance_count = n
	_hats.multimesh.visible_instance_count = n

	_label.text = str(count)
	_label.visible = count > 0


func _cone(top: float, bottom: float, height: float) -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = 8
	m.rings = 1
	return m
