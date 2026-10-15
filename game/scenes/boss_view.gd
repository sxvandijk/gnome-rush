class_name BossView
extends Node3D
## Placeholder mole king: a big mole with a golden crown and hit points.

var boss: Boss
var _body: Node3D
var _label: Label3D
var _time := 0.0


func setup(p_boss: Boss) -> void:
	boss = p_boss
	position.z = -boss.z
	_body = Node3D.new()
	add_child(_body)
	var r := Boss.RADIUS
	Visuals.sphere(_body, r, Color(0.32, 0.24, 0.2), Vector3(0, r, 0))
	Visuals.sphere(_body, r * 0.25, Color(1.0, 0.55, 0.65), Vector3(0, r * 1.1, r * 0.9))
	for side in [-1.0, 1.0]:
		Visuals.sphere(_body, r * 0.1, Color(0.05, 0.05, 0.05), Vector3(side * r * 0.35, r * 1.4, r * 0.8))
		Visuals.sphere(_body, r * 0.3, Color(1.0, 0.7, 0.75), Vector3(side * r * 0.9, r * 0.6, r * 0.6))
	var crown := CylinderMesh.new()
	crown.top_radius = r * 0.55
	crown.bottom_radius = r * 0.45
	crown.height = r * 0.45
	crown.radial_segments = 8
	crown.rings = 1
	Visuals.mesh(_body, crown, Color(1.0, 0.8, 0.15), Vector3(0, r * 2.05, 0))
	_label = Visuals.count_label(self, r * 2.0 + 1.6, 170)
	_label.modulate = Color(1.0, 0.85, 0.3)


func update_view(delta: float, fighting: bool) -> void:
	_time += delta
	_label.text = "♥ %d" % boss.hp_display()
	if boss.is_defeated():
		_body.scale = _body.scale.lerp(Vector3(1, 0.05, 1), 1.0 - exp(-6.0 * delta))
		return
	var shake := sin(_time * 40.0) * 0.06 if fighting else 0.0
	_body.position.x = shake
	_body.scale = Vector3.ONE * (1.0 + sin(_time * 3.0) * 0.03)
