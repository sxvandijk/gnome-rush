class_name MoleGroupView
extends Node3D
## A group of moles in the same sunflower layout as the army, with an
## optional cage of captive gnomes in the middle. Chasing moles are redder.

const CAGE_SIZE := Vector3(1.1, 1.0, 1.1)

var group: MoleGroup
var _moles: Node3D
var _bodies: MultiMeshInstance3D
var _noses: MultiMeshInstance3D
var _label: Label3D
var _cage: Node3D
var _time := 0.0


func setup(p_group: MoleGroup) -> void:
	group = p_group
	position = Vector3(group.x, 0, -group.z)
	_moles = Node3D.new()
	add_child(_moles)
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
	var fur := Color(0.5, 0.2, 0.15) if group.chase > 0.0 else Color(0.32, 0.24, 0.2)
	_bodies = Visuals.multimesh(_moles, body, fur, capacity)
	_noses = Visuals.multimesh(_moles, nose, Color(1.0, 0.55, 0.65), capacity)
	_label = Visuals.count_label(_moles, 1.3, 130)
	_label.modulate = Color(1.0, 0.75, 0.6)
	if group.cage > 0:
		_add_cage()


func update_view(delta: float, fighting: bool) -> void:
	_time += delta
	position = Vector3(group.x, 0, -group.z)  # Pushed while fighting, sliding when chasing
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
	_moles.visible = group.count > 0
	if _cage:
		_cage.visible = not group.cage_opened
		if group.cage_waiting():
			_cage.position.y = absf(sin(_time * 8.0)) * 0.15  # Bounce: come and get us


func _add_cage() -> void:
	_cage = Node3D.new()
	add_child(_cage)
	var wood := Color(0.6, 0.4, 0.2)
	var s := CAGE_SIZE
	Visuals.box(_cage, Vector3(s.x, 0.1, s.z), wood, Vector3(0, 0.05, 0))
	Visuals.box(_cage, Vector3(s.x, 0.1, s.z), wood, Vector3(0, s.y, 0))
	for bx in 4:
		for side in [-1.0, 1.0]:
			var x := -s.x * 0.5 + s.x * bx / 3.0
			Visuals.box(_cage, Vector3(0.06, s.y, 0.06), wood, Vector3(x, s.y * 0.5, side * s.z * 0.5))
			Visuals.box(_cage, Vector3(0.06, s.y, 0.06), wood, Vector3(side * s.x * 0.5, s.y * 0.5, x))
	# A few captive gnomes inside
	for i in 3:
		var p := Army.formation_point(i) * 0.9
		Visuals.box(_cage, Vector3(0.22, 0.4, 0.22), Color(0.2, 0.35, 0.85), Vector3(p.x, 0.3, p.y))
		var hat := CylinderMesh.new()
		hat.top_radius = 0.0
		hat.bottom_radius = 0.14
		hat.height = 0.3
		Visuals.mesh(_cage, hat, Color(0.9, 0.15, 0.15), Vector3(p.x, 0.65, p.y))
	var label := Visuals.count_label(_cage, 2.3, 130)
	label.text = "+%d" % group.cage
	label.modulate = Color(0.55, 1.0, 0.55)
