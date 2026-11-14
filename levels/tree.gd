extends "res://levels/level_base.gd"
# Tree Shape: a binary search tree is only fast if it stays bushy.

const MAX_NODES := 31
const AREA := Rect2(40, 262, 1200, 440)

class TNode:
	var v: int
	var l = null
	var r = null
	var h := 1
	func _init(val: int) -> void:
		v = val

var root = null
var order: Array = []      # values in insertion order, so we can rebuild either way
var balanced := false
var pos := {}              # value -> target Vector2
var cur := {}              # value -> animated Vector2
var path: Array = []       # values on the traced lookup path
var trace_at := 0.0
var goals := [false, false, false]

var stats: Label
var msg: Label
var goal_l: Label
var bal_btn: Button


func _ready() -> void:
	header("Chapter 19: binary search trees. Smaller goes left, bigger goes right.")
	UI.button(self, "Insert 1 random", Vector2(40, 92), Vector2(160, 40), _add_random.bind(1), 15, tint)
	UI.button(self, "Insert 15 random", Vector2(208, 92), Vector2(166, 40), _add_random.bind(15), 15, tint)
	UI.button(self, "Insert 15 in sorted order", Vector2(382, 92), Vector2(232, 40), _add_sorted, 15, tint)
	bal_btn = UI.button(self, "", Vector2(622, 92), Vector2(210, 40), _toggle, 15, tint)
	UI.button(self, "Clear", Vector2(840, 92), Vector2(80, 40), _clear, 15, tint)
	stats = UI.label(self, "", Vector2(40, 146), 20, UI.hot(tint, 1.25), 0.0, "title")
	msg = UI.label(self, "", Vector2(40, 182), 15, UI.INK, 880)
	goal_l = UI.label(self, "", Vector2(950, 96), 14, UI.DIM, 300)
	_refresh("A lookup walks down from the top, one comparison per level. So the cost of a lookup is the HEIGHT of the tree. Click any node to trace it.")


func _h(n) -> int:
	return 0 if n == null else n.h


func _upd(n) -> void:
	n.h = 1 + maxi(_h(n.l), _h(n.r))


func _rot_right(y):
	var x = y.l
	y.l = x.r
	x.r = y
	_upd(y)
	_upd(x)
	return x


func _rot_left(x):
	var y = x.r
	x.r = y.l
	y.l = x
	_upd(x)
	_upd(y)
	return y


func _insert(n, v: int):
	if n == null:
		return TNode.new(v)
	if v < n.v:
		n.l = _insert(n.l, v)
	elif v > n.v:
		n.r = _insert(n.r, v)
	else:
		return n
	_upd(n)
	if not balanced:
		return n
	var b := _h(n.l) - _h(n.r)
	if b > 1:
		if v > n.l.v:
			n.l = _rot_left(n.l)
		return _rot_right(n)
	if b < -1:
		if v < n.r.v:
			n.r = _rot_right(n.r)
		return _rot_left(n)
	return n


func _rebuild() -> void:
	root = null
	for v in order:
		root = _insert(root, v)


func _room() -> int:
	return MAX_NODES - order.size()


func _add_random(count: int) -> void:
	var k := mini(count, _room())
	if k <= 0:
		_refresh("The tree is full (%d values). Clear it to keep going." % MAX_NODES)
		return
	for i in k:
		var v := 1 + randi() % 999
		while order.has(v):
			v = 1 + randi() % 999
		order.append(v)
		root = _insert(root, v)
	path = []
	sfx("pop")
	_refresh("Random order usually gives a decent, slightly lopsided tree: height stays within a small multiple of log n.")


func _add_sorted() -> void:
	var k := mini(15, _room())
	if k <= 0:
		_refresh("The tree is full (%d values). Clear it to keep going." % MAX_NODES)
		return
	var v: int = 0 if order.is_empty() else order.max()
	for i in k:
		v += 1 + randi() % 9
		order.append(v)
		root = _insert(root, v)
	path = []
	sfx("pop")
	if balanced:
		_refresh("Same sorted input, but the tree rotates itself after each insert to stay bushy. Lookups stay at log n no matter what order the data arrives in.")
	else:
		_refresh("Each new value is bigger than everything before it, so it always goes right. The 'tree' is now a linked list and a lookup is O(n). Sorted input is very common in real data.")


