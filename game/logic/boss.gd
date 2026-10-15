class_name Boss
extends RefCounted
## The boss at the end of a level. Each gnome that reaches it costs it one
## hit point; acorns chip away a fraction.

const RADIUS := 1.5

var z: float
var hp: float
var max_hp: float
var kind: String


func _init(p_z: float, p_hp: float, p_kind := "mole_king") -> void:
	z = p_z
	hp = p_hp
	max_hp = p_hp
	kind = p_kind


static func from_dict(data: Dictionary) -> Boss:
	return new(float(data["z"]), float(data["hp"]), str(data.get("kind", "mole_king")))


func damage(amount: float) -> void:
	hp = maxf(hp - amount, 0.0)


func is_defeated() -> bool:
	return hp <= 0.0


## Hit points as shown to the player: a partly damaged point still counts.
func hp_display() -> int:
	return ceili(hp)
