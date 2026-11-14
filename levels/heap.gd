extends "res://levels/level_base.gd"
# Heap Climb: a binary heap is a tree stored in an array. Insert percolates up, remove-min percolates down.

const CAP := 31
const TOP := 232.0
const LEVEL_H := 68.0
const STRIP_Y := 566.0

var h: Array = []
var cur := {}
var hole := -1
var dir := 0            # 0 idle, 1 percolating up, 2 percolating down
var manual := true
var wait := 0.0
var correct := 0
var swaps := 0
var removed: Array = []
var goals := [false, false, false]

var msg: Label
var goal_l: Label
var manual_btn: Button


func _ready() -> void:
	header("Chapter 21: the binary heap. Every parent is smaller than its children.")
	UI.button(self, "Insert random", Vector2(40, 92), Vector2(140, 40), _insert_random, 15, tint)
	UI.button(self, "Insert tiny value", Vector2(188, 92), Vector2(160, 40), _insert_small, 15, tint)
	UI.button(self, "Remove smallest", Vector2(356, 92), Vector2(160, 40), _remove_min, 15, tint)
	UI.button(self, "Add 7 at once", Vector2(524, 92), Vector2(130, 40), _add_many, 15, tint)
	manual_btn = UI.button(self, "", Vector2(662, 92), Vector2(190, 40), _toggle, 15, tint)
	UI.button(self, "Clear", Vector2(860, 92), Vector2(74, 40), _clear, 15, tint)
	goal_l = UI.label(self, "", Vector2(960, 88), 13, UI.DIM, 290)
	msg = UI.label(self, "", Vector2(40, 144), 15, UI.INK, 900)
	for v in [12, 25, 18, 40, 31, 22]:
		h.append(v)
	_say("The smallest value always sits at the root, so 'find min' is free. You do the swaps: when a value is out of place, click the node it should trade with.")


func _say(s: String) -> void:
	msg.text = s
	manual_btn.text = "You do the swaps: ON" if manual else "You do the swaps: OFF"
	UI.select(manual_btn, manual, tint)
	if h.size() >= 15:
		goals[0] = true
	if correct >= 6:
		goals[1] = true
	if removed.size() >= 5:
		goals[2] = true
	goal_l.text = "GOALS\n[%s]  Grow the heap to 15+ values\n[%s]  Make 6 correct swaps by hand (%d)\n[%s]  Remove the smallest 5 times (%d)" % [
		"x" if goals[0] else "  ", "x" if goals[1] else "  ", mini(correct, 6), "x" if goals[2] else "  ", mini(removed.size(), 5)]
	var count := goals.count(true)
	if count > 0:
		finish(count, count == 3)


func _busy() -> bool:
	if dir != 0:
		sfx("bad")
		_say("Finish the current percolation first: the white-ringed value is still out of place.")
		return true
	return false


func _fresh(lo: int, hi: int) -> int:
	var v := lo + randi() % (hi - lo + 1)
	var tries := 0
	while h.has(v) and tries < 300:
		v = lo + randi() % (hi - lo + 1)
		tries += 1
	return v


func _insert_value(v: int) -> void:
	if _busy():
		return
	if h.size() >= CAP:
		_say("The heap is full (%d). Remove some values or clear it." % CAP)
		return
	h.append(v)
	cur[v] = Vector2(640, 200)
	hole = h.size() - 1
	dir = 1
	swaps = 0
	wait = 0.5
	sfx("pop")
	_after_step("New value %d goes in the next free slot at the bottom. " % v)


func _insert_random() -> void:
	_insert_value(_fresh(1, 99))


func _insert_small() -> void:
	var smallest: int = 2 if h.is_empty() else maxi(int(h[0]) - 1, 0)
	_insert_value(_fresh(0, smallest) if smallest > 0 else 0)


