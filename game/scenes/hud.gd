class_name Hud
extends CanvasLayer
## Run title, a back button, a live counter (endless rows) and the
## end-of-run panel with stars and coins.

signal retry_pressed
signal next_pressed
signal map_pressed

var _panel: PanelContainer
var _title: Label
var _stars: Label
var _detail: Label
var _coins: Label
var _primary: Button
var _counter: Label
var _next := false


func _ready() -> void:
	var back := Button.new()
	back.text = "‹ Kaart"
	back.add_theme_font_size_override("font_size", 48)
	back.position = Vector2(40, 60)
	back.pressed.connect(map_pressed.emit)
	add_child(back)

	_counter = _label(56)
	_counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_counter.offset_top = 150
	_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_counter)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.1, 0.88)
	style.set_corner_radius_all(40)
	style.set_content_margin_all(60)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	center.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 34)
	_panel.add_child(box)

	_title = _label(110)
	_stars = _label(120)
	_stars.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
	_detail = _label(60)
	_coins = _label(60)
	_coins.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	for label in [_title, _stars, _detail, _coins]:
		box.add_child(label)

	_primary = _button("Opnieuw")
	_primary.pressed.connect(func() -> void:
		if _next:
			next_pressed.emit()
		else:
			retry_pressed.emit())
	box.add_child(_primary)
	var map := _button("Kaart")
	map.pressed.connect(map_pressed.emit)
	box.add_child(map)


func set_title(text: String) -> void:
	var title := _label(56)
	title.text = text
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 70
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)


func set_counter(text: String) -> void:
	_counter.text = text


## result from Game.finish_run(); remaining = gnomes left over.
func show_result(result: Dictionary, remaining: int, endless: bool, has_next: bool) -> void:
	_next = result.won and has_next
	if endless:
		_title.text = "Nieuw record!" if result.record else "Klaar!"
		_stars.text = ""
		_detail.text = "%d rijen gehaald" % result.rows
	elif result.won:
		_title.text = "Gehaald!"
		_stars.text = "★".repeat(result.stars) + "☆".repeat(3 - result.stars)
		_detail.text = "%d kabouters over" % remaining
	else:
		_title.text = "Verloren"
		_stars.text = ""
		_detail.text = "Al je kabouters zijn op"
	_coins.text = "+%d munten" % result.coins if result.coins > 0 else ""
	_stars.visible = _stars.text != ""
	_coins.visible = _coins.text != ""
	_primary.text = "Volgende level" if _next else "Opnieuw"
	_panel.visible = true


func show_message(text: String) -> void:
	_title.text = "Oeps"
	_detail.text = text
	_stars.visible = false
	_coins.visible = false
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
