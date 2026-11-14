extends "res://levels/level_base.gd"
# Card Hunt: sequential search on shuffled cards, then binary search on sorted ones.

const ROUNDS := [
	{"n": 32, "cols": 16, "sorted": false,
		"text": "Round 1. 32 cards in RANDOM order. Click cards to flip them until you find the target. No trick is possible: with no order, every face-down card is equally likely."},
	{"n": 32, "cols": 16, "sorted": true,
		"text": "Round 2. The same 32 cards, now SORTED (left to right, top to bottom). Every flip tells you which side the target is on, and the impossible cards go dark. Where should you flip first?"},
	{"n": 128, "cols": 16, "sorted": true,
		"text": "Round 3. Four times as many cards, still sorted. Guess before you start: how many more flips will 4x the data cost?"},
	{"n": 512, "cols": 32, "sorted": true,
		"text": "Round 4. 512 cards. Checking them one by one would take minutes. Halving needs at most 10 flips."},
]
const AREA := Rect2(40, 268, 1200, 428)
const GAP := 3.0

var round_i := 0
var values: Array = []
var revealed: Array = []
var ruled: Array = []
var flip_at: Array = []
var ruled_at: Array = []
var target := 0
var flips := 0
var found := false
var summary := false
var summary_at := 0.0
var history: Array = []
var left_shown := 32.0

var explain: Label
var info: Label
var status: Label
var next_btn: Button


func _ready() -> void:
	header("Chapter 6: sequential search vs binary search")
	explain = UI.label(self, "", Vector2(40, 88), 17, UI.INK, 1200)
	info = UI.label(self, "", Vector2(40, 150), 28, UI.hot(tint, 1.3), 0.0, "title")
	status = UI.label(self, "", Vector2(40, 196), 16, UI.WARN, 1020)
	next_btn = UI.button(self, "Next round", Vector2(1080, 152), Vector2(160, 46), _next, 18, tint)
	_start_round()


func _start_round() -> void:
	var r: Dictionary = ROUNDS[round_i]
	var pool := range(1, 1000)
	pool.shuffle()
	values = pool.slice(0, r["n"])
	if r["sorted"]:
		values.sort()
	revealed = []
	ruled = []
	flip_at = []
	ruled_at = []
	for i in values.size():
		revealed.append(false)
		ruled.append(false)
		flip_at.append(0.0)
		ruled_at.append(0.0)
	target = values[randi() % values.size()]
	flips = 0
	found = false
	next_btn.visible = false
	explain.text = r["text"]
	status.text = ""
	left_shown = values.size()
	_refresh()


func _par(n: int) -> int:
	return int(floor(log(n) / log(2.0))) + 1


func _left() -> int:
	if found:
		return 1
	var c := 0
	for i in values.size():
		if not revealed[i] and not ruled[i]:
			c += 1
	return c


func _refresh() -> void:
	info.text = "Find  %d          Flips: %d" % [target, flips]


func _rect(i: int) -> Rect2:
	var r: Dictionary = ROUNDS[round_i]
	var cols: int = r["cols"]
	var rows: int = int(r["n"]) / cols
	var cw := (AREA.size.x - GAP * (cols - 1)) / cols
	var ch := minf(74.0, (AREA.size.y - GAP * (rows - 1)) / rows)
	return Rect2(AREA.position + Vector2((i % cols) * (cw + GAP), (i / cols) * (ch + GAP)), Vector2(cw, ch))


func tick(delta: float) -> void:
	left_shown = lerpf(left_shown, float(_left()), 1.0 - exp(-delta * 9.0))


func _gui_input(event: InputEvent) -> void:
	if summary or found:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in values.size():
			if _rect(i).has_point(event.position):
				if not revealed[i]:
					_flip(i)
				return


func _flip(idx: int) -> void:
	revealed[idx] = true
	flip_at[idx] = t
	flips += 1
	var n := values.size()
	var is_sorted: bool = ROUNDS[round_i]["sorted"]
	if values[idx] == target:
		found = true
		history.append(flips)
		sfx("ok")
		burst(_rect(idx).get_center(), tint, 30)
		if is_sorted:
			var par := _par(n)
			status.text = "Found in %d. Halving perfectly never needs more than %d flips for %d cards." % [flips, par, n]
			if flips > par:
				status.text += " Tip: always flip the middle of what is still lit."
		else:
			status.text = "Found in %d. Pure luck: on average it takes n/2 = %d flips, worst case all %d. That is O(n)." % [flips, n / 2, n]
		next_btn.text = "Next round" if round_i < ROUNDS.size() - 1 else "See summary"
		next_btn.visible = true
	else:
		sfx("tick", 0.8 + 0.05 * flips)
		if is_sorted:
			if values[idx] < target:
				for i in range(0, idx + 1):
					if not ruled[i]:
						ruled[i] = true
						ruled_at[i] = t
				status.text = "%d is too small, so everything before it is out too." % values[idx]
			else:
				for i in range(idx, n):
					if not ruled[i]:
						ruled[i] = true
						ruled_at[i] = t
				status.text = "%d is too big, so everything after it is out too." % values[idx]
	_refresh()


