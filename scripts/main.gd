extends Control

const FONT_BOLD: Font = preload("res://assets/fonts/baloo-bold.ttf")
const FONT_REG: Font = preload("res://assets/fonts/baloo-regular.ttf")

const COIN := Color(1.0, 0.84, 0.30)
const CYAN_BRIGHT := Color(0.42, 0.95, 0.90)
const LIME := Color(0.24, 0.85, 0.42)
const WHITE := Color(1.0, 1.0, 1.0)
const WHITE_DIM := Color(0.82, 0.87, 0.96)
const GRAY_DIM := Color(0.45, 0.52, 0.64)
const PANEL_BG := Color(0.06, 0.09, 0.16, 0.92)
const COIN_BG := Color(0.22, 0.16, 0.05, 0.72)
const DARK_BTN := Color(0.10, 0.13, 0.22)

const DEPT_EMOJI := {
	"emergency": "🚑",
	"surgery": "🔬",
	"orderly": "🤖",
	"bionics": "🧬",
	"nanite": "🦠",
	"psych": "🧠",
	"organ": "❤️",
	"neural": "⚡",
	"finger": "👆",
}

const DEPT_COLORS := {
	"emergency": Color(0.95, 0.30, 0.35),
	"surgery": Color(0.24, 0.81, 0.88),
	"orderly": Color(0.95, 0.72, 0.28),
	"bionics": Color(0.62, 0.40, 0.95),
	"nanite": Color(0.48, 0.85, 0.36),
	"psych": Color(0.95, 0.45, 0.70),
	"organ": Color(0.95, 0.58, 0.28),
	"neural": Color(0.95, 0.72, 0.28),
	"finger": Color(0.24, 0.81, 0.88),
}

var credits_label: Label
var cps_label: Label
var tap_value_label: Label
var milestone_fill: ColorRect
var milestone_clip: Panel
var milestone_text: Label
var tap_button: Button
var offline_label: Label
var float_layer: Control

var department_rows := {}
var upgrade_rows := {}


func _ready() -> void:
	_build_ui()
	Game.credits_changed.connect(_refresh)
	Game.tap_made.connect(_on_tap_made)
	_refresh()
	_show_offline_report()


func _rect(left: float, top: float, right: float, bottom: float) -> Rect2:
	return Rect2(size.x * left, size.y * top, size.x * (right - left), size.y * (bottom - top))


