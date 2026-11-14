extends RefCounted
# Small animated icons for the menu cards. Each fits a ~56px box centred on c.


static func draw(ci: CanvasItem, kind: String, c: Vector2, t: float, col: Color) -> void:
	var dim := Color(col.r, col.g, col.b, 0.28)
	match kind:
		"search":
			var lo := 0
			var hi := 8
			for s in int(t * 1.4) % 4:
				if s % 2 == 0:
					lo = (lo + hi) >> 1
				else:
					hi = (lo + hi + 1) >> 1
			for i in 8:
				ci.draw_rect(Rect2(c.x - 27 + i * 7, c.y - 13, 5, 26), col if (i >= lo and i < hi) else dim)
		"bigo":
			for k in 3:
				var pts := PackedVector2Array()
				for i in 13:
					var x := i / 12.0
					var y := x * 0.22
					if k == 1:
						y = x * 0.8
					elif k == 2:
						y = x * x * 2.6
					if y > 1.0:
						break
					pts.append(c + Vector2(-26 + x * 52, 24 - y * 48))
				if pts.size() > 1:
					ci.draw_polyline(pts, col if k == int(t * 0.8) % 3 else dim, 2.5, true)
		"list":
			for i in 3:
				var p := c + Vector2(-22 + i * 22, 0)
				ci.draw_rect(Rect2(p - Vector2(7, 7), Vector2(14, 14)), col if i == int(t * 2.0) % 3 else dim)
				if i < 2:
					ci.draw_line(p + Vector2(7, 0), p + Vector2(15, 0), col, 2.0)
		"stack":
			for i in 4:
				var off := -absf(sin(t * 2.2)) * 12.0 if i == 3 else 0.0
				ci.draw_rect(Rect2(c.x - 20, c.y + 14 - i * 11 + off, 40, 8), col if i == 3 else dim)
		"sort":
			var perm := [5, 2, 7, 1, 8, 3, 6, 4]
			var k := 0.5 - 0.5 * cos(t * 0.9)
			for i in 8:
				var h := lerpf(float(perm[i]), float(i + 1), k) * 6.0
				ci.draw_rect(Rect2(c.x - 27 + i * 7, c.y + 24 - h, 5, h), col.lerp(Color.WHITE, 0.25 * k))
		"rec":
			_branch(ci, c + Vector2(0, 24), -PI / 2.0, 17.0, 4, col, t)
		"tree":
			var pts := [Vector2(0, -20), Vector2(-16, 0), Vector2(16, 0), Vector2(-24, 20), Vector2(-8, 20), Vector2(8, 20), Vector2(24, 20)]
			var path: Array = [[0, 1, 3], [0, 1, 4], [0, 2, 5], [0, 2, 6]][int(t * 0.9) % 4]
			for i in range(1, 7):
				var par := (i - 1) >> 1
				ci.draw_line(c + pts[par], c + pts[i], col if (path.has(i) and path.has(par)) else dim, 2.0, true)
			for i in 7:
				ci.draw_circle(c + pts[i], 4.5, col if path.has(i) else dim)
		"hash":
			var blink := int(t * 2.5) % 8
			for i in 8:
				var on := (i * 5 + 3) % 8 < 5
				var r := Rect2(c.x - 27 + (i % 4) * 14, c.y - 13 + (i >> 2) * 14, 11, 11)
				ci.draw_rect(r, col if i == blink else (dim if on else Color(col.r, col.g, col.b, 0.1)))
		"heap":
			var idx := 0
			for row in 3:
				for k in row + 1:
					var p := c + Vector2((k - row * 0.5) * 20.0, -18 + row * 18)
					ci.draw_circle(p, 6.5 - row * 1.2 + (sin(t * 3.0) * 1.2 if idx == 0 else 0.0), col if idx == 0 else dim)
					idx += 1
		"race":
			for i in 3:
				var w := fposmod(t * (0.9 - i * 0.28), 1.0) * 52.0
				ci.draw_rect(Rect2(c.x - 26, c.y - 16 + i * 13, 52, 7), Color(col.r, col.g, col.b, 0.12))
				ci.draw_rect(Rect2(c.x - 26, c.y - 16 + i * 13, w, 7), col if i == 0 else dim)
		"graph":
			var n := [Vector2(-22, -8), Vector2(-4, -20), Vector2(20, -10), Vector2(-10, 16), Vector2(16, 18)]
			var e := [[0, 1], [1, 2], [0, 3], [3, 4], [2, 4], [1, 3]]
			var live := int(t * 2.0) % e.size()
			for i in e.size():
				ci.draw_line(c + n[e[i][0]], c + n[e[i][1]], col if i == live else dim, 2.0, true)
			for p in n:
				ci.draw_circle(c + p, 4.5, col)
		"maze":
			var walls := [[0, 0, 3, 0], [0, 1, 0, 3], [1, 1, 3, 1], [1, 2, 1, 3], [2, 2, 4, 2], [3, 3, 4, 3], [0, 4, 2, 4], [4, 0, 4, 1]]
			for w in walls:
				ci.draw_line(c + Vector2(-26 + w[0] * 13, -26 + w[1] * 13), c + Vector2(-26 + w[2] * 13, -26 + w[3] * 13), dim, 2.0)
			var track := [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(2, 2), Vector2(3, 2), Vector2(3, 3)]
			var q: Vector2 = track[int(t * 3.0) % track.size()]
			ci.draw_circle(c + Vector2(-19.5 + q.x * 13, -19.5 + q.y * 13), 4.0, col)
		"boss":
			ci.draw_rect(Rect2(c.x - 26, c.y - 20, 36, 20), dim)
			ci.draw_rect(Rect2(c.x - 8, c.y + 4, 34, 18), col)
			for i in 3:
				ci.draw_circle(c + Vector2(0 + i * 9, 13), 2.0 + (1.2 if i == int(t * 3.0) % 3 else 0.0), Color(0, 0, 0, 0.6))
		"sheet":
			for i in 4:
				for j in 3:
					ci.draw_rect(Rect2(c.x - 26 + j * 18, c.y - 22 + i * 12, 15, 8), col if (i + j) % 4 == int(t) % 4 else dim)


static func _branch(ci: CanvasItem, p: Vector2, ang: float, length: float, depth: int, col: Color, t: float) -> void:
	if depth == 0:
		return
	var q := p + Vector2(cos(ang), sin(ang)) * length
	ci.draw_line(p, q, Color(col.r, col.g, col.b, 0.3 + 0.17 * depth), 2.0, true)
	var sway := 0.5 + 0.12 * sin(t * 1.3 + depth)
	_branch(ci, q, ang - sway, length * 0.72, depth - 1, col, t)
	_branch(ci, q, ang + sway, length * 0.72, depth - 1, col, t)