func _remove_min() -> void:
	if _busy():
		return
	if h.is_empty():
		return
	var top: int = h[0]
	removed.append(top)
	float_text(_pos(0) + Vector2(-14, -40), str(top), UI.ACCENT, 26)
	sfx("ok", 1.1)
	var last: int = h.pop_back()
	cur.erase(top)
	if h.is_empty():
		_say("Removed %d. The heap is empty." % top)
		return
	h[0] = last
	hole = 0
	dir = 2
	swaps = 0
	wait = 0.6
	_after_step("Removed the root (%d). The LAST value, %d, is moved to the top to fill the gap. " % [top, last])


func _add_many() -> void:
	if _busy():
		return
	var k := mini(7, CAP - h.size())
	if k <= 0:
		_say("The heap is full (%d)." % CAP)
		return
	for i in k:
		var v := _fresh(1, 99)
		h.append(v)
		cur[v] = Vector2(640, 200)
	for i in range(h.size() / 2 - 1, -1, -1):
		var j := i
		while true:
			var c := 2 * j + 1
			if c >= h.size():
				break
			if c + 1 < h.size() and h[c + 1] < h[c]:
				c += 1
			if h[c] < h[j]:
				var tmp = h[j]
				h[j] = h[c]
				h[c] = tmp
				j = c
			else:
				break
	sfx("pop")
	_say("buildHeap: dump the values in, then fix every parent from the bottom up. Surprisingly this is O(n) in total, cheaper than n separate inserts at O(log n) each.")


func _toggle() -> void:
	manual = not manual
	_say(msg.text)


func _clear() -> void:
	h = []
	cur = {}
	dir = 0
	hole = -1
	_say("Empty heap.")


func _target() -> int:
	if dir == 1:
		if hole > 0 and h[hole] < h[(hole - 1) / 2]:
			return (hole - 1) / 2
	elif dir == 2:
		var c := 2 * hole + 1
		if c < h.size():
			if c + 1 < h.size() and h[c + 1] < h[c]:
				c += 1
			if h[c] < h[hole]:
				return c
	return -1


func _after_step(prefix: String) -> void:
	if _target() == -1:
		var height := int(floor(log(maxi(h.size(), 1)) / log(2.0)))
		_say(prefix + "Heap order holds after %d swap%s. The most it could ever take is the height of the tree: %d. That is the O(log n)." % [swaps, "" if swaps == 1 else "s", height])
		dir = 0
		hole = -1
		return
	if dir == 1:
		_say(prefix + "It is smaller than its parent, so it must rise. " + ("Click the node it should swap with." if manual else ""))
	else:
		_say(prefix + "It is bigger than a child, so it must sink. " + ("Click the node it should swap with." if manual else ""))


func _do_swap(tgt: int) -> void:
	var tmp = h[hole]
	h[hole] = h[tgt]
	h[tgt] = tmp
	hole = tgt
	swaps += 1
	sfx("tick", 1.0 + 0.15 * swaps)
	wait = 0.5
	_after_step("")


func tick(delta: float) -> void:
	var k := 1.0 - exp(-delta * 10.0)
	for i in h.size():
		var from: Vector2 = cur.get(h[i], _pos(i))
		cur[h[i]] = from.lerp(_pos(i), k)
	if dir != 0 and not manual:
		wait -= delta
		if wait <= 0.0:
			var tgt := _target()
			if tgt >= 0:
				_do_swap(tgt)


func _pos(i: int) -> Vector2:
	var level := int(floor(log(i + 1) / log(2.0) + 0.0001))
	var first := (1 << level) - 1
	var count := 1 << level
	return Vector2(40.0 + (i - first + 0.5) * 1200.0 / count, TOP + level * LEVEL_H)


func _gui_input(event: InputEvent) -> void:
	if dir == 0 or not manual:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in h.size():
			if _pos(i).distance_to(event.position) <= 23.0 and i != hole:
				if i == _target():
					correct += 1
					burst(_pos(i), tint, 14)
					_do_swap(i)
				else:
					sfx("bad")
					shake()
					if dir == 1:
						_say("Going up there is only one candidate: the parent. For the node at index i, the parent is at i / 2 (rounded down).")
					else:
						_say("Going down, swap with the SMALLER of the two children. Promote the bigger one and it would sit above its smaller sibling, breaking the heap.")
				return


