extends Control

@onready var credits_label: Label = %CreditsLabel
@onready var cps_label: Label = %CpsLabel
@onready var departments_box: VBoxContainer = %Departments
@onready var tap_button: Button = %TapButton
@onready var tap_hint: Label = %TapHint
@onready var float_layer: Control = %FloatLayer
@onready var offline_label: Label = %OfflineLabel

var department_buttons := {}


func _ready() -> void:
	Game.credits_changed.connect(_refresh)
	Game.tap_made.connect(_on_tap_made)
	tap_button.pressed.connect(Game.do_tap)
	for id in Game.departments:
		var dept_id: String = id
		_make_department_button(dept_id)
	_refresh()
	_show_offline_report()


func _refresh() -> void:
	credits_label.text = Game.format_num(Game.credits)
	cps_label.text = "%s /s" % Game.format_num(Game.total_cps())
	tap_hint.text = "ADMIT PATIENT  (+%s)" % Game.format_num(Game.tap_value)
	for id in Game.departments:
		var d: Dictionary = Game.departments[id]
		var cost := Game.next_cost(id)
		var btn: Button = department_buttons[id]
		btn.disabled = Game.credits < cost
		btn.text = "%s\nOwned %d   |   %s/s each   |   Cost %s" % [
			d.name,
			d.owned,
			Game.format_num(d.base_cps),
			Game.format_num(cost),
		]


func _make_department_button(id: String) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0.0, 92.0)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.85, 0.93, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.52, 0.62))
	btn.pressed.connect(func() -> void:
		Game.buy_department(id)
	)
	departments_box.add_child(btn)
	department_buttons[id] = btn


func _on_tap_made(amount: float) -> void:
	_spawn_float("+%s" % Game.format_num(amount))


func _spawn_float(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("outline_size", 8)
	label.position = Vector2(randf_range(140.0, 430.0), randf_range(620.0, 780.0))
	label.modulate.a = 0.0
	float_layer.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.1)
	tween.tween_property(label, "position:y", label.position.y - 90.0, 0.9)
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
	)
