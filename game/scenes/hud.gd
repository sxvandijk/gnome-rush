class_name Hud
extends CanvasLayer
## End-of-run panel with the result and a retry button.

signal retry_pressed

var _panel: PanelContainer
var _title: Label
var _detail: Label


func _ready() -> void:
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

	var button := Button.new()
	button.text = "Opnieuw"
	button.custom_minimum_size = Vector2(520, 160)
	button.add_theme_font_size_override("font_size", 72)
	button.pressed.connect(retry_pressed.emit)
	box.add_child(button)


func show_result(won: bool, count: int) -> void:
	_title.text = "Gehaald!" if won else "Verloren"
	_detail.text = ("%d kabouters over" % count) if won else "Al je kabouters zijn op"
	_panel.visible = true


func _label(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label
