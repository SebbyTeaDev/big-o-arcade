extends "res://levels/level_base.gd"
# Call Tree: the recursive fib call tree, with and without remembering answers.

const AREA := Rect2(40, 184, 1200, 372)
const MAX_N := 10

var n := 5
var memo_on := false
var nodes: Array = []      # {n, kids, depth, cached, x}
var leaves := 0
var max_depth := 0
var built_at := 0.0
var last_shown := 0
var goals := [false, false, false]
var quiz_done := false

var n_label: Label
var memo_btn: Button
var count_l: Label
var insight: Label
var quiz_l: Label
var quiz_btns: Array = []


func _ready() -> void:
	header("Chapter 8: recursion, and why dynamic programming exists")
	UI.button(self, "n - 1", Vector2(40, 92), Vector2(70, 40), _step.bind(-1), 16, tint)
	n_label = UI.label(self, "", Vector2(122, 96), 24, UI.hot(tint, 1.3), 0.0, "title")
	UI.button(self, "n + 1", Vector2(222, 92), Vector2(70, 40), _step.bind(1), 16, tint)
	memo_btn = UI.button(self, "", Vector2(304, 92), Vector2(250, 40), _toggle, 15, tint)
	UI.button(self, "Replay", Vector2(562, 92), Vector2(90, 40), _build, 15, tint)
	quiz_l = UI.label(self, "Bonus: with NO caching, about how many calls does fib(30) make?", Vector2(40, 146), 15, UI.DIM)
	var opts := ["59", "about 1,800", "about 2.7 million"]
	for i in 3:
		quiz_btns.append(UI.button(self, opts[i], Vector2(560 + i * 180, 138), Vector2(170, 36), _quiz.bind(i), 15, tint))
	count_l = UI.label(self, "", Vector2(40, 566), 30, UI.hot(tint, 1.3), 0.0, "title")
	insight = UI.label(self, "", Vector2(40, 612), 15, UI.INK, 780)
	_build()


func _step(d: int) -> void:
	n = clampi(n + d, 2, MAX_N)
	_build()


func _toggle() -> void:
	memo_on = not memo_on
	_build()


func _quiz(i: int) -> void:
	if quiz_done:
		return
	quiz_done = true
	for b in quiz_btns:
		b.disabled = true
		b.modulate = Color(1, 1, 1, 0.4)
	for b in quiz_btns:
		b.visible = false
	if i == 2:
		goals[2] = true
		sfx("ok")
		burst(Vector2(300, 156), UI.ACCENT, 26)
		quiz_l.text = "Right: 2,692,537 calls. With caching, fib(30) takes 59."
		quiz_l.add_theme_color_override("font_color", UI.ACCENT)
	else:
		sfx("bad")
		quiz_l.text = "It is 2,692,537 calls. 59 is the count WITH caching: same answer, 45,000x less work."
		quiz_l.add_theme_color_override("font_color", UI.WARN)
	_award()


func _make(k: int, depth: int, memo: Dictionary) -> int:
	var id := nodes.size()
	var nd := {"n": k, "kids": [], "depth": depth, "cached": false, "x": 0.0}
	nodes.append(nd)
	max_depth = maxi(max_depth, depth)
	if memo_on and k >= 2 and memo.has(k):
		nd["cached"] = true
	elif k >= 2:
		nd["kids"].append(_make(k - 1, depth + 1, memo))
		nd["kids"].append(_make(k - 2, depth + 1, memo))
		memo[k] = true
	if nd["kids"].is_empty():
		nd["x"] = float(leaves)
		leaves += 1
	else:
		nd["x"] = (float(nodes[nd["kids"][0]]["x"]) + float(nodes[nd["kids"][1]]["x"])) / 2.0
	return id


func _calls(k: int) -> int:
	var a := 1
	var b := 1
	for i in k:
		var c := a + b
		a = b
		b = c
	return 2 * a - 1


