class_name LevelMapPath
extends Control
## The winding level path, level 1 at the bottom. Only the part inside the
## scroll window is drawn, so it copes with thousands of levels.

signal level_pressed(n: int)

const STEP_Y := 210.0
const AMPLITUDE := 290.0
const RADIUS := 76.0
const MARGIN := 260.0
const TAP_SLOP := 24.0
const CHAPTER_NAMES := ["Voortuin", "Moestuin", "Vijvertuin"]
const CHAPTER_COLORS := [Color(0.35, 0.65, 0.3), Color(0.6, 0.42, 0.25), Color(0.25, 0.5, 0.7)]
const LOCKED := Color(0.55, 0.58, 0.6)
const GOLD := Color(1.0, 0.8, 0.2)

var count := 0
var progress: Progress
var _press_pos := Vector2.INF
var _time := 0.0


func setup(p_count: int, p_progress: Progress) -> void:
	count = p_count
	progress = p_progress
	custom_minimum_size = Vector2(0, (count - 1) * STEP_Y + MARGIN * 2.0)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()  # The current level pulses


func node_pos(n: int) -> Vector2:
	return Vector2(size.x * 0.5 + sin(n * 0.55) * AMPLITUDE, custom_minimum_size.y - MARGIN - (n - 1) * STEP_Y)


func level_at(point: Vector2) -> int:
	var guess := roundi((custom_minimum_size.y - MARGIN - point.y) / STEP_Y) + 1
	for n in range(guess - 1, guess + 2):
		if n >= 1 and n <= count and node_pos(n).distance_to(point) <= RADIUS * 1.2:
			return n
	return 0


func _visible_range() -> Vector2i:
	var scroll := get_parent() as ScrollContainer
	var top := float(scroll.scroll_vertical) if scroll else 0.0
	var height := scroll.size.y if scroll else size.y
	var hi := floori((custom_minimum_size.y - MARGIN - top) / STEP_Y) + 3
	var lo := floori((custom_minimum_size.y - MARGIN - top - height) / STEP_Y) - 1
	return Vector2i(clampi(lo, 1, count), clampi(hi, 1, count))


func _draw() -> void:
	if count == 0:
		return
	var font := ThemeDB.fallback_font
	var r := _visible_range()
	for n in range(maxi(r.x - 1, 1), mini(r.y + 1, count)):
		var done := progress.is_unlocked(n + 1)
		draw_line(node_pos(n), node_pos(n + 1), Color(1, 1, 1, 0.9) if done else Color(1, 1, 1, 0.4), 22.0)
	for n in range(r.x, r.y + 1):
		_draw_level(n, font)


func _draw_level(n: int, font: Font) -> void:
	var pos := node_pos(n)
	var chapter := (n - 1) / LevelGenerator.LEVELS_PER_CHAPTER
	if (n - 1) % LevelGenerator.LEVELS_PER_CHAPTER == 0:
		var title := "Hoofdstuk %d · %s" % [chapter + 1, CHAPTER_NAMES[chapter % CHAPTER_NAMES.size()]]
		draw_string_outline(font, Vector2(0, pos.y + RADIUS + 110), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, 56, 14, Color(0.1, 0.25, 0.1))
		draw_string(font, Vector2(0, pos.y + RADIUS + 110), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, 56, Color.WHITE)

	var unlocked := progress.is_unlocked(n)
	var current := n == progress.unlocked
	var color: Color = CHAPTER_COLORS[chapter % CHAPTER_COLORS.size()] if unlocked else LOCKED
	if current:
		draw_circle(pos, RADIUS + 14 + sin(_time * 4.0) * 6.0, Color(1, 1, 1, 0.6))
	if n % 5 == 0:
		draw_circle(pos, RADIUS + 8, GOLD)
	draw_circle(pos, RADIUS, color)
	draw_string(font, pos + Vector2(-RADIUS, 22), str(n), HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 64, Color.WHITE if unlocked else Color(0.9, 0.9, 0.9))

	var stars := progress.stars_for(n)
	if unlocked and not current:
		var text := "★".repeat(stars) + "☆".repeat(3 - stars)
		draw_string_outline(font, pos + Vector2(-RADIUS, RADIUS + 46), text, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 44, 8, Color(0.2, 0.15, 0.05))
		draw_string(font, pos + Vector2(-RADIUS, RADIUS + 46), text, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 44, GOLD)


func _gui_input(event: InputEvent) -> void:
	# A tap opens a level; a drag scrolls (handled by the ScrollContainer)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
		elif _press_pos.distance_to(event.position) < TAP_SLOP:
			var n := level_at(event.position)
			if n > 0 and progress.is_unlocked(n):
				level_pressed.emit(n)
