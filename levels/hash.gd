extends "res://levels/level_base.gd"
# Hash Buckets: watch keys hash, collide and probe. Load factor is everything.

const MODES := ["Linear probing", "Quadratic probing", "Separate chaining"]
const COLS := 12
const SW := 92.0
const SH := 52.0
const SGAP := 6.0
const X0 := 46.0
const Y0 := 318.0
const ROWH := 186.0
const MACHINE := Vector2(640, 262)

var m := 11
var mode := 0
var keys: Array = []
var slots: Array = []
var chains: Array = []
var probes := {}
var landed := {}
var jobs: Array = []
var bump := {}
var goals := [false, false, false]

var msg: Label
var goal_l: Label
var mode_btn: Button
var size_btn: Button


func _ready() -> void:
	header("Chapter 20: a hash function turns a key straight into a slot number")
	UI.button(self, "Insert 1", Vector2(40, 92), Vector2(100, 40), _add.bind(1), 15, tint)
	UI.button(self, "Insert 5", Vector2(148, 92), Vector2(100, 40), _add.bind(5), 15, tint)
	UI.button(self, "Insert look-alikes", Vector2(256, 92), Vector2(170, 40), _add_alike, 15, tint)
	mode_btn = UI.button(self, "", Vector2(434, 92), Vector2(230, 40), _next_mode, 15, tint)
	size_btn = UI.button(self, "", Vector2(672, 92), Vector2(200, 40), _resize, 15, tint)
	UI.button(self, "Clear", Vector2(880, 92), Vector2(74, 40), _clear, 15, tint)
	goal_l = UI.label(self, "", Vector2(972, 88), 13, UI.DIM, 280)
	msg = UI.label(self, "", Vector2(40, 144), 15, UI.INK, 900)
	_reset_table()
	_say("Each key goes to slot  key % table size. That jump is one step, which is where O(1) comes from. Trouble starts when two keys want the same slot. Insert some keys, then click one to look it up.")


func _say(s: String) -> void:
	msg.text = s
	mode_btn.text = "Mode: " + MODES[mode]
	size_btn.text = "Rehash into 23 slots" if m == 11 else "Shrink back to 11"
	goal_l.text = "GOALS\n[%s]  Linear probing: make a key need 5+ probes\n[%s]  23 slots, 8+ keys, average under 1.5 probes\n[%s]  Separate chaining with 12+ keys" % [
		"x" if goals[0] else "  ", "x" if goals[1] else "  ", "x" if goals[2] else "  "]


func _reset_table() -> void:
	slots = []
	chains = []
	for i in m:
		slots.append(-1)
		chains.append([])
	probes = {}
	landed = {}
	jobs = []


func _place(key: int) -> Array:
	var h := key % m
	if mode == 2:
		chains[h].append(key)
		probes[key] = chains[h].size()
		return [h]
	var seq: Array = []
	for i in m:
		var s := (h + (i if mode == 0 else i * i)) % m
		seq.append(s)
		if slots[s] == -1:
			slots[s] = key
			probes[key] = i + 1
			return seq
	return []


func _insert(key: int, animate: bool) -> bool:
	if keys.has(key):
		return false
	var seq := _place(key)
	if seq.is_empty():
		return false
	keys.append(key)
	if animate:
		jobs.append({"key": key, "seq": seq, "p": 0.0, "i": 0, "lookup": false})
	else:
		landed[key] = true
	return true


func _fresh_key() -> int:
	var k := 1 + randi() % 999
	while keys.has(k):
		k = 1 + randi() % 999
	return k


func _fail_text() -> String:
	if mode == 0:
		return "The table is completely full. Probing has nowhere left to go: rehash into a bigger table."
	return "Quadratic probing jumped around and never found a free slot. It is only guaranteed to work while the table is under half full (and the size is prime). Rehash into a bigger table."


func _add(count: int) -> void:
	var added := 0
	for i in count:
		if _insert(_fresh_key(), true):
			added += 1
	if added < count:
		sfx("bad")
		_say(_fail_text())
	else:
		_say("hash(key) = key %% %d. If that slot is taken: %s" % [m,
			["try the next slot, then the next... (linear probing).", "jump 1, 4, 9, 16... slots ahead (quadratic probing), which breaks up clusters.", "no problem, each slot holds a small list (separate chaining)."][mode]])