func _toggle() -> void:
	balanced = not balanced
	_rebuild()
	path = []
	if balanced:
		_refresh("Balancing ON (AVL rules): if one side of any node gets 2 levels taller than the other, rotate. Same values, same arrival order, rebuilt with rotations.")
	else:
		_refresh("Balancing OFF: values land wherever the comparisons send them.")


func _clear() -> void:
	order = []
	root = null
	path = []
	_refresh("Empty tree.")


func _refresh(text: String) -> void:
	msg.text = text
	bal_btn.text = "Self-balancing: ON" if balanced else "Self-balancing: OFF"
	UI.select(bal_btn, balanced, tint)
	var n := order.size()
	var h := _h(root)
	if n == 0:
		stats.text = "0 values"
	else:
		var ideal := int(floor(log(n) / log(2.0))) + 1
		stats.text = "%d values      height %d  (best possible: %d)      worst lookup: %d steps" % [n, h, ideal, h]
	if h >= 10:
		goals[0] = true
	if n >= 15 and h <= 5:
		goals[1] = true
	goal_l.text = "GOALS\n[%s]  Build a tree at least 10 levels tall\n[%s]  Hold 15+ values in 5 levels or fewer\n[%s]  Click a node to trace a lookup" % [
		"x" if goals[0] else "  ", "x" if goals[1] else "  ", "x" if goals[2] else "  "]
	var count := goals.count(true)
	if count > 0:
		finish(count, count == 3)
	_layout()


func _layout() -> void:
	pos = {}
	var n := order.size()
	if n == 0:
		return
	var h := _h(root)
	var step := 60.0 if h <= 1 else minf(60.0, (AREA.size.y - 50) / (h - 1))
	var counter := [0]
	_place(root, 0, counter, n, step)


func _place(node, depth: int, counter: Array, n: int, step: float) -> void:
	if node == null:
		return
	_place(node.l, depth + 1, counter, n, step)
	pos[node.v] = Vector2(AREA.position.x + (counter[0] + 0.5) * AREA.size.x / n, AREA.position.y + 26 + depth * step)
	counter[0] += 1
	_place(node.r, depth + 1, counter, n, step)


func tick(delta: float) -> void:
	var k := 1.0 - exp(-delta * 9.0)
	for v in pos:
		var from: Vector2 = cur.get(v, Vector2(AREA.get_center().x, AREA.position.y - 10))
		cur[v] = from.lerp(pos[v], k)
	for v in cur.keys():
		if not pos.has(v):
			cur.erase(v)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for v in cur:
			if cur[v].distance_to(event.position) <= 19.0:
				_trace(v)
				return


func _trace(v: int) -> void:
	path = []
	var n = root
	while n != null:
		path.append(n.v)
		if v == n.v:
			break
		n = n.l if v < n.v else n.r
	trace_at = t
	goals[2] = true
	sfx("ok", 1.2)
	_refresh("Looking up %d took %d comparisons: one per level on the way down." % [v, path.size()])


func _lit(v: int) -> bool:
	var i := path.find(v)
	return i >= 0 and (t - trace_at) / 0.07 >= i


func _draw_edges(node) -> void:
	if node == null:
		return
	for c in [node.l, node.r]:
		if c != null:
			if cur.has(node.v) and cur.has(c.v):
				var on: bool = _lit(node.v) and _lit(c.v)
				draw_line(cur[node.v], cur[c.v], UI.hot(UI.WARN, 1.8) if on else Color(1, 1, 1, 0.22), 3.5 if on else 1.5, true)
			_draw_edges(c)


func _draw() -> void:
	UI.rrect(self, AREA, Color(0.04, 0.045, 0.075, 0.75), 14.0, Color(1, 1, 1, 0.06), 1.0)
	if root == null:
		UI.ctext(self, AREA.get_center(), "Insert some values to grow a tree", 18, UI.DIM)
		return
	_draw_edges(root)
	var base_c := tint if balanced else UI.BLUE
	for v in cur:
		var p: Vector2 = cur[v]
		var on := _lit(v)
		draw_circle(p, 17.0, UI.WARN if on else base_c.darkened(0.35))
		draw_arc(p, 17.0, 0.0, TAU, 28, UI.hot(UI.WARN, 2.0) if on else base_c, 1.5, true)
		UI.ctext(self, p, str(v), 13, UI.BG if on else UI.INK, "title")


func demo() -> void:
	await main.click(Vector2(480, 112))
	await main.wait(1.0)
	await main.click(pos[order[9]])
	await main.wait(0.6)
