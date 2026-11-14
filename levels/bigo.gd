extends "res://levels/level_base.gd"
# Count the Loops: read a snippet, pick its Big-O, see it on the growth chart and as a pile of steps.

const OPTS := ["O(1)", "O(log n)", "O(n)", "O(n log n)", "O(n²)", "O(2^n)"]
const AT_1000 := ["1 step", "about 10 steps", "1,000 steps", "about 10,000 steps", "1,000,000 steps", "a number with 302 digits"]
const NAMES := ["constant", "logarithmic", "linear", "linearithmic", "quadratic", "exponential"]
const COLORS := [UI.ACCENT, UI.BLUE, UI.INK, UI.PURPLE, UI.WARN, UI.BAD]
const CHART := Rect2(720, 124, 520, 232)

const Traces = preload("res://traces.gd")

const QS := [
	{"trace": "loop", "a": 2,
		"why": "One pass over n items, constant work per item. n steps."},
	{"trace": "indexof", "a": 4,
		"why": "indexOf is a hidden loop: it scans the array. A scan inside a pass is n x n. Library calls are where most accidental O(n²) lives."},
	{"trace": "first", "a": 0,
		"why": "Jumping to an index is one step whether the array holds 10 items or 10 billion."},
	{"trace": "bsearch", "a": 1,
		"why": "Each trip through the loop halves the remaining range. You can only halve n about log2(n) times."},
	{"trace": "nested", "a": 4,
		"why": "Nested loops multiply: n times around the outside, n times inside each."},
	{"trace": "doubling", "a": 1,
		"why": "i doubles each time (1, 2, 4, 8...). Doubling up to n takes as many steps as halving down from n: log n."},
	{"trace": "sethas", "a": 2,
		"why": "Set.has is a hash lookup: about 1 step. So this is one pass, O(n). Swap the Set for array.includes and the same code becomes O(n²)."},
	{"trace": "twoloops", "a": 2,
		"why": "Loops one AFTER another add: n + n = 2n. Big-O drops constant factors, so 2n is still O(n). Only nesting multiplies."},
	{"trace": "innerconst", "a": 2,
		"why": "The inner loop runs 3 times (red, green, blue) however many pixels there are. 3n is O(n). A nested loop is only quadratic if BOTH bounds grow with n."},
	{"trace": "triangular", "a": 4,
		"why": "The inner loop shrinks, so the total is n(n-1)/2: every pair once. Half of n² is still O(n²). Constants drop."},
	{"trace": "sortloop", "a": 3,
		"why": "A good comparison sort costs n log n. The loop after it is only n, and the bigger term wins: O(n log n)."},
	{"trace": "nqueries", "a": 3,
		"why": "n queries, each costing log n. Multiply: n log n."},
	{"trace": "dedupe", "a": 4,
		"why": "includes scans out, which can grow to n items. That is the classic slow de-dupe. A Set makes it O(n)."},
	{"trace": "fib", "a": 5,
		"why": "Each call spawns two more, so the call tree doubles at every level. fib(50) is already billions of calls. Remembering answers (Call Tree level) makes it O(n)."},
]

var qi := 0
var score := 0
var answered := -1
var answer_at := 0.0
var over := false
var code_label: RichTextLabel
var progress: Label
var feedback: Label
var at1000: Label
var buttons: Array = []
var next_btn: Button
var step_btn: Button


func _ready() -> void:
	header("Chapter 6: Big-Oh rules. How many steps as n grows?")
	progress = UI.label(self, "", Vector2(40, 90), 17, UI.DIM)
	code_label = UI.code(self, Rect2(40, 124, 640, 232), 18)
	for i in OPTS.size():
		buttons.append(UI.button(self, OPTS[i], Vector2(40 + (i % 3) * 216, 372 + (i / 3) * 56), Vector2(208, 48), _answer.bind(i), 20, COLORS[i]))
	feedback = UI.label(self, "", Vector2(40, 494), 17, UI.INK, 640)
	at1000 = UI.label(self, "", Vector2(720, 626), 17, UI.WARN, 340)
	next_btn = UI.button(self, "Next", Vector2(1080, 646), Vector2(160, 48), _next, 18, tint)
	step_btn = UI.button(self, "Step through it", Vector2(500, 314), Vector2(170, 34), _open_stepper, 14, tint)
	_show()


func _open_stepper() -> void:
	open_code([QS[qi]["trace"]], answered >= 0)


func _unhandled_key_input(event: InputEvent) -> void:
	super._unhandled_key_input(event)
	if event is InputEventKey and event.pressed and overlay == null and not over:
		var k: int = event.keycode - KEY_1
		if k >= 0 and k < OPTS.size():
			_answer(k)


func _show() -> void:
	answered = -1
	var q: Dictionary = QS[qi]
	progress.text = "Snippet %d of %d          Score: %d" % [qi + 1, QS.size(), score]
	code_label.text = UI.highlight(Traces.code_for(q["trace"]))
	step_btn.visible = true
	feedback.text = "n is the size of the input. Pick how the step count grows (keys 1 to 6 work too), or step through the code first."
	feedback.add_theme_color_override("font_color", UI.DIM)
	at1000.text = ""
	next_btn.visible = false
	for b in buttons:
		b.disabled = false
		b.modulate = Color.WHITE


