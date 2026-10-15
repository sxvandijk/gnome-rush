class_name RunState
extends RefCounted
## One attempt at a level. Simulates at a fixed step so every run with the
## same input gives the same result, whatever the frame rate. Distance grows
## forward from 0; acorns are stored as Vector2(x, distance).

signal pair_passed(pair: GatePair, gate: Gate)
signal gate_hit(pair: GatePair, gate: Gate)
signal fight_started(group: MoleGroup)
signal cage_opened(group: MoleGroup)
signal boss_reached

const STEP := 1.0 / 60.0
const STEER_RATE := 12.0
const ACORN_SPEED := 30.0
const ACORN_RANGE := 42.0
const MAX_ACORNS := 90
const ACORN_BOSS_DAMAGE := 0.25
const MOLE_INTERVAL := 0.035
## The army keeps running at this fraction of its speed while it fights a
## mole group, pushing the moles ahead instead of stopping dead.
const MOLE_FIGHT_SPEED := 0.5
## Chasing moles start closing in when the army is this close.
const CHASE_RANGE := 20.0
const MOWER_INTERVAL := 0.045
const EPSILON := 1e-6

var level: LevelData
var army: Army
var pairs: Array[GatePair]
var moles: Array[MoleGroup]
var mowers: Array[Mower]
var boss: Boss
var distance := 0.0
var time := 0.0
var target_x := 0.0
var fire_rate := 5.0
var acorns := PackedVector2Array()
var shots_fired := 0
var moles_defeated := 0
var fighting: MoleGroup = null
var at_boss := false

var _accum := 0.0
var _fire_accum := 0.0
var _next_pair := 0
var _fight_accum := 0.0
var _boss_accum := 0.0
var _mower_accums: Array[float] = []


func _init(p_level: LevelData) -> void:
	level = p_level
	army = Army.new(level.start_count, level.army_x_limit)
	pairs = level.create_pairs()
	moles = level.create_moles()
	mowers = level.create_mowers()
	boss = level.create_boss()
	_mower_accums.resize(mowers.size())
	_mower_accums.fill(0.0)


func set_target_x(x: float) -> void:
	target_x = clampf(x, -army.x_limit, army.x_limit)


func update(delta: float) -> void:
	_accum += delta
	while _accum >= STEP - EPSILON and not is_finished():
		_accum -= STEP
		_step(STEP)


func is_finished() -> bool:
	return army.is_defeated() or is_won()


func is_won() -> bool:
	if army.is_defeated():
		return false
	if boss:
		return boss.is_defeated()
	return distance >= level.length


## Seconds between gnomes lost against the boss; faster for big armies.
static func boss_interval(army_count: int) -> float:
	return maxf(0.012, 0.05 - army_count / 4000.0)


func _step(dt: float) -> void:
	time += dt
	army.set_center_x(lerpf(army.center_x, target_x, minf(1.0, dt * STEER_RATE)))
	_chase(dt)
	_update_acorns(dt)
	_fire(dt)
	if at_boss:
		_fight_boss(dt)
	elif fighting:
		_fight_moles(dt)
		if not army.is_defeated():
			_move(dt * MOLE_FIGHT_SPEED)
	else:
		_move(dt)
	_update_mowers(dt)


func _move(dt: float) -> void:
	var stop := level.length
	if boss:
		stop = boss.z - Boss.RADIUS - army.radius()
	distance = minf(distance + level.speed * dt, stop)
	if fighting:
		fighting.z = maxf(fighting.z, distance + army.radius() + fighting.radius())

	while _next_pair < pairs.size() and pairs[_next_pair].z <= distance:
		var pair := pairs[_next_pair]
		var gate := pair.gate_for_x(army.center_x)
		army.pass_gate_pair(pair)
		_next_pair += 1
		pair_passed.emit(pair, gate)
		if army.is_defeated():
			return

	_check_moles()
	_check_cages()
	if boss and distance >= stop:
		at_boss = true
		boss_reached.emit()