func _add_alike() -> void:
	var r := randi() % m
	var added := 0
	var tries := 0
	while added < 4 and tries < 60:
		tries += 1
		var k := r + m * (1 + randi() % 40)
		if k <= 999 and not keys.has(k):
			if not _insert(k, true):
				sfx("bad")
				_say(_fail_text())
				return
			added += 1
	_say("Four keys that all hash to slot %d. A bad hash function, or unlucky data, makes this happen for real. Watch them pile up%s" % [r,
		": with linear probing they form a solid run, and every future key that lands anywhere in the run makes it longer. That is primary clustering." if mode == 0 else "."])


func _rebuild() -> void:
	var old := keys.duplicate()
	keys = []
	_reset_table()
	var dropped := 0
	for k in old:
		if not _insert(k, false):
			dropped += 1
	if dropped > 0:
		_say("%d key%s could not be placed in this configuration and were dropped. %s" % [dropped, "" if dropped == 1 else "s", _fail_text()])
	_check_goals()


func _next_mode() -> void:
	mode = (mode + 1) % 3
	_say(["Linear probing: on a collision, walk to the next free slot. Simple and cache-friendly, but occupied runs grow into clusters.",
		"Quadratic probing: on a collision, jump 1, 4, 9... slots ahead. Keys that collide still follow the same path, but neighbouring runs no longer merge.",
		"Separate chaining: every slot holds a short list. Nothing ever probes, the table can go past 100% full, and a lookup costs the length of one chain."][mode])
	_rebuild()


func _resize() -> void:
	m = 23 if m == 11 else 11
	_say("Rehashing: every key's slot is key %% %d, so ALL of them move. It costs O(n) once, but it resets the load factor, and doubling means it happens rarely. Same amortized trick as a growing array." % m)
	_rebuild()
	sfx("pop")


func _clear() -> void:
	keys = []
	_reset_table()
	_say("Empty table.")


func _stats() -> Array:
	var total := 0
	var worst := 0
	var count := 0
	for k in keys:
		if landed.has(k):
			total += int(probes[k])
			worst = maxi(worst, int(probes[k]))
			count += 1
	return [count, (float(total) / count) if count > 0 else 0.0, worst]


func _check_goals() -> void:
	var s := _stats()
	if mode == 0 and s[2] >= 5:
		goals[0] = true
	if m == 23 and s[0] >= 8 and s[1] <= 1.5:
		goals[1] = true
	if mode == 2 and s[0] >= 12:
		goals[2] = true
	var count := goals.count(true)
	if count > 0:
		finish(count, count == 3)
	_say(msg.text)


func _slot(i: int) -> Rect2:
	return Rect2(X0 + (i % COLS) * (SW + SGAP), Y0 + (i / COLS) * ROWH, SW, SH)


func _chain_rect(s: int, j: int) -> Rect2:
	var r := _slot(s)
	return Rect2(r.position.x + 8, r.end.y + 8 + j * 27.0, SW - 16, 23)


func tick(delta: float) -> void:
	if jobs.is_empty():
		return
	var job: Dictionary = jobs[0]
	var seq: Array = job["seq"]
	job["p"] = float(job["p"]) + delta * (16.0 if jobs.size() > 3 else 5.5)
	while int(job["i"]) < seq.size() - 1 and float(job["p"]) >= int(job["i"]) + 1.0:
		bump[seq[int(job["i"])]] = t
		sfx("tick", 0.8 + 0.12 * int(job["i"]))
		job["i"] = int(job["i"]) + 1
	if float(job["p"]) >= seq.size():
		jobs.pop_front()
		if job["lookup"]:
			sfx("ok", 1.3)
			_say("Found %d after %d probe%s. A lookup repeats exactly the path the insert took." % [job["key"], int(probes[job["key"]]), "" if int(probes[job["key"]]) == 1 else "s"])
		else:
			landed[job["key"]] = true
			sfx("pop", 1.2)
			_check_goals()


