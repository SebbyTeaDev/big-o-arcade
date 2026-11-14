extends "res://levels/level_base.gd"
# Shift or Relink: the same operation on an array and on a linked list, one step at a time.

const N := 10
const DT := 0.22
const CW := 80.0
const CGAP := 4.0
const AX := 70.0
const AY := 232.0
const LX := 100.0
const LSTEP := 100.0
const LY := 468.0
const OPTS := ["Array", "Linked list", "About the same"]

const QS := [
	{"q": "Get the item at position 7.", "kind": "get", "pos": 7,
		"why": "An array is one contiguous block, so position 7 is simple arithmetic: start + 7 x item size. One step. The list has no addresses to compute, only 'next' pointers, so it must hop through 7 nodes.",
		"big": "At a million items: array 1 step, list up to 1,000,000 hops."},
	{"q": "Insert a new item at the FRONT.", "kind": "insert", "pos": 0,
		"why": "The array has to slide every existing item one slot right to open a gap. The list just points the new node at the old head. This is why arr.unshift() in a loop is O(n²).",
		"big": "At a million items: array 1,000,000 shifts, list 1 step."},
	{"q": "Insert a new item in the MIDDLE (position 5).", "kind": "insert", "pos": 5,
		"why": "A trap. The list's relink is one step, but it has to WALK to the middle first. The array jumps there instantly but then shifts half the items. Both are O(n). The list only wins if you already hold a pointer to the spot.",
		"big": "At a million items: both around 500,000 steps."},
	{"q": "Append a new item at the END. The array has spare room.", "kind": "insert", "pos": 10,
		"why": "With spare capacity the array writes into the next free slot. The list keeps a tail pointer and links one node. Both are one step.",
		"big": "At a million items: 1 step each."},
	{"q": "Remove the FIRST item.", "kind": "remove", "pos": 0,
		"why": "The array closes the gap by sliding everything left. The list moves its head pointer to the second node. This is why a queue built on arr.shift() is slow, and why real queues use a linked list or a circular buffer.",
		"big": "At a million items: array 999,999 shifts, list 1 step."},
	{"q": "Append one more item, but the array is completely FULL.", "kind": "grow", "pos": 10,
		"why": "The array must allocate a bigger block and copy everything over. Painful once, but it DOUBLES its capacity, so the next n appends are free. Averaged out, append still costs about 1 step: that is what 'amortized O(1)' means (it is how vector push_back works).",
		"big": "This one append: array n copies, list 1. Averaged over many appends: both about 1."},
]

var qi := 0
var score := 0
var picked := -1
var anim_at := 0.0
var a_total := 1
var l_total := 1
var revealed := false
var over := false

var q_label: Label
var verdict: Label
var why: Label
var buttons: Array = []
var next_btn: Button


func _ready() -> void:
	header("Chapters 1 and 17: one contiguous block vs nodes joined by pointers")
	q_label = UI.label(self, "", Vector2(40, 88), 22, UI.INK, 1200, "title")
	UI.label(self, "Which structure does it in fewer steps?", Vector2(40, 138), 15, UI.DIM)
	for i in 3:
		buttons.append(UI.button(self, OPTS[i], Vector2(360 + i * 200, 128), Vector2(190, 42), _pick.bind(i), 16, tint))
	verdict = UI.label(self, "", Vector2(40, 590), 19, UI.WARN, 1020, "title")
	why = UI.label(self, "", Vector2(40, 620), 15, UI.INK, 1020)
	next_btn = UI.button(self, "Next", Vector2(1090, 646), Vector2(150, 48), _next, 18, tint)
	_show()


func _show() -> void:
	var q: Dictionary = QS[qi]
	picked = -1
	revealed = false
	q_label.text = "%d / %d   %s" % [qi + 1, QS.size(), q["q"]]
	verdict.text = ""
	why.text = ""
	next_btn.visible = false
	for b in buttons:
		b.disabled = false
		b.modulate = Color.WHITE
	var p: int = q["pos"]
	match q["kind"]:
		"get":
			a_total = 1
			l_total = maxi(p, 1)
		"insert":
			a_total = (N - p) + 1
			l_total = 1 if (p == 0 or p == N) else p
		"remove":
			a_total = N - 1
			l_total = 1
		"grow":
			a_total = N + 1
			l_total = 1


func _winner() -> int:
	var hi := float(maxi(a_total, l_total))
	var lo := float(mini(a_total, l_total))
	if hi / lo <= 1.5:
		return 2
	return 0 if a_total < l_total else 1


func _pick(i: int) -> void:
	if picked >= 0 or over:
		return
	picked = i
	anim_at = t
	for b in buttons:
		b.disabled = true
	buttons[i].modulate = UI.hot(UI.WARN, 1.3)


