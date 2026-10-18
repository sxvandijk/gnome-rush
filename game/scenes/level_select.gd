extends Control
## Temporary level picker: all 60 levels by chapter. The Candy Crush style
## map with unlocking replaces this in M4.

const CHAPTER_NAMES := ["Voortuin", "Moestuin", "Vijvertuin"]
const CHAPTER_COLORS := [Color(0.35, 0.65, 0.3), Color(0.55, 0.4, 0.25), Color(0.25, 0.5, 0.65)]
const COLUMNS := 5


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.8, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	margin.add_theme_constant_override("margin_top", 140)
	margin.add_theme_constant_override("margin_bottom", 80)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 30)
	scroll.add_child(list)

	list.add_child(_label("Gnome Rush", 110))
	var count := LevelLoader.level_count()
	var chapters := ceili(float(count) / LevelGenerator.LEVELS_PER_CHAPTER)
	for c in chapters:
		list.add_child(_label("Hoofdstuk %d · %s" % [c + 1, CHAPTER_NAMES[c % CHAPTER_NAMES.size()]], 64))
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 24)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		list.add_child(grid)
		for i in LevelGenerator.LEVELS_PER_CHAPTER:
			var n := c * LevelGenerator.LEVELS_PER_CHAPTER + i + 1
			if n <= count:
				grid.add_child(_level_button(n, CHAPTER_COLORS[c % CHAPTER_COLORS.size()]))


func _level_button(n: int, color: Color) -> Button:
	var button := Button.new()
	button.text = str(n)
	button.custom_minimum_size = Vector2(160, 160)
	button.add_theme_font_size_override("font_size", 64)
	var boss := n % 5 == 0
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.3) if boss else color
	style.set_corner_radius_all(80)
	style.set_border_width_all(8 if boss else 0)
	style.border_color = Color(1.0, 0.8, 0.2)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(Game.play.bind(n))
	return button


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.25, 0.1))
	label.add_theme_constant_override("outline_size", 18)
	return label