func _lookup(key: int) -> void:
	if not jobs.is_empty():
		return
	var h := key % m
	var seq: Array = []
	if mode == 2:
		seq = [h]
	else:
		for i in m:
			var s := (h + (i if mode == 0 else i * i)) % m
			seq.append(s)
			if slots[s] == key:
				break
	jobs.append({"key": key, "seq": seq, "p": 0.0, "i": 0, "lookup": true})


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in m:
			if mode == 2:
				for j in chains[i].size():
					if _chain_rect(i, j).has_point(event.position) and landed.has(chains[i][j]):
						_lookup(chains[i][j])
						return
			elif slots[i] != -1 and landed.has(slots[i]) and _slot(i).has_point(event.position):
				_lookup(slots[i])
				return


func _key_col(key: int) -> Color:
	return UI.hue(key % m, m, 0.6, 0.95)


func _draw() -> void:
	var s := _stats()
	var lam := float(keys.size()) / m
	# stats strip
	UI.text(self, Vector2(40, 218), "Load factor", 13, UI.DIM)
	UI.rrect(self, Rect2(40, 226, 220, 12), UI.PANEL, 6.0)
	var lc := UI.ACCENT if lam < 0.5 else (UI.WARN if lam < 0.8 else UI.BAD)
	UI.rrect(self, Rect2(40, 226, minf(lam, 1.0) * 220.0, 12), UI.hot(lc, 1.5), 6.0)
	UI.text(self, Vector2(272, 238), "%d / %d = %.2f" % [keys.size(), m, lam], 16, UI.hot(lc, 1.3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	UI.text(self, Vector2(40, 276), "Average probes per lookup: %.2f        Worst: %d" % [s[1], s[2]], 15, UI.INK)
	# hash machine
	var mr := Rect2(MACHINE - Vector2(150, 24), Vector2(300, 48))
	UI.rrect(self, mr, UI.PANEL2, 12.0, UI.hot(tint, 1.3), 1.5)
	var mt := "hash(key) = key %% %d" % m
	if not jobs.is_empty():
		var jk: int = jobs[0]["key"]
		mt = "%d %% %d = %d" % [jk, m, jk % m]
	UI.ctext(self, MACHINE, mt, 18, UI.INK, "mono")
	# slots
	for i in m:
		var r := _slot(i)
		var bt := clampf(1.0 - (t - float(bump.get(i, -9.0))) / 0.45, 0.0, 1.0)
		UI.rrect(self, r, UI.PANEL, 10.0, UI.hot(UI.BAD, 1.0 + bt) if bt > 0.0 else Color(1, 1, 1, 0.10), 1.0 + 2.0 * bt)
		UI.text(self, Vector2(r.position.x, r.position.y - 6), str(i), 12, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER, SW)
		if mode == 2:
			var ch: Array = chains[i]
			var cap := 5
			for j in mini(ch.size(), cap):
				if landed.has(ch[j]):
					var cr := _chain_rect(i, j)
					UI.rrect(self, cr, _key_col(ch[j]), 7.0)
					UI.ctext(self, cr.get_center(), str(ch[j]), 14, UI.BG, "title")
			if ch.size() > cap:
				UI.text(self, Vector2(r.position.x, r.end.y + 8 + cap * 27.0 + 14), "+%d more" % (ch.size() - cap), 12, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER, SW)
			UI.ctext(self, r.get_center(), "%d item%s" % [ch.size(), "" if ch.size() == 1 else "s"], 13, UI.DIM)
		elif slots[i] != -1 and landed.has(slots[i]):
			var key: int = slots[i]
			var pc := int(probes[key])
			UI.rrect(self, r.grow(-4.0), _key_col(key), 8.0)
			UI.ctext(self, r.get_center() + Vector2(0, -5), str(key), 18, UI.BG, "title")
			for d in mini(pc, 8):
				draw_circle(Vector2(r.position.x + 14 + d * 9.0, r.end.y - 11), 2.6, Color(0.05, 0.06, 0.1) if pc <= 2 else UI.hot(UI.BAD, 1.2))
	# clusters (linear probing): outline runs of 4 or more occupied slots
	if mode == 0:
		var run_start := -1
		for i in m + 1:
			var occ: bool = i < m and slots[i] != -1 and landed.has(slots[i]) and (i % COLS != 0 or run_start == -1)
			if occ and run_start == -1:
				run_start = i
			elif not occ and run_start != -1:
				if i - run_start >= 4:
					var a := _slot(run_start)
					var b := _slot(i - 1)
					UI.rrect(self, Rect2(a.position - Vector2(5, 5), b.end - a.position + Vector2(10, 10)), UI.CLEAR, 14.0, UI.hot(UI.WARN, 1.6), 2.0)
					UI.text(self, Vector2(a.position.x, a.end.y + 24), "cluster of %d" % (i - run_start), 13, UI.hot(UI.WARN, 1.3))
				run_start = i if (i < m and slots[i] != -1 and landed.has(slots[i])) else -1
	if m == 11:
		_draw_chart(lam, float(s[1]))
	# the key in flight
	if not jobs.is_empty():
		var job: Dictionary = jobs[0]
		var seq: Array = job["seq"]
		var pts: Array = [MACHINE + Vector2(0, 30)]
		for k in seq.size():
			var c := _slot(seq[k]).get_center()
			pts.append(c if k == seq.size() - 1 else c + Vector2(0, -46))
		var p := clampf(float(job["p"]), 0.0, seq.size() - 0.001)
		var i0 := int(p)
		var f := p - i0
		var pos: Vector2 = pts[i0].lerp(pts[i0 + 1], f * f * (3.0 - 2.0 * f)) + Vector2(0, -sin(PI * f) * 24.0)
		var kr := Rect2(pos - Vector2(36, 20), Vector2(72, 40))
		if job["lookup"]:
			UI.rrect(self, kr, UI.CLEAR, 10.0, UI.hot(Color.WHITE, 2.2), 3.0)
		else:
			UI.rrect(self, kr, UI.hot(_key_col(job["key"]), 1.5), 10.0)
			UI.ctext(self, pos, str(job["key"]), 18, UI.BG, "title")


func demo() -> void:
	await main.click(Vector2(340, 112))
	await main.wait(1.8)
	await main.click(Vector2(190, 112))
	await main.wait(2.6)


func _draw_chart(lam: float, measured: float) -> void:
	var cr := Rect2(46, 512, 1176, 184)
	UI.rrect(self, cr, Color("0f111b"), 12.0, Color(1, 1, 1, 0.07), 1.0)
	UI.text(self, cr.position + Vector2(16, 24), "Expected probes per lookup as the table fills up (theory). The white dot is your table right now.", 13, UI.DIM)
	var w := cr.size.x - 240.0
	var h := cr.size.y - 74.0
	var ox := cr.position.x + 40.0
	var oy := cr.end.y - 30.0
	var ticks := [[0.0, "empty"], [0.5, "half full"], [0.75, "75%"], [0.9, "90% full"]]
	for tk in ticks:
		var x := ox + float(tk[0]) / 0.95 * w
		draw_line(Vector2(x, oy), Vector2(x, oy - h), Color(1, 1, 1, 0.07), 1.0)
		UI.text(self, Vector2(x - 40, oy + 18), tk[1], 12, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER, 80.0)
	for curve in 2:
		var pts := PackedVector2Array()
		var l := 0.0
		while l <= 0.951:
			var y := 0.5 * (1.0 + 1.0 / (1.0 - l)) if curve == 0 else 1.0 + l / 2.0
			pts.append(Vector2(ox + l / 0.95 * w, oy - (minf(y, 10.5) - 1.0) / 9.5 * h))
			l += 0.01
		var c := UI.BAD if curve == 0 else UI.ACCENT
		var live := (curve == 0 and mode == 0) or (curve == 1 and mode == 2)
		draw_polyline(pts, UI.hot(c, 1.6) if live else Color(c.r, c.g, c.b, 0.45), 4.0 if live else 2.0, true)
		UI.text(self, pts[pts.size() - 1] + Vector2(10, 5), "linear probing" if curve == 0 else "separate chaining", 13, c)
	var dot := Vector2(ox + minf(lam, 0.95) / 0.95 * w, oy - (clampf(measured, 1.0, 10.5) - 1.0) / 9.5 * h)
	draw_circle(dot, 7.0, UI.hot(Color.WHITE, 2.4))