func tick(_delta: float) -> void:
	if picked < 0 or revealed:
		return
	var p := (t - anim_at) / DT
	if int(p) != int(p - _delta / DT) and p <= maxi(a_total, l_total):
		sfx("tick", 1.0 + 0.04 * int(p))
	if p >= maxi(a_total, l_total) + 1.5:
		revealed = true
		var w := _winner()
		buttons[w].modulate = UI.hot(UI.ACCENT, 1.5)
		if picked == w:
			score += 1
			sfx("ok")
			burst(buttons[w].position + buttons[w].size / 2.0, UI.ACCENT, 26)
			verdict.text = "Right: %s.  Array %d steps, linked list %d steps." % [OPTS[w].to_lower(), a_total, l_total]
			verdict.add_theme_color_override("font_color", UI.ACCENT)
		else:
			sfx("bad")
			verdict.text = "It was: %s.  Array %d steps, linked list %d steps." % [OPTS[w].to_lower(), a_total, l_total]
			verdict.add_theme_color_override("font_color", UI.WARN)
		why.text = QS[qi]["why"] + "  " + QS[qi]["big"]
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
	finish(3 if score >= 5 else (2 if score >= 3 else 1))
	q_label.text = "Score: %d / %d" % [score, QS.size()]
	verdict.text = "Arrays are great at jumping to a position. Lists are great at splicing where you already stand."
	verdict.add_theme_color_override("font_color", UI.INK)
	why.text = "In practice the array usually wins anyway, because contiguous memory is kind to the CPU cache. Reach for a linked list when you insert or remove at the ends or at a spot you already hold."
	for b in buttons:
		b.visible = false
	next_btn.text = "Play again"


func _cell(i: int) -> Vector2:
	return Vector2(AX + i * (CW + CGAP), AY)


func _item(pos: Vector2, s: String, c: Color, w: float = CW, alpha: float = 1.0) -> void:
	UI.rrect(self, Rect2(pos + Vector2(3, 3), Vector2(w - 6, 54)), Color(c.r, c.g, c.b, alpha), 9.0)
	UI.ctext(self, pos + Vector2(w / 2.0, 30), s, 20, Color(0.04, 0.05, 0.09, alpha), "title")


func _node(center: Vector2, s: String, c: Color, alpha: float = 1.0) -> void:
	UI.rrect(self, Rect2(center - Vector2(30, 26), Vector2(60, 52)), Color(c.r, c.g, c.b, alpha), 12.0)
	UI.ctext(self, center, s, 20, Color(0.04, 0.05, 0.09, alpha), "title")


