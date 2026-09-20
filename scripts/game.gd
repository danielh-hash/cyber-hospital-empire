extends Node

signal credits_changed
signal tap_made(amount: float)

const SAVE_PATH := "user://cyber_hospital_save.json"
const OFFLINE_CAP_SECONDS := 12.0 * 3600.0
const AUTOSAVE_INTERVAL := 5.0

var credits := 0.0
var departments := {}
var upgrades := {}
var upgrade_levels := {}
var offline_report := {"seconds": 0.0, "earned": 0.0}

var _last_seen := Time.get_unix_time_from_system()
var _save_timer := 0.0


func _ready() -> void:
	_register_departments()
	_register_upgrades()
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


func _register_upgrades() -> void:
	_add_upgrade("neural", "Neural Overclock", "tap_flat", "Each level adds +1 credit per tap.", 25.0, 1.6, 25)
	_add_upgrade("finger", "Finger Interface", "tap_mult", "Doubles all tap income.", 500.0, 3.4, 10)
	_add_dept_upgrade("emergency", "Trauma Stabilizers", 400.0, 3.5)
	_add_dept_upgrade("surgery", "Servo Scalpels", 2500.0, 3.7)
	_add_dept_upgrade("orderly", "Swarm Logic", 12000.0, 4.0)
	_add_dept_upgrade("bionics", "Synth Organs", 70000.0, 4.2)
	_add_dept_upgrade("nanite", "Replicator EU", 300000.0, 4.5)
	_add_dept_upgrade("psych", "Empathy Chip", 2000000.0, 5.0)
	_add_dept_upgrade("organ", "Genome Printer", 10000000.0, 5.5)


func _add_upgrade(id: String, name: String, kind: String, desc: String, cost_base: float, cost_mult: float, max: int) -> void:
	upgrades[id] = {
		"id": id,
		"name": name,
		"kind": kind,
		"desc": desc,
		"cost_base": cost_base,
		"cost_mult": cost_mult,
		"max": max,
		"dept": "",
	}


func _add_dept_upgrade(dept_id: String, name: String, cost_base: float, cost_mult: float, max := 8) -> void:
	var dept: Dictionary = departments[dept_id]
	upgrades[dept_id] = {
		"id": dept_id,
		"name": name,
		"kind": "dept_mult",
		"desc": "Doubles all Cyber %s income." % dept.name,
		"cost_base": cost_base,
		"cost_mult": cost_mult,
		"max": max,
		"dept": dept_id,
	}


func upgrade_level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))


func next_upgrade_cost(id: String) -> float:
	var u: Dictionary = upgrades[id]
	return roundi(u.cost_base * pow(u.cost_mult, upgrade_level(id)))


func buy_upgrade(id: String) -> bool:
	var u: Dictionary = upgrades[id]
	if upgrade_level(id) >= u.max:
		return false
	var cost := next_upgrade_cost(id)
	if credits < cost:
		return false
	credits -= cost
	upgrade_levels[id] = upgrade_level(id) + 1
	credits_changed.emit()
	return true


func tap_value() -> float:
	var total := 1.0 + float(upgrade_level("neural"))
	total *= pow(2.0, upgrade_level("finger"))
	return total


func department_cps(id: String) -> float:
	var d: Dictionary = departments[id]
	return d.base_cps * pow(2.0, upgrade_level(id))


func total_cps() -> float:
	var total := 0.0
	for id in departments:
		var d: Dictionary = departments[id]
		total += department_cps(id) * d.owned
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
	var amount := tap_value()
	add_credits(amount)
	tap_made.emit(amount)


func add_credits(amount: float) -> void:
	if amount == 0.0:
		return
	credits += amount
	credits_changed.emit()


func save_game() -> void:
	var data := {
		"credits": credits,
		"last_seen": _last_seen,
		"departments": {},
		"upgrades": {},
	}
	for id in departments:
		data.departments[id] = departments[id].owned
	for id in upgrades:
		data.upgrades[id] = upgrade_level(id)
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
	_last_seen = float(parsed.get("last_seen", Time.get_unix_time_from_system()))
	var counts: Dictionary = parsed.get("departments", {})
	for id in departments:
		departments[id].owned = int(counts.get(id, 0))
	var ulevels: Dictionary = parsed.get("upgrades", {})
	for id in upgrades:
		upgrade_levels[id] = clampi(int(ulevels.get(id, 0)), 0, upgrades[id].max)
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
