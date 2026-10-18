extends Control
## Shop: upgrades and skins, paid with coins. Skin packs come with the
## PurchaseService in M5.

const UPGRADE_INFO := {
	"army": ["Groter startleger", "+%d kabouters bij de start"],
	"fire": ["Sneller schieten", "%.1f eikels per seconde"],
	"damage": ["Meer schade", "%.2f schade per eikel op de baas"],
	"coins": ["Meer munten", "+%d%% munten"],
}

var _coins: Label
var _list: VBoxContainer
var _tab := "upgrades"


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.5, 0.72, 0.45)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 40
	root.offset_right = -40
	root.offset_top = 60
	root.offset_bottom = -60
	root.add_theme_constant_override("separation", 24)
	add_child(root)

	var top := HBoxContainer.new()
	var back := _button("‹ Kaart", 48)
	back.pressed.connect(Game.show_map)
	top.add_child(back)
	_coins = _label("", 52, Color(1.0, 0.88, 0.4))
	_coins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_coins)
	root.add_child(top)
	root.add_child(_label("Winkel", 90))

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 20)
	for tab in [["upgrades", "Upgrades"], ["skins", "Skins"]]:
		var button := _button(tab[1], 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			_tab = tab[0]
			_rebuild())
		tabs.add_child(button)
	root.add_child(tabs)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 20)
	scroll.add_child(_list)
	_rebuild()


func _rebuild() -> void:
	var progress := Game.progress
	_coins.text = "● %d munten" % progress.coins
	for child in _list.get_children():
		child.queue_free()
	if _tab == "upgrades":
		for kind in Progress.UPGRADES:
			_list.add_child(_upgrade_row(kind))
	else:
		for skin in Skins.CATALOG:
			_list.add_child(_skin_row(skin))


func _upgrade_row(kind: String) -> Control:
	var progress := Game.progress
	var level: int = progress.upgrades[kind]
	var info: Array = UPGRADE_INFO[kind]
	var effect: String
	match kind:
		"army":
			effect = info[1] % progress.start_bonus()
		"fire":
			effect = info[1] % progress.fire_rate()
		"damage":
			effect = info[1] % progress.boss_damage()
		_:
			effect = info[1] % roundi((progress.coin_multiplier() - 1.0) * 100.0)
	var cost := progress.upgrade_cost(kind)
	var button := _button("Max" if cost < 0 else "%d ●" % cost, 48)
	button.disabled = cost < 0 or progress.coins < cost
	button.pressed.connect(func() -> void:
		if progress.buy_upgrade(kind):
			Game.save()
			_rebuild())
	return _row(info[0], "Niveau %d/%d · %s" % [level, Progress.UPGRADES[kind].max, effect], button)


func _skin_row(skin: Dictionary) -> Control:
	var progress := Game.progress
	var owned: bool = skin.id in progress.skins_owned
	var button: Button
	if progress.skin == skin.id:
		button = _button("Gekozen", 48)
		button.disabled = true
	elif owned:
		button = _button("Kies", 48)
		button.pressed.connect(func() -> void:
			progress.select_skin(skin.id)
			Game.save()
			_rebuild())
	elif skin.price < 0:
		button = _button("Pakket", 48)
		button.disabled = true
	else:
		button = _button("%d ●" % skin.price, 48)
		button.disabled = progress.coins < skin.price
		button.pressed.connect(func() -> void:
			if progress.buy_skin(skin.id):
				progress.select_skin(skin.id)
				Game.save()
				_rebuild())
	var row := _row(skin.name, "Alleen uiterlijk" if skin.price >= 0 else "Komt in een skinpakket", button)
	var swatch := VBoxContainer.new()
	swatch.add_theme_constant_override("separation", 0)
	for part in [["hat", 36], ["body", 54]]:
		var rect := ColorRect.new()
		rect.color = skin[part[0]]
		rect.custom_minimum_size = Vector2(60, part[1])
		swatch.add_child(rect)
	row.get_child(0).add_child(swatch)
	row.get_child(0).move_child(swatch, 0)
	return row


func _row(title: String, detail: String, button: Button) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.2, 0.1, 0.55)
	style.set_corner_radius_all(30)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := _label(title, 52)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var detail_label := _label(detail, 36, Color(0.9, 0.95, 0.85))
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(name_label)
	text.add_child(detail_label)
	row.add_child(text)
	button.custom_minimum_size = Vector2(260, 110)
	row.add_child(button)
	return panel


func _button(text: String, size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", size)
	return button


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.25, 0.1))
	label.add_theme_constant_override("outline_size", 12)
	return label