func _next() -> void:
	if summary:
		summary = false
		history = []
		round_i = 0
		_start_round()
		return
	if round_i < ROUNDS.size() - 1:
		round_i += 1
		_start_round()
		return
	summary = true
	summary_at = t
	var good := 0
	for i in range(1, ROUNDS.size()):
		if history[i] <= _par(ROUNDS[i]["n"]):
			good += 1
	finish(3 if good == 3 else (2 if good >= 1 else 1))
	explain.text = "You used %d flips on 32 shuffled cards, then %d, %d and %d flips on 32, 128 and 512 sorted cards. Sorting did not make the computer faster. It let every look throw away half of what was left." % [history[0], history[1], history[2], history[3]]
	info.text = "Worst-case looks to find one item"
	status.text = ""
	next_btn.text = "Play again"


func _draw() -> void:
	if summary:
		_draw_summary()
		return
	var n := values.size()
	UI.text(self, Vector2(40, 246), "Still possible: %d of %d" % [int(round(left_shown)), n], 13, UI.DIM)
	UI.rrect(self, Rect2(220, 236, 1020, 10), UI.PANEL, 5.0)
	UI.rrect(self, Rect2(220, 236, maxf(1020.0 * left_shown / n, 6.0), 10), UI.hot(tint, 1.5), 5.0)
	var hidden := tint.darkened(0.5)
	var dead := Color(0.07, 0.08, 0.12)
	for i in n:
		var r := _rect(i)
		var rad := minf(8.0, r.size.x * 0.16)
		var p := clampf((t - flip_at[i]) / 0.28, 0.0, 1.0) if revealed[i] else 0.0
		var sx := maxf(absf(cos(PI * p)), 0.04)
		var rr := Rect2(r.position.x + r.size.x * (1.0 - sx) / 2.0, r.position.y, r.size.x * sx, r.size.y)
		if revealed[i] and p >= 0.5:
			var hit: bool = values[i] == target
			UI.rrect(self, rr, tint.lightened(0.25) if hit else UI.PANEL2, rad, UI.hot(Color.WHITE, 1.6 + 0.6 * sin(t * 6.0)) if hit else Color(1, 1, 1, 0.12), 3.0 if hit else 1.0)
			if sx > 0.7:
				var fs := clampi(int(r.size.x * 0.36), 11, 24)
				UI.ctext(self, r.get_center(), str(values[i]), fs, UI.BG if hit else (UI.DIM if ruled[i] else UI.INK), "title")
		else:
			var k := clampf((t - ruled_at[i]) / 0.4, 0.0, 1.0) if ruled[i] else 0.0
			UI.rrect(self, rr, hidden.lerp(dead, k), rad, Color(tint.r, tint.g, tint.b, 0.7 * (1.0 - k)), 1.0)


func _draw_summary() -> void:
	var rows := [32, 128, 512, 1000000, 1000000000]
	var y := 276.0
	var k := clampf((t - summary_at) / 1.2, 0.0, 1.0)
	k = 1.0 - pow(1.0 - k, 3.0)
	UI.text(self, Vector2(60, y), "Items (n)", 15, UI.DIM)
	UI.text(self, Vector2(300, y), "Unsorted: check each one, O(n)", 15, UI.BAD)
	UI.text(self, Vector2(300, y + 20), "Sorted: halve it, O(log n)", 15, UI.ACCENT)
	y += 34.0
	for n in rows:
		UI.rrect(self, Rect2(40, y, 1200, 62), UI.PANEL, 10.0)
		UI.text(self, Vector2(60, y + 39), UI.fmt(n), 22, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
		UI.rrect(self, Rect2(300, y + 12, 760 * k, 14), UI.hot(UI.BAD, 1.3), 7.0)
		UI.text(self, Vector2(1076, y + 25), UI.fmt(n), 15, UI.BAD)
		UI.rrect(self, Rect2(300, y + 36, maxf(760.0 * k * _par(n) / n, 3.0), 14), UI.hot(UI.ACCENT, 1.6), 7.0)
		UI.text(self, Vector2(1076, y + 49), str(_par(n)), 15, UI.ACCENT)
		y += 70.0
	UI.text(self, Vector2(60, y + 26), "Each row is drawn to the same scale. By a million items the green bar is thinner than a pixel. Doubling the data adds ONE look.", 16, UI.WARN)


func demo() -> void:
	round_i = 2
	_start_round()
	var lo := 0
	var hi := values.size() - 1
	for i in 3:
		var mid := (lo + hi) >> 1
		await main.click(_rect(mid).get_center())
		if values[mid] == target:
			break
		if values[mid] < target:
			lo = mid + 1
		else:
			hi = mid - 1
		await main.wait(0.25)