func _sb(bg: Color, radius: float, border := 0, border_color := Color(1.0, 1.0, 1.0, 0.0), shadow := 0.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	var r := int(radius)
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	if border > 0:
		sb.border_width_top = border
		sb.border_width_bottom = border
		sb.border_width_left = border
		sb.border_width_right = border
		sb.border_color = border_color
	if shadow > 0.0:
		sb.shadow_size = int(shadow)
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	return sb


func _ignore_all(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			_ignore_all(child)


func _font(node: Control, size: int, bold := true, color := Color(1.0, 1.0, 1.0, 0.0)) -> void:
	node.add_theme_font_override("font", FONT_BOLD if bold else FONT_REG)
	node.add_theme_font_size_override("font_size", size)
	if color.a > 0.0:
		node.add_theme_color_override("font_color", color)


func _panel(parent: Control, rect: Rect2, sb: StyleBoxFlat) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	return p


func _label(parent: Control, text: String, size: int, color: Color, bold := true, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	_font(l, size, bold, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _build_ui() -> void:
	_build_bg()
	_build_hud()
	_build_milestone()
	_build_tap_button()
	_build_shop()
	_build_overlays()


func _build_bg() -> void:
	var bg := Control.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_script(load("res://scripts/bg.gd"))
	add_child(bg)


func _build_hud() -> void:
	var title := _panel(self, _rect(0.16, 0.012, 0.84, 0.060), _sb(Color(1.0, 1.0, 1.0, 0.12), 18.0, 1, Color(1.0, 1.0, 1.0, 0.25)))
	var title_label := _label(title, "CYBER HOSPITAL EMPIRE", 21, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.set_anchors_preset(Control.PRESET_FULL_RECT)

	var coin_panel := _panel(self, _rect(0.03, 0.07, 0.62, 0.170), _sb(COIN_BG, 24.0, 1, Color(1.0, 0.84, 0.3, 0.45), 6.0))
	var coin_icon := _label(coin_panel, "💠", 30, WHITE)
	coin_icon.position = Vector2(16.0, coin_panel.size.y / 2.0 - 21.0)
	coin_icon.size = Vector2(46.0, 42.0)
	credits_label = _label(coin_panel, "0", 34, COIN)
	credits_label.position = Vector2(70.0, 0.0)
	credits_label.size = Vector2(coin_panel.size.x - 82.0, coin_panel.size.y)

	var cps_panel := _panel(self, _rect(0.66, 0.07, 0.97, 0.170), _sb(Color(0.05, 0.16, 0.22, 0.80), 24.0, 1, Color(0.3, 0.85, 0.9, 0.5), 6.0))
	cps_label = _label(cps_panel, "+0 /s", 25, CYAN_BRIGHT, true, HORIZONTAL_ALIGNMENT_CENTER)
	cps_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cps_label.offset_bottom = -cps_panel.size.y * 0.45
	tap_value_label = _label(cps_panel, "tap +0", 15, WHITE_DIM)
	tap_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_value_label.position = Vector2(0.0, cps_panel.size.y * 0.55)
	tap_value_label.size = cps_panel.size * Vector2(1.0, 0.45)


func _build_milestone() -> void:
	var track := _panel(self, _rect(0.03, 0.185, 0.97, 0.228), _sb(Color(0.0, 0.0, 0.0, 0.45), 16.0, 1, Color(1.0, 1.0, 1.0, 0.12)))
	milestone_clip = Panel.new()
	milestone_clip.position = Vector2(8.0, 6.0)
	milestone_clip.size = Vector2(track.size.x - 16.0, track.size.y - 12.0)
	milestone_clip.clip_contents = true
	milestone_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(milestone_clip)
	milestone_fill = ColorRect.new()
	milestone_fill.color = Color(0.24, 0.81, 0.88)
	milestone_fill.position = Vector2.ZERO
	milestone_fill.size = Vector2(1.0, milestone_clip.size.y)
	milestone_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	milestone_clip.add_child(milestone_fill)
	milestone_text = _label(track, "", 14, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	milestone_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	milestone_text.add_theme_color_override("font_outline_color", Color(0.0, 0.08, 0.2, 0.8))
	milestone_text.add_theme_constant_override("outline_size", 4)


func _build_tap_button() -> void:
	float_layer = Control.new()
	float_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(float_layer)

	var center := Vector2(size.x * 0.5, size.y * 0.545)
	var radius := minf(size.x * 0.116, size.y * 0.064)

	var ring := Panel.new()
	ring.position = center - Vector2(radius * 1.22, radius * 1.22)
	ring.size = Vector2(radius * 2.44, radius * 2.44)
	ring.add_theme_stylebox_override("panel", _sb(Color(0.4, 0.95, 0.9, 0.14), radius * 1.22, 6, Color(0.6, 1.0, 0.96, 0.55)))
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.pivot_offset = ring.size / 2.0
	add_child(ring)
	_pulse_loops(ring)

	tap_button = Button.new()
	tap_button.position = center - Vector2(radius, radius)
	tap_button.size = Vector2(radius * 2.0, radius * 2.0)
	tap_button.pivot_offset = tap_button.size / 2.0
	tap_button.focus_mode = Control.FOCUS_NONE
	tap_button.add_theme_stylebox_override("normal", _sb(Color(0.16, 0.68, 0.66), radius, 4, Color(1.0, 1.0, 1.0, 0.55), 8.0))
	tap_button.add_theme_stylebox_override("hover", _sb(Color(0.26, 0.82, 0.78), radius, 4, Color(1.0, 1.0, 1.0, 0.7), 8.0))
	tap_button.add_theme_stylebox_override("pressed", _sb(Color(0.10, 0.5, 0.5), radius, 4, Color(1.0, 1.0, 1.0, 0.4), 4.0))
	tap_button.pressed.connect(_on_tap_pressed)
	add_child(tap_button)

	var icon := _label(tap_button, "🏥", int(radius * 0.85), WHITE)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.position = Vector2(0.0, radius * 0.18)
	icon.size = Vector2(radius * 2.0, radius * 0.75)

	var hint := _label(tap_button, "ADMIT PATIENT", int(radius * 0.27), WHITE)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0.0, radius * 1.02)
	hint.size = Vector2(radius * 2.0, radius * 0.5)
	_ignore_all(tap_button)


func _pulse_loops(node: Control) -> void:
	var t := create_tween()
	t.set_loops()
	t.tween_property(node, "scale", Vector2(1.0, 1.0) * 1.18, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", Vector2(1.0, 1.0) * 1.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(0.15)


func _on_tap_pressed() -> void:
	Game.do_tap()
	var dance := create_tween()
	dance.tween_property(tap_button, "scale", Vector2(0.90, 0.90), 0.06)
	dance.tween_property(tap_button, "scale", Vector2(1.07, 1.07), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	dance.tween_property(tap_button, "scale", Vector2(1.0, 1.0), 0.1)


func _build_shop() -> void:
	var shelf := _panel(self, _rect(0.0, 0.655, 1.0, 1.0), _sb(PANEL_BG, 44.0, 0, Color(0.0, 0.0, 0.0, 0.0), 18.0))

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0.0, 26.0)
	scroll.size = Vector2(shelf.size.x, shelf.size.y - 26.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	shelf.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	content.add_theme_constant_override("parent_h_margin", 18)
	content.add_theme_constant_override("parent_s_h_margin", 18)
	scroll.add_child(content)

	var dept_header := _label(content, "🏥 DEPARTMENTS", 19, CYAN_BRIGHT, true, HORIZONTAL_ALIGNMENT_CENTER)
	dept_header.custom_minimum_size = Vector2(0.0, 34.0)

	for id in Game.departments:
		var dept_id: String = id
		_make_department_card(content, dept_id)

	var up_header := _label(content, "⚡ IMPLANTS & UPGRADES", 19, Color(0.6, 0.95, 0.8), true, HORIZONTAL_ALIGNMENT_CENTER)
	up_header.custom_minimum_size = Vector2(0.0, 34.0)

	for id in Game.upgrades:
		var up_id: String = id
		_make_upgrade_card(content, up_id)


func _card_button(parent: Control, height: float) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0.0, height)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _sb(Color(0.09, 0.13, 0.22), 22.0, 2, Color(1.0, 1.0, 1.0, 0.12), 5.0))
	btn.add_theme_stylebox_override("hover", _sb(Color(0.11, 0.17, 0.28), 22.0, 2, Color(0.42, 0.95, 0.9, 0.75), 5.0))
	btn.add_theme_stylebox_override("pressed", _sb(Color(0.06, 0.09, 0.15), 22.0, 2, Color(0.3, 0.7, 0.7, 0.6), 2.0))
	btn.add_theme_stylebox_override("disabled", _sb(Color(0.05, 0.07, 0.12), 22.0, 1, Color(1.0, 1.0, 1.0, 0.06), 2.0))
	parent.add_child(btn)
	return btn


func _row_widgets(btn: Button, height: float, cost_w: float) -> Dictionary:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14.0
	row.offset_right = -14.0
	row.add_theme_constant_override("separation", 14)
	btn.add_child(row)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)

	var cost_panel := Panel.new()
	cost_panel.custom_minimum_size = Vector2(cost_w, height * 0.55)
	cost_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cost_panel.add_theme_stylebox_override("panel", _sb(DARK_BTN, 14.0))
	row.add_child(cost_panel)
	var buy := _label(cost_panel, "BUY", 11, WHITE_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
	buy.set_anchors_preset(Control.PRESET_TOP_WIDE)
	buy.offset_bottom = 18.0
	var cost := _label(cost_panel, "0", 19, GRAY_DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
	cost.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cost.offset_top = -32.0

	_ignore_all(cost_panel)
	return {"row": row, "mid": mid, "cost_panel": cost_panel, "cost": cost}


func _make_department_card(parent: Control, id: String) -> void:
	var d: Dictionary = Game.departments[id]
	var btn := _card_button(parent, 112.0)
	var w := _row_widgets(btn, 112.0, 116.0)
	var row: HBoxContainer = w.row
	var mid: VBoxContainer = w.mid

	var circle := Panel.new()
	circle.custom_minimum_size = Vector2(78.0, 86.0)
	circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	circle.add_theme_stylebox_override("panel", _sb(DEPT_COLORS[id], 22.0))
	row.add_child(circle)
	var icon := _label(circle, DEPT_EMOJI[id], 40, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ignore_all(circle)

	var title := _label(mid, d.name, 20, WHITE)
	title.custom_minimum_size = Vector2(0.0, 30.0)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var info := _label(mid, "", 15, WHITE_DIM)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ignore_all(mid)
	row.add_child(mid)

	var cost_panel: Panel = w.cost_panel
	var cost: Label = w.cost
	cost.name = "cost"
	cost.text = "0"
	btn.pressed.connect(func() -> void:
		Game.buy_department(id)
	)
	department_rows[id] = {"btn": btn, "info": info, "cost": cost, "cost_panel": cost_panel, "content": row}


func _make_upgrade_card(parent: Control, id: String) -> void:
	var u: Dictionary = Game.upgrades[id]
	var btn := _card_button(parent, 98.0)
	var w := _row_widgets(btn, 98.0, 108.0)
	var row: HBoxContainer = w.row
	var mid: VBoxContainer = w.mid

	var circle := Panel.new()
	circle.custom_minimum_size = Vector2(66.0, 72.0)
	circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	circle.add_theme_stylebox_override("panel", _sb(DEPT_COLORS[id], 20.0))
	row.add_child(circle)
	var icon := _label(circle, DEPT_EMOJI[id], 34, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ignore_all(circle)

	var title := _label(mid, u.name, 18, WHITE)
	title.custom_minimum_size = Vector2(0.0, 26.0)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var info := _label(mid, "", 13, WHITE_DIM)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ignore_all(mid)
	row.add_child(mid)

	var cost_panel: Panel = w.cost_panel
	var cost: Label = w.cost
	cost.name = "cost"
	cost.text = "0"
	btn.pressed.connect(func() -> void:
		Game.buy_upgrade(id)
	)
	upgrade_rows[id] = {"btn": btn, "info": info, "cost": cost, "cost_panel": cost_panel, "content": row}


func _build_overlays() -> void:
	offline_label = Label.new()
	offline_label.text = ""
	offline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	offline_label.position = Vector2(70.0, 330.0)
	offline_label.size = Vector2(size.x - 140.0, 110.0)
	offline_label.add_theme_font_override("font", FONT_BOLD)
	offline_label.add_theme_font_size_override("font_size", 22)
	offline_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	offline_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	offline_label.add_theme_constant_override("outline_size", 8)
	offline_label.visible = false
	add_child(offline_label)


func _refresh() -> void:
	credits_label.text = Game.format_num(Game.credits)
	cps_label.text = "+%s /s" % Game.format_num(Game.total_cps())
	tap_value_label.text = "tap +%s" % Game.format_num(Game.tap_value())
	_update_milestone()
	for id in Game.departments:
		var d: Dictionary = Game.departments[id]
		var cost := Game.next_cost(id)
		var affordable := Game.credits >= cost
		var row: Dictionary = department_rows[id]
		var btn := row.btn as Button
		btn.disabled = not affordable
		row.info.text = "Own %d   ·   each +%s/s" % [d.owned, Game.format_num(Game.department_cps(id))]
		row.cost.text = Game.format_num(cost)
		_style_cost(row, affordable)
	_refresh_upgrades()


func _update_milestone() -> void:
	var target: String = ""
	for id in Game.departments:
		if Game.departments[id].owned <= 0:
			target = id
			break
	if target == "":
		milestone_fill.size.x = milestone_clip.size.x
		milestone_text.text = "🏆 ALL DEPARTMENTS ONLINE"
		return
	var cost := Game.next_cost(target)
	var progress := clampf(Game.credits / cost, 0.0, 1.0)
	milestone_fill.size.x = milestone_clip.size.x * progress
	milestone_text.text = "NEXT: %s   ·   %s / %s" % [Game.departments[target].name, Game.format_num(Game.credits), Game.format_num(cost)]


func _refresh_upgrades() -> void:
	for id in Game.upgrades:
		var u: Dictionary = Game.upgrades[id]
		var lvl := Game.upgrade_level(id)
		var max := int(u.max)
		var row: Dictionary = upgrade_rows[id]
		var btn := row.btn as Button
		if lvl >= max:
			btn.disabled = true
			row.info.text = "%s   ·   Lv %d/%d  [MAX]" % [u.desc, lvl, max]
			row.cost.text = "MAX"
			_style_cost(row, false)
		else:
			var cost := Game.next_upgrade_cost(id)
			var affordable := Game.credits >= cost
			btn.disabled = not affordable
			row.info.text = "%s   ·   Lv %d/%d" % [u.desc, lvl, max]
			row.cost.text = Game.format_num(cost)
			_style_cost(row, affordable)


func _style_cost(row: Dictionary, affordable: bool) -> void:
	var panel: Panel = row.cost_panel
	var cost: Label = row.cost
	var content: Control = row.content
	var btn: Button = row.btn
	panel.add_theme_stylebox_override("panel", _sb(LIME if affordable else DARK_BTN, 14.0))
	cost.add_theme_color_override("font_color", Color(0.03, 0.18, 0.07) if affordable else GRAY_DIM)
	content.modulate = Color(1.0, 1.0, 1.0, 1.0) if affordable else Color(0.55, 0.55, 0.62, 0.9)
	btn.add_theme_stylebox_override("normal", _sb(Color(0.09, 0.13, 0.22), 22.0, 2, Color(0.32, 0.85, 0.82, 0.55) if affordable else Color(1.0, 1.0, 1.0, 0.08), 5.0))
	btn.add_theme_stylebox_override("hover", _sb(Color(0.11, 0.17, 0.28), 22.0, 2, Color(0.42, 0.95, 0.9, 0.8), 5.0))


func _on_tap_made(amount: float) -> void:
	var y0 := size.y * 0.545
	var x0 := size.x * 0.5
	var label := Label.new()
	label.text = "+%s" % Game.format_num(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_BOLD)
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("outline_size", 8)
	label.position = Vector2(x0 - 70.0 + randf_range(-30.0, 30.0), y0 - 170.0)
	label.size = Vector2(140.0, 44.0)
	label.z_index = 5
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	float_layer.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.08)
	tween.tween_property(label, "position:y", label.position.y - 110.0, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)


func _show_offline_report() -> void:
	var earned: float = Game.offline_report.earned
	if earned <= 0.0:
		return
	var mins := int(Game.offline_report.seconds / 60.0)
	offline_label.text = "While you were away (%d min),\nyour hospital earned +%s" % [mins, Game.format_num(earned)]
	offline_label.visible = true
	var tween := create_tween()
	tween.tween_interval(4.5)
	tween.tween_property(offline_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func() -> void:
		offline_label.visible = false
		offline_label.modulate.a = 1.0
	)
