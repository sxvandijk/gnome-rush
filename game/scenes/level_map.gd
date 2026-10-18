extends Control
## Main screen: the level map, with coins and stars on top and the shop,
## daily challenge and endless mode below.

var _scroll: ScrollContainer
var _path: LevelMapPath


func _ready() -> void:
	var progress := Game.progress
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.8, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = 220
	_scroll.offset_bottom = -260
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	_path = LevelMapPath.new()
	_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path.setup(LevelLoader.level_count(), progress)
	_path.level_pressed.connect(Game.play)
	_scroll.add_child(_path)
	_scroll.get_v_scroll_bar().value_changed.connect(func(_v: float) -> void: _path.queue_redraw())

	var top := _bar(Control.PRESET_TOP_WIDE, 40, 200)
	top.add_child(_label("Gnome Rush", 72))
	top.add_child(_label("● %d munten    ★ %d" % [progress.coins, progress.total_stars()], 48, Color(1.0, 0.88, 0.4)))

	var bottom := HBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -230
	bottom.offset_bottom = -50
	bottom.offset_left = 30
	bottom.offset_right = -30
	bottom.add_theme_constant_override("separation", 20)
	add_child(bottom)
	var daily_done := progress.daily_claimed == Daily.today()
	bottom.add_child(_button("Winkel", Game.show_shop))
	bottom.add_child(_button("Dagelijks ✓" if daily_done else "Dagelijks", Game.play_daily))
	bottom.add_child(_button("Eindeloos\nrecord %d" % progress.endless_best, Game.play_endless))

	_scroll_to_current.call_deferred()


func _scroll_to_current() -> void:
	if not is_inside_tree():
		return  # Left the map already (development shortcuts)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var y := _path.node_pos(Game.progress.unlocked).y
	_scroll.scroll_vertical = int(y - _scroll.size.y * 0.6)


func _bar(preset: int, top: float, height: float) -> VBoxContainer:
	var bar := VBoxContainer.new()
	bar.set_anchors_and_offsets_preset(preset)
	bar.offset_top = top
	bar.offset_bottom = top + height
	add_child(bar)
	return bar


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 48)
	button.pressed.connect(action)
	return button


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.25, 0.1))
	label.add_theme_constant_override("outline_size", 16)
	return label