func _strip(i: int) -> Rect2:
	return Rect2(51.0 + i * 38.0, STRIP_Y, 36, 40)


func _draw() -> void:
	var tgt_parent := -1
	var kids: Array = []
	if hole >= 0:
		tgt_parent = (hole - 1) / 2 if hole > 0 else -1
		for c in [2 * hole + 1, 2 * hole + 2]:
			if c < h.size():
				kids.append(c)
	for i in range(1, h.size()):
		var a: Vector2 = cur.get(h[i], _pos(i))
		var b: Vector2 = cur.get(h[(i - 1) / 2], _pos((i - 1) / 2))
		draw_line(a, b, Color(1, 1, 1, 0.22), 1.5, true)
	for i in h.size():
		var p: Vector2 = cur.get(h[i], _pos(i))
		var c := UI.hue(float(h[i]), 115.0, 0.62, 0.92)
		draw_circle(p, 21.0, c)
		if i == hole:
			draw_arc(p, 25.0 + sin(t * 7.0) * 1.5, 0.0, TAU, 32, UI.hot(Color.WHITE, 2.4), 3.0, true)
		elif i == 0:
			draw_arc(p, 25.0, 0.0, TAU, 32, UI.hot(UI.ACCENT, 1.6), 2.0, true)
		UI.ctext(self, p, str(h[i]), 16, UI.BG, "title")
	if not h.is_empty() and hole != 0:
		UI.text(self, _pos(0) + Vector2(34, 6), "smallest", 13, UI.hot(UI.ACCENT, 1.3))
	# the same heap as a flat array
	UI.text(self, Vector2(51, STRIP_Y - 10), "The same heap as a plain array. No pointers: for index i, parent = i / 2, children = 2i and 2i + 1.", 13, UI.DIM)
	for i in CAP:
		var r := _strip(i)
		if i < h.size():
			var c := UI.hue(float(h[i]), 115.0, 0.62, 0.92)
			UI.rrect(self, r, c, 6.0, UI.hot(Color.WHITE, 2.2) if i == hole else UI.CLEAR, 3.0 if i == hole else 0.0)
			UI.ctext(self, r.get_center(), str(h[i]), 14, UI.BG, "title")
			if i == tgt_parent:
				UI.text(self, Vector2(r.position.x, r.end.y + 30), "parent", 11, UI.hot(Color.WHITE, 1.3), HORIZONTAL_ALIGNMENT_CENTER, 36.0)
			elif kids.has(i):
				UI.text(self, Vector2(r.position.x, r.end.y + 30), "child", 11, UI.hot(Color.WHITE, 1.3), HORIZONTAL_ALIGNMENT_CENTER, 36.0)
		else:
			UI.rrect(self, r, UI.PANEL, 6.0, Color(1, 1, 1, 0.06), 1.0)
		UI.text(self, Vector2(r.position.x, r.end.y + 15), str(i + 1), 11, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER, 36.0)
	# removed values come out sorted
	if not removed.is_empty():
		UI.text(self, Vector2(51, 672), "Removed, in order:", 14, UI.DIM)
		var shown := removed.slice(maxi(0, removed.size() - 18))
		for j in shown.size():
			UI.text(self, Vector2(200 + j * 40.0, 673), str(shown[j]), 17, UI.hot(UI.ACCENT, 1.3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
		UI.text(self, Vector2(200 + shown.size() * 40.0 + 14, 672), "always sorted. Do this n times and you have heapsort.", 13, UI.DIM)


func demo() -> void:
	await main.click(Vector2(590, 112))
	await main.wait(0.8)
	await main.click(Vector2(268, 112))
	await main.wait(0.6)
	var tgt := _target()
	if tgt >= 0:
		await main.click(_pos(tgt))
	await main.wait(0.5)
