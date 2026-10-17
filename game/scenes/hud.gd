class_name Hud
extends CanvasLayer
## Level title, a back button and the end-of-run panel.

signal retry_pressed
signal next_pressed
signal levels_pressed

var _panel: PanelContainer
var _title: Label
var _detail: Label
var _primary: Button
var _won := false


func _ready() -> void:
	var back := Button.new()
	back.text = "‹ Levels"
	back.add_theme_font_size_override("font_size", 48)
	back.position = Vector2(40, 60)
	back.pressed.connect(levels_pressed.emit)
	add_child(back)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.1, 0.85)
	style.set_corner_radius_all(40)
	style.set_content_margin_all(60)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	center.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 40)
	_panel.add_child(box)

	_title = _label(110)
	_detail = _label(64)
	box.add_child(_title)
	box.add_child(_detail)

	_primary = _button("Opnieuw")
	_primary.pressed.connect(func() -> void:
		if _won:
			next_pressed.emit()
		else:
			retry_pressed.emit())
	box.add_child(_primary)
	var levels := _button("Levels")
	levels.pressed.connect(levels_pressed.emit)
	box.add_child(levels)


func set_level_title(text: String) -> void:
	var title := _label(56)
	title.text = text
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 70
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)


func show_result(won: bool, count: int, has_next: bool) -> void:
	_won = won and has_next
	_title.text = "Gehaald!" if won else "Verloren"
	_detail.text = ("%d kabouters over" % count) if won else "Al je kabouters zijn op"
	_primary.text = "Volgende level" if _won else "Opnieuw"
	_panel.visible = true


func show_message(text: String) -> void:
	_title.text = "Oeps"
	_detail.text = text
	_primary.visible = false
	_panel.visible = true


func _label(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.2, 0.1))
	label.add_theme_constant_override("outline_size", 12)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(560, 150)
	button.add_theme_font_size_override("font_size", 64)
	return button
