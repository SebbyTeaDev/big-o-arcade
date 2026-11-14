extends "res://levels/level_base.gd"
# Maze Forge: build a maze with union-find. Each colour is one set of connected cells.

const GW := 24
const GH := 12
const CS := 39.0
const X0 := 40.0
const Y0 := 208.0
const PX := 1024.0

var edges: Array = []
var ei := 0
var par_s: Array = []
var size_s: Array = []
var par_n: Array = []
var hops_s := 0
var hops_n := 0
var sets := 0
var open := {}
var shown: Array = []
var running := false
var fast := false
var acc := 0.0
var last_edge: Array = []
var last_removed := false
var last_at := -9.0
var q1 := -1
var q2 := -1
var path: Array = []
var path_at := 0.0
var goals := [false, false, false]

var msg: Label
var run_btn: Button
var fast_btn: Button


func _ready() -> void:
	header("Chapter 24: the disjoint set class. Two questions only: same set? merge them.")
	UI.button(self, "Step", Vector2(40, 92), Vector2(80, 40), _step_btn, 15, tint)
	run_btn = UI.button(self, "Run", Vector2(128, 92), Vector2(90, 40), _toggle_run, 15, tint)
	fast_btn = UI.button(self, "Speed: slow", Vector2(226, 92), Vector2(130, 40), _toggle_fast, 15, tint)
	UI.button(self, "New maze", Vector2(364, 92), Vector2(110, 40), _new, 15, tint)
	UI.button(self, "Solve it", Vector2(482, 92), Vector2(100, 40), _solve, 15, tint)
	msg = UI.label(self, "", Vector2(40, 138), 14, UI.INK, 960)
	_new()


func _new() -> void:
	var n := GW * GH
	par_s = []
	size_s = []
	par_n = []
	shown = []
	for i in n:
		par_s.append(i)
		size_s.append(1)
		par_n.append(i)
		shown.append(_set_col(i))
	edges = []
	for i in n:
		if i % GW < GW - 1:
			edges.append([i, i + 1, i * 2])
		if i / GW < GH - 1:
			edges.append([i, i + GW, i * 2 + 1])
	edges.shuffle()
	ei = 0
	hops_s = 0
	hops_n = 0
	sets = n
	open = {}
	running = false
	path = []
	q1 = -1
	q2 = -1
	last_edge = []
	run_btn.text = "Run"
	msg.text = "Every cell starts as its own set (its own colour). Pick a random wall: if the two cells beside it are in DIFFERENT sets, knock it down and merge them. If they are already in the same set, keep the wall, or you would create a loop. Press Step a few times, then Run."


func _set_col(root: int) -> Color:
	return Color.from_hsv(fposmod(root * 0.6180339, 1.0), 0.55, 0.62)


func _root(x: int) -> int:
	while par_s[x] != x:
		x = par_s[x]
	return x


func _find_s(x: int) -> int:
	var r := x
	while par_s[r] != r:
		r = par_s[r]
		hops_s += 1
	while par_s[x] != r:
		var nx: int = par_s[x]
		par_s[x] = r
		x = nx
	return r


func _find_n(x: int) -> int:
	while par_n[x] != x:
		x = par_n[x]
		hops_n += 1
	return x


func _step() -> void:
	if sets <= 1 or ei >= edges.size():
		return
	var e: Array = edges[ei]
	ei += 1
	var ra := _find_s(e[0])
	var rb := _find_s(e[1])
	var na := _find_n(e[0])
	var nb := _find_n(e[1])
	last_edge = e
	last_at = t
	if ra != rb:
		if size_s[ra] < size_s[rb]:
			var tmp := ra
			ra = rb
			rb = tmp
		par_s[rb] = ra
		size_s[ra] += size_s[rb]
		par_n[na] = nb
		open[e[2]] = true
		sets -= 1
		last_removed = true
		if not fast or sets % 6 == 0:
			sfx("tick", 0.6 + 1.6 * (1.0 - float(sets) / (GW * GH)))
	else:
		last_removed = false
	if sets == 1:
		running = false
		run_btn.text = "Run"
		goals[0] = true
		q1 = -1
		q2 = -1
		sfx("ok")
		burst(Vector2(X0 + GW * CS / 2.0, Y0 + GH * CS / 2.0), tint, 50)
		msg.text = "One set left: every cell can reach every other cell, and because we never joined two cells that were already connected, there is exactly ONE route between any two. That is a perfect maze. Press Solve it."
		_award()