func _check_moles() -> void:
	if fighting:
		return
	var r := army.radius()
	for group in moles:
		if group.resolved:
			continue
		var reach := r + group.radius()
		if group.z - distance > reach:
			break  # Sorted by z: the rest is further ahead
		if distance - group.z > reach:
			group.resolved = true  # Dodged
		elif absf(army.center_x - group.x) < reach:
			fighting = group
			_fight_accum = 0.0
			fight_started.emit(group)
			return


func _fight_moles(dt: float) -> void:
	_fight_accum += dt
	while _fight_accum >= MOLE_INTERVAL - EPSILON and fighting.count > 0 and not army.is_defeated():
		_fight_accum -= MOLE_INTERVAL
		fighting.count -= 1
		moles_defeated += 1
		army.remove(1)
	if fighting.count <= 0:
		fighting.resolved = true
		fighting = null


## A freed cage opens when the army walks over it; passing it loses it.
func _check_cages() -> void:
	var r := army.radius()
	for group in moles:
		if not group.cage_waiting():
			continue
		var reach := r + MoleGroup.CAGE_RADIUS
		if distance - group.z > reach:
			group.cage_missed = true
		elif absf(distance - group.z) < reach and absf(army.center_x - group.x) < reach:
			group.cage_opened = true
			army.add(group.cage)
			cage_opened.emit(group)


## Chasing moles slide sideways towards the army once it is in range.
func _chase(dt: float) -> void:
	for group in moles:
		if group.chase <= 0.0 or group.resolved or group == fighting:
			continue
		var ahead := group.z - distance
		if ahead < 0.0 or ahead > CHASE_RANGE:
			continue
		group.x = clampf(move_toward(group.x, army.center_x, group.chase * dt), -army.x_limit, army.x_limit)


func _fight_boss(dt: float) -> void:
	_boss_accum += dt
	while not boss.is_defeated() and not army.is_defeated():
		var interval := boss_interval(army.count)
		if _boss_accum < interval - EPSILON:
			break
		_boss_accum -= interval
		boss.damage(1.0)
		army.remove(1)


func _update_mowers(dt: float) -> void:
	var r := army.radius()
	for i in mowers.size():
		if not mowers[i].overlaps(army.center_x, distance, r, time):
			_mower_accums[i] = 0.0
			continue
		_mower_accums[i] += dt
		while _mower_accums[i] >= MOWER_INTERVAL - EPSILON and not army.is_defeated():
			_mower_accums[i] -= MOWER_INTERVAL
			army.remove(1)


func _fire(dt: float) -> void:
	if army.is_defeated():
		return
	_fire_accum += dt * fire_rate
	while _fire_accum >= 1.0 - EPSILON:
		_fire_accum -= 1.0
		if acorns.size() >= MAX_ACORNS:
			continue
		# Cycle through the visible gnomes so shots spread over the swarm
		var shooter := shots_fired % mini(army.count, Army.MAX_VISIBLE)
		acorns.append(Vector2(army.center_x + Army.formation_point(shooter).x, distance))
		shots_fired += 1


func _update_acorns(dt: float) -> void:
	var kept := PackedVector2Array()
	for acorn in acorns:
		var from := acorn.y
		acorn.y += ACORN_SPEED * dt
		if not _acorn_hits(acorn.x, from, acorn.y) and acorn.y <= distance + ACORN_RANGE:
			kept.append(acorn)
	acorns = kept


## Returns true when the acorn hit something on its way from `from` to `to`.
func _acorn_hits(x: float, from: float, to: float) -> bool:
	for i in range(_next_pair, pairs.size()):
		var pair := pairs[i]
		if pair.z > to:
			break
		if pair.z > from and not pair.used:
			var gate := pair.gate_for_x(x)
			gate.hit_by_acorn()
			gate_hit.emit(pair, gate)
			return true
	for group in moles:
		if group.resolved or group.count <= 0:
			continue
		if group.z > from and group.z <= to and absf(x - group.x) < group.radius():
			group.count -= 1
			moles_defeated += 1
			if group.count <= 0:
				group.resolved = true
				if fighting == group:
					fighting = null
			return true
	if boss and not boss.is_defeated() and to >= boss.z - Boss.RADIUS:
		boss.damage(ACORN_BOSS_DAMAGE)
		return true
	return false