func _build() -> void:
	nodes = []
	leaves = 0
	max_depth = 0
	_make(n, 0, {})
	built_at = t
	last_shown = 0
	n_label.text = "fib(%d)" % n
	memo_btn.text = "Remember answers: ON" if memo_on else "Remember answers: OFF"
	UI.select(memo_btn, memo_on, tint)
	if n >= MAX_N and not memo_on:
		goals[0] = true
	if memo_on and n >= 8:
		goals[1] = true
	var twos := 0
	for nd in nodes:
		if nd["n"] == 2 and not nd["cached"]:
			twos += 1
	if memo_on:
		insight.text = "Each answer is worked out once and then looked up (hollow rings). The tree collapses to a single spine: %d calls instead of %s. That is dynamic programming: trade a little memory for an exponential amount of time." % [nodes.size(), UI.fmt(_calls(n))]
	else:
		insight.text = "Same colour = same question. fib(2) alone is worked out from scratch %d separate times. Every +1 to n multiplies the work by about 1.6: exponential growth, O(2^n). Try n + 1 a few times, then turn on remembering." % twos
	_award()


func _award() -> void:
	var count := goals.count(true)
	if count > 0:
		finish(count, count == 3)


func _rate() -> float:
	return maxf(nodes.size() / 2.4, 14.0)


func tick(_delta: float) -> void:
	var shown := mini(int((t - built_at) * _rate()), nodes.size())
	if shown > last_shown:
		if shown % 3 == 0 or nodes.size() < 30:
			sfx("tick", 0.6 + 0.12 * float(nodes[shown - 1]["n"]))
		last_shown = shown
	count_l.text = "%s calls" % UI.fmt(shown)


func _p(nd: Dictionary) -> Vector2:
	var step := minf(64.0, (AREA.size.y - 40.0) / maxf(max_depth, 1.0))
	return Vector2(AREA.position.x + (float(nd["x"]) + 0.5) * AREA.size.x / leaves, AREA.position.y + 22.0 + int(nd["depth"]) * step)


func _draw() -> void:
	UI.rrect(self, AREA, Color(0.04, 0.045, 0.075, 0.75), 14.0, Color(1, 1, 1, 0.06), 1.0)
	var shown := mini(int((t - built_at) * _rate()), nodes.size())
	var rad := clampf(AREA.size.x / leaves * 0.42, 3.5, 17.0)
	for i in shown:
		var nd: Dictionary = nodes[i]
		for k in nd["kids"]:
			if k < shown:
				draw_line(_p(nd), _p(nodes[k]), Color(1, 1, 1, 0.22), 1.5, true)
	for i in shown:
		var nd: Dictionary = nodes[i]
		var p := _p(nd)
		var c := UI.hue(float(nd["n"]), 11.0, 0.7, 0.95)
		var fresh := clampf(1.0 - ((t - built_at) * _rate() - i) / 6.0, 0.0, 1.0)
		if nd["cached"]:
			draw_arc(p, rad, 0.0, TAU, 24, UI.hot(c, 1.5), 2.0, true)
		else:
			draw_circle(p, rad + fresh * 3.0, UI.hot(c, 1.0 + fresh * 1.2))
		if rad >= 9.0:
			UI.ctext(self, p, str(nd["n"]), int(rad * 0.95), c if nd["cached"] else UI.BG, "title")
	# mini chart: calls for each n, with and without remembering
	var cx := 860.0
	var cy := 690.0
	UI.text(self, Vector2(cx, 580), "calls needed for fib(n)", 13, UI.DIM)
	var top := float(_calls(MAX_N))
	for k in range(2, MAX_N + 1):
		var x := cx + (k - 2) * 42.0
		var h1 := float(_calls(k)) / top * 92.0
		var h2 := float(2 * k - 1) / top * 92.0
		var here := k == n
		draw_rect(Rect2(x, cy - h1, 16, h1), UI.hot(UI.BAD, 1.5) if (here and not memo_on) else Color(UI.BAD.r, UI.BAD.g, UI.BAD.b, 0.55))
		draw_rect(Rect2(x + 18, cy - maxf(h2, 2.0), 16, maxf(h2, 2.0)), UI.hot(UI.ACCENT, 1.5) if (here and memo_on) else Color(UI.ACCENT.r, UI.ACCENT.g, UI.ACCENT.b, 0.55))
		UI.text(self, Vector2(x, cy + 16), str(k), 12, UI.INK if here else UI.DIM, HORIZONTAL_ALIGNMENT_CENTER, 34.0)
	UI.text(self, Vector2(cx + 150, 580), "red: plain   green: remembered", 12, UI.DIM)


func demo() -> void:
	for i in 3:
		await main.click(Vector2(256, 112))
	await main.wait(2.2)