func _award() -> void:
	var count := goals.count(true)
	if count > 0:
		finish(count, count == 3)


func _step_btn() -> void:
	_step()
	if sets > 1 and not last_edge.is_empty():
		msg.text = ("Different sets, so the wall comes down and the two sets merge into one colour. %d sets left." % sets) if last_removed else "Same set already (same colour): those cells are connected by some other route. The wall stays."


func _toggle_run() -> void:
	if sets <= 1:
		return
	running = not running
	run_btn.text = "Pause" if running else "Run"
	if running:
		msg.text = "Watch the colours merge. While it runs (or after pausing), click any two cells to ask the union-find question: are these connected yet?"


func _toggle_fast() -> void:
	fast = not fast
	fast_btn.text = "Speed: fast" if fast else "Speed: slow"


func tick(delta: float) -> void:
	if running:
		acc += delta * (120.0 if fast else 14.0)
		var k := int(acc)
		acc -= k
		for i in k:
			_step()
	var f := 1.0 - exp(-delta * 7.0)
	var done := sets == 1
	for i in GW * GH:
		var target := Color(0.09, 0.105, 0.17) if done else _set_col(_root(i))
		shown[i] = shown[i].lerp(target, f)


func _cell_at(p: Vector2) -> int:
	var x := int((p.x - X0) / CS)
	var y := int((p.y - Y0) / CS)
	if p.x < X0 or p.y < Y0 or x >= GW or y >= GH:
		return -1
	return y * GW + x


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := _cell_at(event.position)
		if c < 0:
			return
		if q1 == -1 or q2 != -1:
			q1 = c
			q2 = -1
			sfx("click")
			msg.text = "First cell picked. Click a second cell to ask: are these two connected?"
		else:
			q2 = c
			var same := _root(q1) == _root(q2)
			sfx("ok" if same else "pop")
			msg.text = ("Connected: both cells trace back to the same root, so they are in the same set." if same else "Not connected yet: they trace back to different roots.") + " Answering this took a few pointer hops, not a search of the maze. That is the whole point of union-find."
			if sets > 1:
				goals[1] = true
				_award()


func _solve() -> void:
	if sets > 1:
		sfx("bad")
		msg.text = "The maze is not finished: there are still %d separate sets, so some cells cannot reach each other." % sets
		return
	var n := GW * GH
	var prev: Array = []
	for i in n:
		prev.append(-2)
	var q := [0]
	prev[0] = -1
	var head := 0
	while head < q.size():
		var u: int = q[head]
		head += 1
		if u == n - 1:
			break
		var cand := []
		if u % GW < GW - 1 and open.has(u * 2):
			cand.append(u + 1)
		if u / GW < GH - 1 and open.has(u * 2 + 1):
			cand.append(u + GW)
		if u % GW > 0 and open.has((u - 1) * 2):
			cand.append(u - 1)
		if u >= GW and open.has((u - GW) * 2 + 1):
			cand.append(u - GW)
		for v in cand:
			if prev[v] == -2:
				prev[v] = u
				q.append(v)
	path = []
	var w: int = n - 1
	while w >= 0:
		path.append(w)
		w = prev[w]
	path.reverse()
	path_at = t
	goals[2] = true
	sfx("ok")
	msg.text = "Solved with breadth-first search from the top-left to the bottom-right: %d steps. Union-find built the maze; a graph search walks it." % (path.size() - 1)
	_award()


func _c(i: int) -> Vector2:
	return Vector2(X0 + (i % GW + 0.5) * CS, Y0 + (i / GW + 0.5) * CS)