func _answer(i: int) -> void:
	if answered >= 0 or over:
		return
	answered = i
	answer_at = t
	var q: Dictionary = QS[qi]
	var a: int = q["a"]
	for b in buttons:
		b.disabled = true
		b.modulate = Color(1, 1, 1, 0.4)
	buttons[a].modulate = UI.hot(UI.ACCENT, 1.5)
	if i == a:
		score += 1
		sfx("ok")
		burst(buttons[a].position + buttons[a].size / 2.0, UI.ACCENT, 26)
		feedback.text = "Correct: %s.  %s" % [OPTS[a], q["why"]]
		feedback.add_theme_color_override("font_color", UI.ACCENT)
	else:
		buttons[i].modulate = UI.hot(UI.BAD, 1.3)
		sfx("bad")
		shake()
		feedback.text = "It is %s, not %s.  %s" % [OPTS[a], OPTS[i], q["why"]]
		feedback.add_theme_color_override("font_color", UI.WARN)
	at1000.text = "%s is %s growth. At n = 1,000 that is %s." % [OPTS[a], NAMES[a], AT_1000[a]]
	progress.text = "Snippet %d of %d          Score: %d" % [qi + 1, QS.size(), score]
	next_btn.text = "Next" if qi < QS.size() - 1 else "Finish"
	next_btn.visible = true


func _next() -> void:
	if over:
		over = false
		qi = 0
		score = 0
		for b in buttons:
			b.visible = true
		_show()
		return
	if qi < QS.size() - 1:
		qi += 1
		_show()
		return
	over = true
	finish(3 if score >= QS.size() - 1 else (2 if score >= 10 else 1))
	code_label.text = "Score: %d / %d\n\nThe rules you just used:\n  loops in a row      -> add\n  loops nested        -> multiply\n  halving / doubling  -> log n\n  hash lookup         -> 1\n  drop constants, keep the biggest term" % [score, QS.size()]
	feedback.text = "O(1) < O(log n) < O(n) < O(n log n) < O(n²) < O(2^n). Anything left of n² is usually fine. n² hurts past a few thousand items. 2^n is only for tiny inputs."
	feedback.add_theme_color_override("font_color", UI.INK)
	at1000.text = ""
	for b in buttons:
		b.visible = false
	step_btn.visible = false
	next_btn.text = "Play again"
	answered = -1


func _f(k: int, n: float) -> float:
	var lg := log(n) / log(2.0)
	match k:
		0: return 1.0
		1: return maxf(lg, 0.0)
		2: return n
		3: return n * lg
		4: return n * n
	return pow(2.0, n)


func _draw() -> void:
	UI.rrect(self, CHART, Color("0f111b"), 12.0, Color(1, 1, 1, 0.07), 1.0)
	UI.text(self, CHART.position + Vector2(14, 22), "steps (up) as n grows (right)", 13, UI.DIM)
	var max_n := 30.0
	var max_y := 220.0
	var hot_k := -1
	if answered >= 0:
		hot_k = QS[qi]["a"]
	for k in OPTS.size():
		var pts := PackedVector2Array()
		var n := 1.0
		while n <= max_n:
			var v := _f(k, n)
			if v > max_y:
				break
			pts.append(Vector2(CHART.position.x + 16 + (n - 1) / (max_n - 1) * (CHART.size.x - 120),
				CHART.end.y - 14 - v / max_y * (CHART.size.y - 50)))
			n += 0.25
		var c: Color = COLORS[k]
		if hot_k >= 0 and k != hot_k:
			c = Color(c.r, c.g, c.b, 0.2)
		elif k == hot_k:
			c = UI.hot(c, 1.7)
		if pts.size() > 1:
			draw_polyline(pts, c, 5.0 if k == hot_k else 2.0, true)
			var last := pts[pts.size() - 1]
			UI.text(self, last + Vector2(8, 16 if k == 0 else (-2 if k == 1 else 6)), OPTS[k], 16 if k == hot_k else 13, c)
	if hot_k < 0:
		return
	# The same growth as piles of dots: one dot per step.
	UI.text(self, Vector2(720, 384), "One dot per step, for n = 4, 8 and 16", 13, UI.DIM)
	var shown := int((t - answer_at) * 420.0)
	var ns := [4.0, 8.0, 16.0]
	var c2: Color = UI.hot(COLORS[hot_k], 1.5)
	for j in 3:
		var total := int(round(_f(hot_k, ns[j])))
		var ox := 720.0 + j * 176.0
		UI.text(self, Vector2(ox, 408), "n = %d:  %s" % [int(ns[j]), UI.fmt(total)], 15, UI.INK)
		var cap := mini(total, 460)
		for d in mini(cap, shown):
			draw_rect(Rect2(ox + (d % 23) * 7, 418 + (d / 23) * 7, 5, 5), c2)
		if total > cap and shown > cap:
			UI.text(self, Vector2(ox, 580), "...and %s more" % UI.fmt(total - cap), 13, UI.BAD)
		shown -= cap


func demo() -> void:
	qi = 4
	_show()
	await main.click(buttons[4].position + Vector2(40, 20))
	await main.wait(1.5)
