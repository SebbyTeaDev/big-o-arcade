extends "res://levels/level_base.gd"
# Cheat Sheet: every cost from the game on one page.

const OPS := ["get #i", "find key", "insert", "remove", "smallest", "in order"]
const ROWS := [
	["Array (unsorted)", "1", "n", "1 at end", "n", "n", "n log n"],
	["Array (sorted)", "1", "log n", "n", "n", "1", "n"],
	["Linked list", "n", "n", "1 at ends", "1 at ends", "n", "n log n"],
	["Stack / queue", "-", "-", "1", "1", "-", "-"],
	["Hash table", "-", "1 avg", "1 avg", "1 avg", "n", "n log n"],
	["Balanced search tree", "-", "log n", "log n", "log n", "log n", "n"],
	["Binary heap", "-", "n", "log n", "log n (min)", "1", "n log n"],
	["Union-find (sets)", "-", "~1", "~1 merge", "-", "-", "-"],
]
const SORTS := [
	["Insertion sort", "n", "n²", "n²", "great on small or nearly-sorted data"],
	["Shellsort", "n log n", "~n^1.25", "~n^1.5", "insertion sort with long jumps first"],
	["Mergesort", "n log n", "n log n", "n log n", "predictable; needs extra memory"],
	["Quicksort", "n log n", "n log n", "n²", "fastest in practice; pick a good pivot"],
	["Heapsort", "n log n", "n log n", "n log n", "no extra memory, no bad cases"],
]
const RULES := [
	"Loops in a row add. Loops nested multiply.",
	"Halving or doubling means log n.",
	"Drop constants; keep the biggest term.",
	"Library calls can hide a loop: includes, indexOf, find, shift, sort.",
	"Find-inside-a-loop? Build a Map or Set first.",
	"Sorted data unlocks binary search and range queries.",
	"Need the smallest, again and again? Heap.",
	"Recomputing the same answers? Cache them.",
	"A million items: log n is 20, n log n is 20 million, n² is a trillion.",
]


func _ready() -> void:
	header("Everything in the game on one page")


func _col(s: String) -> Color:
	if s == "-":
		return Color(1, 1, 1, 0.18)
	if s.begins_with("1") or s.begins_with("~1"):
		return UI.ACCENT
	if s.begins_with("log n"):
		return UI.BLUE
	if s.begins_with("n log n"):
		return Color("ff9a4d")
	if s.begins_with("~n"):
		return UI.BAD
	if s.begins_with("n²"):
		return UI.BAD
	return UI.WARN


func _draw() -> void:
	# structures
	UI.rrect(self, Rect2(40, 92, 800, 336), UI.PANEL, 14.0, Color(1, 1, 1, 0.07), 1.0)
	UI.text(self, Vector2(60, 118), "DATA STRUCTURES", 13, UI.DIM)
	for c in OPS.size():
		UI.text(self, Vector2(262 + c * 96, 118), OPS[c], 13, UI.DIM)
	for r in ROWS.size():
		var y := 150.0 + r * 34.0
		if r % 2 == 0:
			UI.rrect(self, Rect2(48, y - 22, 784, 32), Color(1, 1, 1, 0.03), 6.0)
		UI.text(self, Vector2(60, y), ROWS[r][0], 15, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
		for c in OPS.size():
			var s: String = ROWS[r][c + 1]
			UI.text(self, Vector2(262 + c * 96, y), s, 14, UI.hot(_col(s), 1.2))
	# sorts
	UI.rrect(self, Rect2(40, 440, 800, 262), UI.PANEL, 14.0, Color(1, 1, 1, 0.07), 1.0)
	UI.text(self, Vector2(60, 466), "SORTING", 13, UI.DIM)
	var heads := ["best", "average", "worst"]
	for c in 3:
		UI.text(self, Vector2(230 + c * 100, 466), heads[c], 13, UI.DIM)
	for r in SORTS.size():
		var y := 500.0 + r * 40.0
		if r % 2 == 0:
			UI.rrect(self, Rect2(48, y - 24, 784, 36), Color(1, 1, 1, 0.03), 6.0)
		UI.text(self, Vector2(60, y), SORTS[r][0], 15, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
		for c in 3:
			var s: String = SORTS[r][c + 1]
			UI.text(self, Vector2(230 + c * 100, y), s, 14, UI.hot(_col(s), 1.2))
		UI.text(self, Vector2(540, y), SORTS[r][4], 13, UI.DIM)
	# rules of thumb
	UI.rrect(self, Rect2(856, 92, 384, 610), UI.PANEL, 14.0, Color(1, 1, 1, 0.07), 1.0)
	UI.text(self, Vector2(876, 118), "RULES OF THUMB", 13, UI.DIM)
	var y := 152.0
	for i in RULES.size():
		draw_circle(Vector2(884, y - 5), 4.0, UI.hot(UI.hue(i, RULES.size()), 1.5))
		draw_multiline_string(UI.font(), Vector2(900, y), RULES[i], HORIZONTAL_ALIGNMENT_LEFT, 322.0, 15, 3, UI.INK)
		y += 62.0