func _draw() -> void:
	var r1 := _root(q1) if q1 >= 0 else -1
	var r2 := _root(q2) if q2 >= 0 else -1
	for i in GW * GH:
		var r := Rect2(X0 + (i % GW) * CS, Y0 + (i / GW) * CS, CS, CS)
		var c: Color = shown[i]
		if q1 >= 0:
			var ri := _root(i)
			if ri == r1 or (q2 >= 0 and ri == r2):
				c = c.lightened(0.35)
		draw_rect(r, c)
	# walls
	var wall := Color(0.93, 0.94, 0.97, 0.9)
	for i in GW * GH:
		var x := X0 + (i % GW) * CS
		var y := Y0 + (i / GW) * CS
		if i % GW < GW - 1 and not open.has(i * 2):
			draw_line(Vector2(x + CS, y), Vector2(x + CS, y + CS), wall, 2.0)
		if i / GW < GH - 1 and not open.has(i * 2 + 1):
			draw_line(Vector2(x, y + CS), Vector2(x + CS, y + CS), wall, 2.0)
	draw_rect(Rect2(X0, Y0, GW * CS, GH * CS), wall, false, 3.0)
	# the wall just considered
	var flash := 1.0 - (t - last_at) / 0.6
	if flash > 0.0 and not last_edge.is_empty():
		var i: int = last_edge[0]
		var x := X0 + (i % GW) * CS
		var y := Y0 + (i / GW) * CS
		var col := UI.ACCENT if last_removed else UI.BAD
		col = Color(col.r * 2.2, col.g * 2.2, col.b * 2.2, flash)
		if int(last_edge[2]) % 2 == 0:
			draw_line(Vector2(x + CS, y), Vector2(x + CS, y + CS), col, 5.0)
		else:
			draw_line(Vector2(x, y + CS), Vector2(x + CS, y + CS), col, 5.0)
	for q in [q1, q2]:
		if q >= 0:
			draw_arc(_c(q), 13.0, 0.0, TAU, 24, UI.hot(Color.WHITE, 2.4), 3.0, true)
	if path.size() > 1:
		var n := mini(path.size(), int((t - path_at) * 90.0) + 2)
		var pts := PackedVector2Array()
		for i in n:
			pts.append(_c(path[i]))
		draw_polyline(pts, UI.hot(UI.WARN, 2.4), 5.0, true)
		draw_circle(_c(0), 9.0, UI.hot(UI.ACCENT, 2.0))
		draw_circle(_c(GW * GH - 1), 9.0, UI.hot(UI.WARN, 2.0))
	# side panel
	UI.text(self, Vector2(PX, 196), "SETS REMAINING", 13, UI.DIM)
	UI.text(self, Vector2(PX, 256), str(sets), 58, UI.hot(tint, 1.4), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	UI.text(self, Vector2(PX, 292), "walls removed: %d" % (GW * GH - sets), 14, UI.INK)
	UI.text(self, Vector2(PX, 312), "walls tested: %d" % ei, 14, UI.INK)
	UI.text(self, Vector2(PX, 364), "POINTER HOPS IN find()", 13, UI.DIM)
	var top := float(maxi(maxi(hops_n, hops_s), 1))
	UI.text(self, Vector2(PX, 392), "Naive linking", 14, UI.INK)
	UI.rrect(self, Rect2(PX, 400, 216, 14), UI.PANEL, 7.0)
	UI.rrect(self, Rect2(PX, 400, 216.0 * hops_n / top, 14), UI.hot(UI.BAD, 1.4), 7.0)
	UI.text(self, Vector2(PX, 434), UI.fmt(hops_n), 18, UI.hot(UI.BAD, 1.3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	UI.text(self, Vector2(PX, 468), "Union by size + path compression", 14, UI.INK)
	UI.rrect(self, Rect2(PX, 476, 216, 14), UI.PANEL, 7.0)
	UI.rrect(self, Rect2(PX, 476, 216.0 * hops_s / top, 14), UI.hot(UI.ACCENT, 1.5), 7.0)
	UI.text(self, Vector2(PX, 510), UI.fmt(hops_s), 18, UI.hot(UI.ACCENT, 1.3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	draw_multiline_string(UI.font(), Vector2(PX, 548), "Each set is a tree of parent pointers. Two cheap tricks (hang the small tree under the big one; re-point everything you pass at the root) keep those trees almost flat, so each question is nearly O(1).", HORIZONTAL_ALIGNMENT_LEFT, 216.0, 13, 8, UI.DIM)


func demo() -> void:
	await main.click(Vector2(290, 112))
	await main.click(Vector2(172, 112))
	await main.wait(1.2)
	await main.click(_c(30))
	await main.click(_c(31))
	await main.wait(4.2)
	await main.click(Vector2(530, 112))
	await main.wait(1.6)
