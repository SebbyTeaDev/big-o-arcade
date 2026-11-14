extends "res://levels/level_base.gd"
# Sort Lab: six sorts replay their recorded steps at the same steps-per-second.

const NAMES := ["Insertion sort", "Shellsort", "Mergesort", "Quicksort, first pivot", "Quicksort, median of 3", "Heapsort"]
const NOTES := ["O(n²), but O(n) if nearly sorted", "roughly O(n^1.25) in practice", "O(n log n) always", "O(n log n) avg, O(n²) worst", "O(n log n) in practice", "O(n log n) always, no extra memory"]
const SIZES := [16, 64, 256]
const ORDERS := ["Random", "Already sorted", "Reversed", "Nearly sorted"]
const LESSONS := [
	"Random input: insertion sort does about n²/4 comparisons while the n log n sorts barely notice. Quadruple n and run again: insertion sort gets ~16x slower, mergesort only ~5x. Shellsort is insertion sort with long jumps first, and that one idea closes most of the gap.",
	"Already sorted: insertion sort's best case, one comparison per item, O(n). And naive quicksort's worst: with the first item as pivot every split is 0 vs n-1, so it degrades to O(n²). Median-of-three fixes the pivot.",
	"Reversed: the worst case for insertion sort (every item travels the whole way) and again for first-pivot quicksort. Mergesort and heapsort do the same work whatever the input looks like.",
	"Nearly sorted: only a few items are out of place, so insertion sort is close to linear. This is why real library sorts hand small or nearly-sorted pieces to insertion sort.",
]

var n := 64
var order := 0
var base: Array = []
var disp: Array = []
var ops: Array = []
var pos: Array = []
var hot_idx: Array = []
var finished: Array = []
var running := false
var ran := false
var bet := -1
var rate := 60.0
var acc := 0.0
var beep := 0.0
var seen_orders := {}
var seen_sizes := {}

var size_btns: Array = []
var order_btns: Array = []
var go_btn: Button
var result: Label


func _ready() -> void:
	header("Chapter 9: same data, same speed per step. Only the step counts differ.")
	UI.label(self, "Items", Vector2(40, 100), 15, UI.DIM)
	for i in SIZES.size():
		size_btns.append(UI.button(self, str(SIZES[i]), Vector2(92 + i * 70, 92), Vector2(62, 38), _pick_size.bind(i), 16, tint))
	UI.label(self, "Starting order", Vector2(326, 100), 15, UI.DIM)
	for i in ORDERS.size():
		order_btns.append(UI.button(self, ORDERS[i], Vector2(440 + i * 150, 92), Vector2(142, 38), _pick_order.bind(i), 15, tint))
	go_btn = UI.button(self, "Race!", Vector2(1100, 88), Vector2(140, 46), _start, 20, tint)
	UI.label(self, "Click a panel to bet on the winner, then press Race. Sound follows your bet.", Vector2(40, 140), 14, UI.DIM)
	result = UI.label(self, "", Vector2(40, 546), 15, UI.INK, 1200)
	for i in 6:
		disp.append([])
		ops.append([])
		pos.append(0)
		hot_idx.append([-1, -1])
	_make_data()


func _pick_size(i: int) -> void:
	if running:
		return
	n = SIZES[i]
	_make_data()


func _pick_order(i: int) -> void:
	if running:
		return
	order = i
	_make_data()


func _make_data() -> void:
	base = range(1, n + 1)
	match order:
		0:
			base.shuffle()
		2:
			base.reverse()
		3:
			for k in maxi(1, n / 16):
				var a := randi() % n
				var b := mini(n - 1, a + 1 + randi() % 4)
				var tmp = base[a]
				base[a] = base[b]
				base[b] = tmp
	for i in 6:
		disp[i] = base.duplicate()
		ops[i] = []
		pos[i] = 0
		hot_idx[i] = [-1, -1]
	finished = []
	ran = false
	result.text = ""
	for i in size_btns.size():
		UI.select(size_btns[i], SIZES[i] == n, tint)
	for i in order_btns.size():
		UI.select(order_btns[i], i == order, tint)


