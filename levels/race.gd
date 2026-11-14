extends "res://levels/level_base.gd"
# Pick Your Structure: a workload arrives, six structures race on total step count.

const N := 1000.0
const STRUCTS := ["Unsorted array", "Sorted array", "Linked list", "Hash table", "Balanced search tree", "Binary heap"]
const OP_NAMES := {
	"lookup": "lookup by key", "insert": "insert", "remove_min": "remove smallest",
	"sorted_list": "list all in order", "index": "get item #i", "range": "range query", "scan": "read everything",
}
const SCENARIOS := [
	{"title": "Login service",
		"text": "1,000 accounts are already loaded. Then 10,000 logins each look up one account by username.",
		"ops": {"lookup": 10000},
		"lesson": "Lookup by exact key is what a hash table is for: about 1 step, however big n gets. Sorted array and balanced tree are respectable at ~10 steps (log n). Everything else scans up to 1,000 items per login."},
	{"title": "ER triage",
		"text": "1,000 patients arrive through the day, mixed with 1,000 calls of 'who is most urgent? treat them next'.",
		"ops": {"insert": 1000, "remove_min": 1000},
		"lesson": "'Always hand me the smallest' is a priority queue. A binary heap does insert and remove-min in log n. A balanced tree ties on paper, but the heap is simpler and lives in a plain array. The sorted array has the minimum ready, yet every insert shifts ~n items."},
	{"title": "Leaderboard",
		"text": "1,000 new scores arrive, 1,000 players look up their own score, and the full ranking is printed in order 20 times.",
		"ops": {"insert": 1000, "lookup": 1000, "sorted_list": 20},
		"lesson": "Inserts, lookups AND ordered output: a balanced search tree is log n for the first two and walks out in sorted order for free. The hash table flies until someone asks for order, then it must sort everything, every time."},
	{"title": "Audit log",
		"text": "10,000 events are appended as they happen. At the end of the day the whole log is read once, start to finish.",
		"ops": {"insert": 10000, "scan": 1},
		"lesson": "Nothing here needs searching or ordering, so plain append wins at 1 step each. A tree or heap does log n work per insert to maintain an order nobody asked for. Use the simplest structure the workload allows."},
	{"title": "Dictionary app",
		"text": "The word list loads once and never changes. Then 5,000 exact lookups and 5,000 'every word between cat and dog' queries.",
		"ops": {"lookup": 5000, "range": 5000},
		"lesson": "A hash table cannot answer 'between': hashing scatters neighbours, so a range query scans everything. Sorted data keeps neighbours adjacent, so binary search finds the start of the range in log n. With no inserts, a sorted array matches the tree and is simpler."},
	{"title": "Spreadsheet column",
		"text": "A column of 1,000 cells. 10,000 formulas each ask for 'the value in row i'.",
		"ops": {"index": 10000},
		"lesson": "Jumping straight to position i is the array's superpower: one step. A linked list walks i links to get there. Trees, heaps and hash tables do not keep 'row i' at all."},
	{"title": "Email de-dupe",
		"text": "5,000 sign-ups stream in. For each one: have we seen this address before? If not, remember it.",
		"ops": {"lookup": 5000, "insert": 5000},
		"lesson": "'Have I seen this?' plus 'remember it' is a set: a hash table does both in about 1 step. The unsorted array is the accidental O(n²) you met in Count the Loops: cheap insert, but every check scans everything."},
]
const LANE_Y := 240.0
const LANE_H := 54.0
const TRACK_X := 300.0
const TRACK_W := 680.0

var si := 0
var score := 0
var pick := -1
var rt := 0.0
var racing := false
var totals: Array = []
var durs: Array = []
var best := 1.0
var over := false

var title_l: Label
var text_l: Label
var ops_l: Label
var verdict: Label
var lesson: Label
var next_btn: Button
var lane_btns: Array = []


