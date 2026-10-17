class_name BossView
extends Node3D
## Placeholder bosses, one look per kind, with hit points overhead.

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
	match boss.kind:
		"cat":
			_build_cat(r)
		"magpie":
			_build_magpie(r)
		"sprinkler_robot":
			_build_robot(r)
		"mole_king_xl":
			_build_mole_king(r)
			_body.scale = Vector3.ONE * 1.35
		"flamingo_queen":
			_build_flamingo(r)
		"koi_emperor":
			_build_koi(r)
		_:
			_build_mole_king(r)
	_label = Visuals.count_label(self, r * 2.0 * _body.scale.y + 1.6, 170)
	_label.modulate = Color(1.0, 0.85, 0.3)


func update_view(delta: float, fighting: bool) -> void:
	_time += delta
	_label.text = "♥ %d" % boss.hp_display()
	if boss.is_defeated():
		_body.scale = _body.scale.lerp(Vector3(_body.scale.x, 0.05, _body.scale.z), 1.0 - exp(-6.0 * delta))
		return
	_body.position.x = sin(_time * 40.0) * 0.06 if fighting else 0.0
	_body.position.y = sin(_time * 3.0) * 0.05


func _crown(r: float, y: float) -> void:
	var crown := CylinderMesh.new()
	crown.top_radius = r * 0.55
	crown.bottom_radius = r * 0.45
	crown.height = r * 0.45
	crown.radial_segments = 8
	crown.rings = 1
	Visuals.mesh(_body, crown, Color(1.0, 0.8, 0.15), Vector3(0, y, 0))


func _eyes(r: float, y: float, z: float, spread := 0.35) -> void:
	for side in [-1.0, 1.0]:
		Visuals.sphere(_body, r * 0.1, Color(0.05, 0.05, 0.05), Vector3(side * r * spread, y, z))


func _build_mole_king(r: float) -> void:
	Visuals.sphere(_body, r, Color(0.32, 0.24, 0.2), Vector3(0, r, 0))
	Visuals.sphere(_body, r * 0.25, Color(1.0, 0.55, 0.65), Vector3(0, r * 1.1, r * 0.9))
	_eyes(r, r * 1.4, r * 0.8)
	for side in [-1.0, 1.0]:
		Visuals.sphere(_body, r * 0.3, Color(1.0, 0.7, 0.75), Vector3(side * r * 0.9, r * 0.6, r * 0.6))
	_crown(r, r * 2.05)


func _build_cat(r: float) -> void:
	var fur := Color(0.95, 0.55, 0.15)
	Visuals.sphere(_body, r * 0.9, fur, Vector3(0, r * 0.9, 0))
	Visuals.sphere(_body, r * 0.6, fur, Vector3(0, r * 2.0, r * 0.2))
	for side in [-1.0, 1.0]:
		var ear := CylinderMesh.new()
		ear.top_radius = 0.0
		ear.bottom_radius = r * 0.2
		ear.height = r * 0.4
		Visuals.mesh(_body, ear, fur, Vector3(side * r * 0.35, r * 2.6, r * 0.2))
	_eyes(r, r * 2.1, r * 0.75, 0.25)
	Visuals.box(_body, Vector3(r * 0.2, r * 0.2, r * 1.6), fur.darkened(0.2), Vector3(r * 0.6, r * 0.4, -r * 1.0))


func _build_magpie(r: float) -> void:
	Visuals.sphere(_body, r * 0.85, Color(0.08, 0.08, 0.1), Vector3(0, r * 1.0, 0))
	Visuals.sphere(_body, r * 0.6, Color(0.95, 0.95, 0.95), Vector3(0, r * 0.8, r * 0.4))
	Visuals.sphere(_body, r * 0.5, Color(0.08, 0.08, 0.1), Vector3(0, r * 2.0, r * 0.3))
	Visuals.box(_body, Vector3(r * 0.15, r * 0.15, r * 0.6), Color(0.2, 0.2, 0.2), Vector3(0, r * 2.0, r * 0.95))
	for side in [-1.0, 1.0]:
		Visuals.box(_body, Vector3(r * 0.2, r * 0.9, r * 1.2), Color(0.1, 0.15, 0.35), Vector3(side * r * 0.9, r * 1.0, 0))
	_eyes(r, r * 2.15, r * 0.7, 0.25)


func _build_robot(r: float) -> void:
	var metal := Color(0.6, 0.62, 0.66)
	Visuals.box(_body, Vector3(r * 1.6, r * 1.4, r * 1.2), metal, Vector3(0, r * 0.9, 0))
	Visuals.box(_body, Vector3(r * 1.0, r * 0.7, r * 0.9), metal.lightened(0.2), Vector3(0, r * 2.0, 0))
	Visuals.box(_body, Vector3(r * 0.8, r * 0.15, r * 0.1), Color(0.3, 0.8, 1.0), Vector3(0, r * 2.05, r * 0.46))
	for side in [-1.0, 1.0]:
		Visuals.box(_body, Vector3(r * 0.25, r * 0.25, r * 1.0), Color(0.3, 0.55, 0.9), Vector3(side * r * 1.0, r * 1.3, r * 0.4))


func _build_flamingo(r: float) -> void:
	var pink := Color(1.0, 0.5, 0.65)
	Visuals.sphere(_body, r * 0.8, pink, Vector3(0, r * 1.6, 0))
	Visuals.box(_body, Vector3(r * 0.15, r * 1.6, r * 0.15), pink.darkened(0.1), Vector3(0, r * 0.7, 0))
	Visuals.box(_body, Vector3(r * 0.15, r * 1.2, r * 0.15), pink, Vector3(0, r * 2.6, r * 0.3))
	Visuals.sphere(_body, r * 0.3, pink, Vector3(0, r * 3.2, r * 0.35))
	Visuals.box(_body, Vector3(r * 0.1, r * 0.1, r * 0.4), Color(0.1, 0.1, 0.1), Vector3(0, r * 3.1, r * 0.7))
	_crown(r * 0.5, r * 3.55)


func _build_koi(r: float) -> void:
	Visuals.sphere(_body, r, Color(1.0, 0.95, 0.9), Vector3(0, r * 1.0, 0))
	Visuals.sphere(_body, r * 0.55, Color(1.0, 0.45, 0.1), Vector3(r * 0.4, r * 1.5, r * 0.3))
	Visuals.sphere(_body, r * 0.45, Color(1.0, 0.45, 0.1), Vector3(-r * 0.5, r * 0.8, -r * 0.3))
	Visuals.box(_body, Vector3(r * 0.1, r * 1.0, r * 0.8), Color(1.0, 0.6, 0.3), Vector3(0, r * 1.0, -r * 1.2))
	_eyes(r, r * 1.3, r * 0.9, 0.4)
	_crown(r, r * 2.05)