func _start() -> void:
	if running:
		return
	if ran:
		_make_data()
	for i in 6:
		var a := base.duplicate()
		var o: Array = []
		match i:
			0: _insertion(a, o)
			1: _shell(a, o)
			2:
				var tmp := a.duplicate()
				_merge(a, tmp, 0, n - 1, o)
			3: _quick(a, 0, n - 1, o, false)
			4: _quick(a, 0, n - 1, o, true)
			5: _heapsort(a, o)
		ops[i] = o
	var longest := 0
	for i in 6:
		longest = maxi(longest, ops[i].size())
	rate = maxf(longest / 9.0, 40.0)
	acc = 0.0
	running = true
	go_btn.disabled = true


# --- the algorithms, recording [0, i, j] for a comparison and [1, i, value] for a write ---

func _insertion(a: Array, o: Array) -> void:
	for p in range(1, a.size()):
		var tmp = a[p]
		var j := p
		while j > 0:
			o.append([0, j - 1, j])
			if a[j - 1] > tmp:
				a[j] = a[j - 1]
				o.append([1, j, a[j]])
				j -= 1
			else:
				break
		a[j] = tmp
		o.append([1, j, tmp])


func _shell(a: Array, o: Array) -> void:
	var gap := a.size() / 2
	while gap > 0:
		for i in range(gap, a.size()):
			var tmp = a[i]
			var j := i
			while j >= gap:
				o.append([0, j - gap, j])
				if a[j - gap] > tmp:
					a[j] = a[j - gap]
					o.append([1, j, a[j]])
					j -= gap
				else:
					break
			a[j] = tmp
			o.append([1, j, tmp])
		gap = 1 if gap == 2 else int(gap / 2.2)


func _merge(a: Array, tmp: Array, lo: int, hi: int, o: Array) -> void:
	if lo >= hi:
		return
	var mid := (lo + hi) >> 1
	_merge(a, tmp, lo, mid, o)
	_merge(a, tmp, mid + 1, hi, o)
	var i := lo
	var j := mid + 1
	var k := lo
	while i <= mid and j <= hi:
		o.append([0, i, j])
		if a[i] <= a[j]:
			tmp[k] = a[i]
			i += 1
		else:
			tmp[k] = a[j]
			j += 1
		k += 1
	while i <= mid:
		tmp[k] = a[i]
		i += 1
		k += 1
	while j <= hi:
		tmp[k] = a[j]
		j += 1
		k += 1
	for x in range(lo, hi + 1):
		a[x] = tmp[x]
		o.append([1, x, a[x]])


func _swap(a: Array, i: int, j: int, o: Array) -> void:
	if i == j:
		return
	var tmp = a[i]
	a[i] = a[j]
	a[j] = tmp
	o.append([1, i, a[i]])
	o.append([1, j, a[j]])


func _quick(a: Array, lo: int, hi: int, o: Array, med3: bool) -> void:
	if lo >= hi:
		return
	if med3 and hi - lo >= 2:
		var mid := (lo + hi) >> 1
		o.append([0, lo, mid])
		if a[mid] < a[lo]:
			_swap(a, lo, mid, o)
		o.append([0, lo, hi])
		if a[hi] < a[lo]:
			_swap(a, lo, hi, o)
		o.append([0, mid, hi])
		if a[hi] < a[mid]:
			_swap(a, mid, hi, o)
		_swap(a, lo, mid, o)  # median becomes the pivot
	var pivot = a[lo]
	var i := lo
	for j in range(lo + 1, hi + 1):
		o.append([0, j, lo])
		if a[j] < pivot:
			i += 1
			_swap(a, i, j, o)
	_swap(a, lo, i, o)
	_quick(a, lo, i - 1, o, med3)
	_quick(a, i + 1, hi, o, med3)


func _sift(a: Array, i: int, size_now: int, o: Array) -> void:
	while true:
		var c := 2 * i + 1
		if c >= size_now:
			break
		if c + 1 < size_now:
			o.append([0, c, c + 1])
			if a[c + 1] > a[c]:
				c += 1
		o.append([0, i, c])
		if a[c] > a[i]:
			_swap(a, i, c, o)
			i = c
		else:
			break


func _heapsort(a: Array, o: Array) -> void:
	var m := a.size()
	for i in range(m / 2 - 1, -1, -1):
		_sift(a, i, m, o)
	for end in range(m - 1, 0, -1):
		_swap(a, 0, end, o)
		_sift(a, 0, end, o)