func _ready() -> void:
	header("Chapter 7 onward: every structure is a trade. n = 1,000 items, counting steps.")
	title_l = UI.label(self, "", Vector2(40, 88), 24, UI.hot(tint, 1.25), 0.0, "title")
	text_l = UI.label(self, "", Vector2(40, 126), 18, UI.INK, 1200)
	ops_l = UI.label(self, "", Vector2(40, 190), 15, UI.DIM)
	for i in STRUCTS.size():
		lane_btns.append(UI.button(self, STRUCTS[i], Vector2(40, LANE_Y + i * LANE_H), Vector2(240, 44), _pick.bind(i), 16, tint))
	verdict = UI.label(self, "", Vector2(40, 574), 20, UI.WARN, 1020, "title")
	lesson = UI.label(self, "", Vector2(40, 606), 15, UI.INK, 1020)
	next_btn = UI.button(self, "Next", Vector2(1090, 646), Vector2(150, 48), _next, 18, tint)
	_show()


func cost(s: int, op: String) -> float:
	var n := N
	var lg := log(n) / log(2.0)
	var row: Array = []
	match op:
		"lookup": row = [n, lg, n, 1, lg, n]
		"insert": row = [1, n, 1, 1, lg, lg]
		"remove_min": row = [n, 1, n, n, lg, lg]
		"sorted_list": row = [n * lg, n, n * lg, n * lg, n, n * lg]
		"index": row = [1, 1, n, n, n, n]
		"range": row = [n, lg, n, n, lg, n]
		"scan": row = [n, n, n, n, n, n]
	return float(row[s])


func _show() -> void:
	var sc: Dictionary = SCENARIOS[si]
	pick = -1
	racing = false
	rt = 0.0
	title_l.text = "%d / %d   %s          Score: %d" % [si + 1, SCENARIOS.size(), sc["title"], score]
	text_l.text = sc["text"]
	var parts: Array = []
	totals = []
	for s in STRUCTS.size():
		totals.append(0.0)
	for op in sc["ops"]:
		parts.append("%s x %s" % [UI.fmt(sc["ops"][op]), OP_NAMES[op]])
		for s in STRUCTS.size():
			totals[s] += cost(s, op) * sc["ops"][op]
	ops_l.text = "Workload:  " + "   +   ".join(parts) + "          Which structure would you reach for?"
	best = totals.min()
	durs = []
	for s in STRUCTS.size():
		durs.append(minf(1.0 * pow(totals[s] / best, 0.3), 7.0))
	verdict.text = ""
	lesson.text = ""
	next_btn.visible = false
	for b in lane_btns:
		b.disabled = false
		b.modulate = Color.WHITE


func _pick(i: int) -> void:
	if pick >= 0 or over:
		return
	pick = i
	racing = true
	rt = 0.0
	for b in lane_btns:
		b.disabled = true
	lane_btns[i].modulate = UI.hot(UI.WARN, 1.3)


func tick(delta: float) -> void:
	if not racing:
		return
	var before := rt
	rt += delta
	for s in STRUCTS.size():
		if before < durs[s] and rt >= durs[s]:
			sfx("tick", 2.0 - durs[s] * 0.18)
	if rt >= durs.max():
		racing = false
		_finish_race()


func _finish_race() -> void:
	var ratio: float = totals[pick] / best
	if ratio <= 1.5:
		score += 1
		sfx("ok")
		burst(Vector2(TRACK_X + TRACK_W, LANE_Y + pick * LANE_H + 22), UI.ACCENT, 34)
		verdict.text = "Best pick. %s did it in %s steps." % [STRUCTS[pick], UI.fmt(totals[pick])]
		verdict.add_theme_color_override("font_color", UI.ACCENT)
	elif ratio <= 50.0:
		verdict.text = "Workable, but about %dx more steps than the best choice." % int(round(ratio))
		verdict.add_theme_color_override("font_color", UI.WARN)
	else:
		sfx("bad")
		verdict.text = "Ouch: about %sx more steps than the best choice." % UI.fmt(ratio)
		verdict.add_theme_color_override("font_color", UI.BAD)
	lesson.text = SCENARIOS[si]["lesson"]
	title_l.text = "%d / %d   %s          Score: %d" % [si + 1, SCENARIOS.size(), SCENARIOS[si]["title"], score]
	next_btn.text = "Next" if si < SCENARIOS.size() - 1 else "Finish"
	next_btn.visible = true