func _draw() -> void:
	if over:
		return
	var q: Dictionary = QS[qi]
	var kind: String = q["kind"]
	var p: int = q["pos"]
	var pr := maxf((t - anim_at) / DT, 0.0) if picked >= 0 else 0.0
	var pa := minf(pr, float(a_total))
	var pl := minf(pr, float(l_total))
	var newc := Color.WHITE

	# ---------- array ----------
	UI.text(self, Vector2(AX, AY - 16), "ARRAY   one contiguous block of memory", 14, UI.DIM)
	UI.text(self, Vector2(1100, AY + 38), "%d steps" % int(pa), 24, UI.hot(UI.BLUE, 1.3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	var cap := N if kind == "grow" else 12
	for c in cap:
		UI.rrect(self, Rect2(_cell(c), Vector2(CW, 60)), UI.PANEL, 10.0, Color(1, 1, 1, 0.10), 1.0)
		UI.text(self, _cell(c) + Vector2(0, 78), str(c), 12, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER, CW)
	if kind == "grow":
		for c in 20:
			UI.rrect(self, Rect2(Vector2(AX + c * 50.0, AY + 96), Vector2(46, 60)), UI.PANEL, 8.0, Color(1, 1, 1, 0.10 if picked >= 0 else 0.0), 1.0)
		if picked >= 0:
			UI.text(self, Vector2(AX, AY + 176), "new block, twice the size", 12, UI.DIM)
	for i in N:
		var s := char(65 + i)
		var c := UI.hue(i, 12.0)
		var pos := _cell(i)
		var alpha := 1.0
		var w := CW
		match kind:
			"insert":
				if i >= p:
					pos.x += clampf(pa - (N - 1 - i), 0.0, 1.0) * (CW + CGAP)
			"remove":
				if i == 0:
					alpha = 1.0 - clampf(pr * 4.0, 0.0, 1.0)
				else:
					pos.x -= clampf(pa - (i - 1), 0.0, 1.0) * (CW + CGAP)
			"grow":
				var k := clampf(pa - i, 0.0, 1.0)
				k = k * k * (3.0 - 2.0 * k)
				pos = pos.lerp(Vector2(AX + i * 50.0, AY + 96), k)
				w = lerpf(CW, 46.0, k)
		if alpha > 0.01:
			_item(pos, s, c, w, alpha)
	if picked >= 0:
		match kind:
			"get":
				UI.rrect(self, Rect2(_cell(p) - Vector2(4, 4), Vector2(CW + 8, 68)), UI.CLEAR, 12.0, UI.hot(Color.WHITE, 2.0), 3.0)
			"insert":
				if pr >= N - p:
					_item(_cell(p), "N", newc)
			"grow":
				if pr >= N:
					_item(Vector2(AX + N * 50.0, AY + 96), "N", newc, 46.0)

	# ---------- linked list ----------
	UI.text(self, Vector2(AX, LY - 96), "LINKED LIST   separate nodes, each pointing at the next", 14, UI.DIM)
	UI.text(self, Vector2(1100, LY - 90), "%d steps" % int(pl), 24, UI.hot(UI.PINK, 1.3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	var first := 0
	var head_x := LX
	var mid_insert := kind == "insert" and p > 0 and p < N
	var spliced := picked >= 0 and mid_insert and pr >= l_total - 1
	if kind == "remove" and picked >= 0 and pr > 0.0:
		first = 1 if pr >= 1.0 else 0
	for i in N:
		var center := Vector2(LX + i * LSTEP, LY)
		var alpha := 1.0
		if kind == "remove" and i == 0 and picked >= 0:
			alpha = 1.0 - clampf(pr, 0.0, 1.0)
		if i < N - 1 and alpha > 0.5:
			if not (spliced and i == p - 1):
				UI.arrow(self, center + Vector2(32, 0), center + Vector2(LSTEP - 32, 0), Color(1, 1, 1, 0.55), 2.0)
		if alpha > 0.01:
			_node(center, char(65 + i), UI.hue(i, 12.0), alpha)
	# walking cursor
	if picked >= 0 and (kind == "get" or mid_insert):
		var stop := float(p if kind == "get" else p - 1)
		var cx := LX + minf(pr, stop) * LSTEP
		UI.rrect(self, Rect2(Vector2(cx - 36, LY - 32), Vector2(72, 64)), UI.CLEAR, 14.0, UI.hot(Color.WHITE, 2.0), 3.0)
	# new nodes
	if picked >= 0:
		if kind == "insert" and p == 0 and pr > 0.0:
			var np := Vector2(LX, LY - 60).lerp(Vector2(LX - 62, LY), 0.0)
			np = Vector2(LX, LY + 84)
			_node(np, "N", newc)
			UI.arrow(self, np + Vector2(0, -28), Vector2(LX, LY + 28), UI.hot(UI.ACCENT, 1.6), 2.5)
			head_x = LX
			UI.text(self, np + Vector2(-90, 6), "head", 14, UI.hot(UI.ACCENT, 1.4))
		elif spliced:
			var a := Vector2(LX + (p - 1) * LSTEP, LY)
			var b := Vector2(LX + p * LSTEP, LY)
			var np := (a + b) / 2.0 + Vector2(0, 84)
			_node(np, "N", newc)
			UI.arrow(self, a + Vector2(10, 28), np + Vector2(-22, -28), UI.hot(UI.ACCENT, 1.6), 2.5)
			UI.arrow(self, np + Vector2(22, -28), b + Vector2(-10, 28), UI.hot(UI.ACCENT, 1.6), 2.5)
		elif (kind == "grow" or (kind == "insert" and p == N)) and pr > 0.0:
			var np := Vector2(LX + N * LSTEP, LY)
			UI.arrow(self, np - Vector2(LSTEP - 32, 0), np - Vector2(32, 0), UI.hot(UI.ACCENT, 1.6), 2.5)
			_node(np, "N", newc)
	if not (picked >= 0 and kind == "insert" and p == 0 and pr > 0.0):
		UI.text(self, Vector2(LX + first * LSTEP - 20, LY - 40), "head", 14, UI.hot(UI.ACCENT, 1.4))
	var tail_i := N if (picked >= 0 and pr > 0.0 and (kind == "grow" or (kind == "insert" and p == N))) else N - 1
	UI.text(self, Vector2(LX + tail_i * LSTEP - 14, LY - 40), "tail", 14, UI.hot(UI.ACCENT, 1.4))


func demo() -> void:
	qi = 2
	_show()
	await main.click(buttons[0].position + Vector2(40, 20))
	await main.wait(0.9)