func tick(delta: float) -> void:
	if not running:
		return
	acc += rate * delta
	var k := int(acc)
	acc -= k
	for i in 6:
		var o: Array = ops[i]
		var end := mini(pos[i] + k, o.size())
		for x in range(pos[i], end):
			var op: Array = o[x]
			if op[0] == 1:
				disp[i][op[1]] = op[2]
				hot_idx[i] = [op[1], -1]
			else:
				hot_idx[i] = [op[1], op[2]]
		pos[i] = end
		if end >= o.size() and not finished.has(i):
			finished.append(i)
			hot_idx[i] = [-1, -1]
			sfx("ok", 0.8 + 0.12 * finished.size())
	beep -= delta
	if beep <= 0.0:
		beep = 0.045
		var listen := bet
		if listen < 0 or finished.has(listen):
			listen = -1
			for i in 6:
				if not finished.has(i):
					listen = i
					break
		if listen >= 0 and hot_idx[listen][0] >= 0:
			sfx("tick", 0.5 + 1.8 * float(disp[listen][hot_idx[listen][0]]) / n)
	if finished.size() == 6:
		running = false
		ran = true
		go_btn.disabled = false
		seen_orders[order] = true
		seen_sizes[n] = true
		var stars := 1
		if seen_orders.size() >= 2:
			stars = 2
		if seen_orders.size() >= 3 and seen_sizes.size() >= 2:
			stars = 3
		finish(stars, stars == 3)
		var win: int = finished[0]
		var last: int = finished[5]
		var head := "%s wins with %s steps; %s needed %s." % [NAMES[win], UI.fmt(ops[win].size()), NAMES[last], UI.fmt(ops[last].size())]
		if bet >= 0:
			head = ("Your bet paid off. " if ops[bet].size() == ops[win].size() else "Your bet lost. ") + head
		result.text = head + "\n" + LESSONS[order]
		if stars < 3:
			result.text += "\nFor three stars: try three different starting orders and two sizes (%d of 3 orders, %d of 2 sizes so far)." % [mini(seen_orders.size(), 3), mini(seen_sizes.size(), 2)]


func _panel(i: int) -> Rect2:
	return Rect2(40 + (i % 3) * 404, 170 + (i / 3) * 186, 392, 174)


func _gui_input(event: InputEvent) -> void:
	if running:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in 6:
			if _panel(i).has_point(event.position):
				bet = i
				sfx("click")


func _draw() -> void:
	for i in 6:
		var r := _panel(i)
		var is_done := finished.has(i)
		UI.rrect(self, r, Color("0f111b"), 12.0, UI.hot(Color.WHITE, 1.3) if i == bet else Color(1, 1, 1, 0.07), 2.0 if i == bet else 1.0)
		var bw := (r.size.x - 16.0) / n
		var maxh := r.size.y - 54.0
		for x in n:
			var v: float = float(disp[i][x])
			var h := v / n * maxh
			var c := UI.hue(v, n * 1.15, 0.7, 0.9)
			if is_done:
				c = UI.hot(c, 1.35)
			elif x == hot_idx[i][0] or x == hot_idx[i][1]:
				c = UI.hot(Color.WHITE, 2.0)
			draw_rect(Rect2(r.position.x + 8.0 + x * bw, r.end.y - 8.0 - h, maxf(bw - (1.0 if n <= 64 else 0.0), 1.0), h), c)
		UI.text(self, r.position + Vector2(12, 22), NAMES[i], 16, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
		UI.text(self, r.position + Vector2(12, 40), NOTES[i], 12, UI.DIM)
		var txt := UI.fmt(pos[i]) + " steps"
		if is_done:
			txt = "#%d   " % (finished.find(i) + 1) + txt
		UI.text(self, r.position + Vector2(r.size.x - 212, 22), txt, 15, UI.hot(UI.WARN, 1.3) if is_done else UI.DIM, HORIZONTAL_ALIGNMENT_RIGHT, 200.0, "title")
		if i == bet:
			UI.text(self, r.position + Vector2(r.size.x - 212, 40), "your bet", 12, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 200.0)


func demo() -> void:
	await main.click(_panel(2).get_center())
	await main.click(go_btn.position + Vector2(40, 20))
	await main.wait(8.2)