func _next() -> void:
	if over:
		over = false
		si = 0
		score = 0
		_show()
		return
	if si < SCENARIOS.size() - 1:
		si += 1
		_show()
		return
	over = true
	finish(3 if score >= 6 else (2 if score >= 4 else 1))
	pick = -1
	title_l.text = "Score: %d / %d" % [score, SCENARIOS.size()]
	text_l.text = "No structure wins everywhere. Ask what the workload does most, then pick the structure that makes THAT cheap."
	ops_l.text = "Cost of one operation with n items:"
	verdict.text = ""
	lesson.text = ""
	next_btn.text = "Play again"
	for b in lane_btns:
		b.disabled = true
		b.modulate = Color.WHITE


func _big_o(v: float) -> String:
	var lg := log(N) / log(2.0)
	if v <= 1.0: return "1"
	if v <= lg + 0.01: return "log n"
	if v <= N: return "n"
	return "n log n"


func _draw() -> void:
	if over:
		var ops := ["lookup", "insert", "remove_min", "sorted_list", "index", "range"]
		for c in ops.size():
			UI.text(self, Vector2(TRACK_X + 14 + c * 156, LANE_Y - 12), OP_NAMES[ops[c]], 14, UI.DIM)
		for s in STRUCTS.size():
			var y := LANE_Y + s * LANE_H
			UI.rrect(self, Rect2(TRACK_X, y, 940, 44), UI.PANEL, 10.0)
			for c in ops.size():
				var txt := _big_o(cost(s, ops[c]))
				var cc := UI.ACCENT if txt == "1" else (UI.BLUE if txt == "log n" else (UI.WARN if txt == "n" else UI.BAD))
				UI.text(self, Vector2(TRACK_X + 14 + c * 156, y + 29), txt, 19, UI.hot(cc, 1.25), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
		UI.text(self, Vector2(40, 600), "Simplified: hash costs are averages, 'get item #i' means position in insertion order, and the sorted array keeps its smallest at the end.", 13, UI.DIM)
		return
	for s in STRUCTS.size():
		var y := LANE_Y + s * LANE_H
		var track := Rect2(TRACK_X, y + 6, TRACK_W, 32)
		UI.rrect(self, track, UI.PANEL, 16.0, Color(1, 1, 1, 0.06), 1.0)
		if pick < 0:
			continue
		var p: float = clampf(rt / durs[s], 0.0, 1.0) if racing else 1.0
		var done := p >= 1.0
		var ratio: float = totals[s] / best
		var c := UI.BLUE
		if s == pick:
			c = UI.WARN
		if done:
			c = UI.ACCENT if ratio <= 1.5 else (UI.WARN if ratio <= 50.0 else UI.BAD)
		UI.rrect(self, Rect2(TRACK_X, y + 6, maxf(TRACK_W * p, 32.0), 32), UI.hot(c, 1.25 if done else 1.0), 16.0)
		if not done:
			draw_circle(Vector2(TRACK_X + maxf(TRACK_W * p, 32.0) - 16.0, y + 22), 11.0, UI.hot(Color.WHITE, 2.2))
		UI.text(self, Vector2(TRACK_X + TRACK_W + 16, y + 28), UI.fmt(totals[s] * p) + " steps", 16, UI.INK if done else UI.DIM)
		if done:
			var tag := "best" if ratio <= 1.5 else "%sx" % UI.fmt(ratio)
			UI.text(self, Vector2(TRACK_X + TRACK_W + 176, y + 28), tag, 16, UI.hot(c, 1.3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
		if s == pick:
			UI.text(self, Vector2(TRACK_X + 14, y + 28), "your pick", 14, UI.BG, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")


func demo() -> void:
	si = 2
	_show()
	await main.click(lane_btns[3].position + Vector2(50, 20))
	await main.wait(1.4)
