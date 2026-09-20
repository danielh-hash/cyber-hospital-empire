extends Node

signal credits_changed
signal tap_made(amount: float)

const SAVE_PATH := "user://cyber_hospital_save.json"
const OFFLINE_CAP_SECONDS := 12.0 * 3600.0
const AUTOSAVE_INTERVAL := 5.0

var credits := 0.0
var tap_value := 1.0
var departments := {}
var offline_report := {"seconds": 0.0, "earned": 0.0}

var _last_seen := Time.get_unix_time_from_system()
var _save_timer := 0.0


func _ready() -> void:
	_register_departments()
	load_game()


func _process(delta: float) -> void:
	var cps := total_cps()
	if cps > 0.0:
		add_credits(cps * delta)
	_save_timer += delta
	if _save_timer >= AUTOSAVE_INTERVAL:
		_save_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _register_departments() -> void:
	_add_department("emergency", "Emergency Bay", 15.0, 0.5)
	_add_department("surgery", "Cyber-Surgery Suite", 110.0, 3.0)
	_add_department("orderly", "Robo-Orderly", 500.0, 12.0)
	_add_department("bionics", "Bionics Lab", 2600.0, 55.0)
	_add_department("nanite", "Nanite Dispenser", 13000.0, 260.0)
	_add_department("psych", "Cyber-Psych Ward", 70000.0, 1200.0)
	_add_department("organ", "Organ Farm", 350000.0, 5200.0)


func _add_department(id: String, name: String, base_cost: float, base_cps: float, cost_mult := 1.35) -> void:
	departments[id] = {
		"id": id,
		"name": name,
		"owned": 0,
		"base_cost": base_cost,
		"base_cps": base_cps,
		"cost_mult": cost_mult,
	}


func total_cps() -> float:
	var total := 0.0
	for id in departments:
		var d: Dictionary = departments[id]
		total += d.base_cps * d.owned
	return total


func next_cost(id: String) -> float:
	var d: Dictionary = departments[id]
	return d.base_cost * pow(d.cost_mult, d.owned)


func buy_department(id: String) -> bool:
	var d: Dictionary = departments[id]
	var cost := next_cost(id)
	if credits < cost:
		return false
	credits -= cost
	d.owned += 1
	credits_changed.emit()
	return true


func do_tap() -> void:
	add_credits(tap_value)
	tap_made.emit(tap_value)


func add_credits(amount: float) -> void:
	if amount == 0.0:
		return
	credits += amount
	credits_changed.emit()


func save_game() -> void:
	var data := {
		"credits": credits,
		"tap_value": tap_value,
		"last_seen": _last_seen,
		"departments": {},
	}
	for id in departments:
		data.departments[id] = departments[id].owned
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return
	credits = float(parsed.get("credits", 0.0))
	tap_value = float(parsed.get("tap_value", 1.0))
	_last_seen = float(parsed.get("last_seen", Time.get_unix_time_from_system()))
	var counts: Dictionary = parsed.get("departments", {})
	for id in departments:
		departments[id].owned = int(counts.get(id, 0))
	_apply_offline_earnings()


func _apply_offline_earnings() -> void:
	var now := Time.get_unix_time_from_system()
	var elapsed := now - _last_seen
	if elapsed <= 0.0:
		return
	var capped := minf(elapsed, OFFLINE_CAP_SECONDS)
	var earned := total_cps() * capped
	if earned > 0.0:
		credits += earned
		offline_report = {"seconds": capped, "earned": earned}
		credits_changed.emit()
	_last_seen = now


static func format_num(value: float) -> String:
	var n := value
	if n < 0.0:
		n = 0.0
	var fixed := String.num_int64(int(n))
	if n < 1000.0:
		return fixed
	var suffixes := ["K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc"]
	var idx := -1
	while n >= 1000.0 and idx < suffixes.size() - 1:
		n /= 1000.0
		idx += 1
	return "%s%s" % [String.num(n, 2), suffixes[idx]]