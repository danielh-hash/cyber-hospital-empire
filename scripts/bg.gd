extends Control

const SKY_TOP := Color(0.045, 0.075, 0.16)
const SKY_BOT := Color(0.30, 0.48, 0.95)
const SKYLINE := Color(0.05, 0.06, 0.13)
const BUILDING := Color(0.93, 0.95, 0.99)
const CROSS := Color(0.95, 0.30, 0.35)
const CROSS_BG := Color(0.06, 0.14, 0.30)


func _draw() -> void:
	var w := size.x
	var h := size.y
	_draw_sky(w, h)
	_draw_sun(w, h)
	_draw_clouds(w, h)
	_draw_skyline(w, h)
	_draw_hospital(w, h)
	_draw_ground(w, h)


func _draw_sky(w: float, h: float) -> void:
	var strips := 28
	for i in strips:
		var t := float(i) / float(strips - 1)
		var band_h := h * 0.62 / float(strips)
		draw_rect(Rect2(0.0, i * band_h, w, band_h + 1.0), SKY_TOP.lerp(SKY_BOT, t))


func _draw_sun(w: float, h: float) -> void:
	var c := Vector2(w * 0.5, h * 0.20)
	var r := h * 0.10
	draw_circle(c, r * 1.55, Color(0.95, 0.75, 0.35, 0.20))
	draw_circle(c, r * 1.15, Color(0.98, 0.80, 0.42, 0.45))
	draw_circle(c, r, Color(1.0, 0.90, 0.55))


func _draw_clouds(w: float, h: float) -> void:
	var cloud := Color(0.93, 0.95, 1.0, 0.90)
	_puff(w * 0.16, h * 0.34, h * 0.030, cloud)
	_puff(w * 0.30, h * 0.40, h * 0.022, Color(0.85, 0.90, 1.0, 0.75))
	_puff(w * 0.80, h * 0.30, h * 0.026, cloud)
	_puff(w * 0.70, h * 0.44, h * 0.018, Color(0.85, 0.90, 1.0, 0.70))


func _puff(x: float, y: float, r: float, c: Color) -> void:
	draw_circle(Vector2(x, y), r, c)
	draw_circle(Vector2(x + r * 1.2, y + r * 0.25), r * 0.8, c)
	draw_circle(Vector2(x - r * 1.2, y + r * 0.25), r * 0.8, c)


func _draw_skyline(w: float, h: float) -> void:
	var base := h * 0.62
	var band_color := Color(0.0, 0.0, 0.0, 0.28)
	draw_rect(Rect2(0.0, base, w, h * 0.12), band_color)
	var seed := 7
	var x := -20.0
	while x < w:
		var bw := 40.0 + float((seed * 31) % 55)
		var bh := 60.0 + float((seed * 17) % 90)
		draw_rect(Rect2(x, base + h * 0.12 - bh, bw, bh), SKYLINE)
		_draw_windows(x, base + h * 0.12 - bh, bw, bh)
		seed += 3
		x += bw + 6.0


func _draw_windows(x: float, y: float, bw: float, bh: float) -> void:
	var lit := Color(0.55, 0.95, 1.0, 0.85)
	var lit2 := Color(1.0, 0.85, 0.45, 0.8)
	var col := 0
	var wx := x + 6.0
	while wx < x + bw - 8.0:
		var wy := y + 8.0
		while wy < y + bh - 10.0:
			var c: Color
			if (col * 37 + int(wy)) % 7 == 0:
				c = lit
			elif (col * 13 + int(wy)) % 11 == 0:
				c = lit2
			else:
				c = Color(0.1, 0.12, 0.24)
			draw_rect(Rect2(wx, wy, 5.0, 7.0), c)
			wy += 14.0
		col += 1
		wx += 11.0


func _draw_hospital(w: float, h: float) -> void:
	var bw := w * 0.46
	var bx := (w - bw) / 2.0
	var roof_h := h * 0.06
	var gy := h * 0.74
	var body_y := gy - roof_h
	draw_rect(Rect2(bx, body_y, bw, roof_h), Color(0.08, 0.16, 0.34))
	var cross_box := 28.0
	var cx := bx + bw / 2.0 - cross_box / 2.0
	var cy := body_y - cross_box + 6.0
	draw_rect(Rect2(cx, cy, cross_box, cross_box), CROSS_BG)
	draw_rect(Rect2(cx + 8.0, cy + 2.0, 12.0, cross_box - 4.0), CROSS)
	draw_rect(Rect2(cx + 2.0, cy + 8.0, cross_box - 4.0, 12.0), CROSS)
	draw_rect(Rect2(bx, gy, bw, h * 0.10), BUILDING)
	draw_rect(Rect2(bx + 6.0, gy + 8.0, bw - 12.0, h * 0.05), Color(0.35, 0.75, 0.92))
	draw_circle(Vector2(bx + bw / 2.0, gy + h * 0.10), h * 0.055, Color(0.06, 0.16, 0.30))
	var glass := Color(0.30, 0.55, 0.88, 0.9)
	var door_w := h * 0.07
	var dx := bx + bw / 2.0 - door_w / 2.0
	draw_rect(Rect2(dx, gy + h * 0.10 - 6.0, door_w, h * 0.06), Color(0.75, 0.93, 1.0))
	var row := 0
	while row < 3:
		var xx := bx + 10.0
		while xx < bx + bw - 16.0:
			draw_rect(Rect2(xx, gy - 6.0 - (row + 1) * 22.0, 26.0, 14.0), glass)
			xx += 34.0
		row += 1


func _draw_ground(w: float, h: float) -> void:
	var gy := h * 0.84
	draw_rect(Rect2(0.0, gy, w, h), Color(0.02, 0.03, 0.07))
	draw_rect(Rect2(0.0, gy - 8.0, w, 8.0), Color(0.42, 0.47, 0.60))
	var step := 52.0
	var x := 10.0
	while x < size.x:
		draw_rect(Rect2(x, gy + h * 0.045, step * 0.5, 6.0), Color(0.85, 0.90, 1.0, 0.35))
		x += step