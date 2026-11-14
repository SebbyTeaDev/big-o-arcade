extends "res://levels/level_base.gd"
# Challenge the AI: an assistant hands over code with a confident claim. Approve or push back.

const CASES := [
	{"code": "function dedupe(emails) {\n  const out = []\n  for (const e of emails) {\n    if (!out.includes(e)) out.push(e)\n  }\n  return out\n}",
		"claim": "One loop over the list, so this is O(n). Ship it.", "ok": false,
		"say": "includes() is a second loop hiding inside the first: O(n²). Ask for a Set, which makes each check about 1 step and the whole thing O(n)."},
	{"code": "const byId = new Map(users.map(u => [u.id, u]))\n\nfunction getUser(id) {\n  return byId.get(id)\n}",
		"claim": "Building the map costs O(n) once. After that every lookup is O(1).", "ok": true,
		"say": "Correct. Pay O(n) once to build a hash map, then each lookup is about one step. This is the standard fix for 'find inside a loop'."},
	{"code": "function has(items, target) {\n  items.sort((a, b) => a - b)\n  return binarySearch(items, target) !== -1\n}",
		"claim": "I sort first so I can binary search. O(log n), much faster than scanning.", "ok": false,
		"say": "The sort costs O(n log n) every single call, which is worse than one plain O(n) scan. Sorting only pays off if you sort ONCE and then search many times."},
	{"code": "function fib(n) {\n  if (n < 2) return n\n  return fib(n - 1) + fib(n - 2)\n}",
		"claim": "Simple recursion, one call per number down to zero: O(n).", "ok": false,
		"say": "Each call makes TWO more calls, so it is O(2^n). fib(50) would take billions of calls. Ask for memoization or a loop: both are O(n)."},
	{"code": "const queue = [...jobs]\nwhile (queue.length > 0) {\n  const job = queue.shift()\n  run(job)\n}",
		"claim": "Each job is handled once, so the loop is O(n).", "ok": false,
		"say": "shift() removes from the FRONT of an array, which slides every other item left: O(n) each time, O(n²) overall. Use an index that walks forward, or a real queue."},
	{"code": "for (const order of orders) {\n  for (let d = 0; d < 7; d++) {\n    tally[d] += order.byDay[d]\n  }\n}",
		"claim": "There is a nested loop, but the inner one is always 7. This is O(n).", "ok": true,
		"say": "Correct. A nested loop is only quadratic when BOTH bounds grow with the input. 7n is O(n)."},
	{"code": "for (const order of orders) {\n  const p = products.find(p => p.id === order.productId)\n  order.price = p.price\n}",
		"claim": "A single pass over the orders: O(n).", "ok": false,
		"say": "find() scans products for every order: O(orders x products). Build a Map of products by id first, then it really is one pass."},
	{"code": "function count(words) {\n  const freq = {}\n  for (const w of words) {\n    freq[w] = (freq[w] || 0) + 1\n  }\n  return freq\n}",
		"claim": "One pass with a hash lookup per word: O(n).", "ok": true,
		"say": "Correct. Object and Map lookups by key are about one step, so one pass really is O(n)."},
	{"code": "let total = 0\nfor (const a of listA) total += a\nfor (const b of listB) total += b",
		"claim": "Careful, there are two loops here, so this is O(n²).", "ok": false,
		"say": "Push back the other way: it is being too pessimistic. Loops in a ROW add (n + n = 2n = O(n)). Only loops INSIDE each other multiply."},
	{"code": "// ids arrive already sorted: 1, 2, 3, 4, ...\nconst tree = new BinarySearchTree()\nfor (const id of ids) tree.insert(id)\n\ntree.find(someId)",
		"claim": "It is a binary search tree, so find() is O(log n).", "ok": false,
		"say": "Only if the tree is balanced. Sorted input makes a plain BST into a linked list, so find() is O(n). Ask for a self-balancing tree (AVL, red-black) or just a sorted array."},
	{"code": "function topTen(scores, incoming) {\n  scores.push(incoming)\n  scores.sort((a, b) => b - a)\n  return scores.slice(0, 10)\n}",
		"claim": "Called once per new score. Sorting keeps it simple and efficient.", "ok": false,
		"say": "It re-sorts everything, O(n log n), on every new score. A heap that holds just the best ten handles each score in O(log 10), and never looks at the rest."},
	{"code": "function findWord(sortedWords, w) {\n  let lo = 0, hi = sortedWords.length - 1\n  while (lo <= hi) {\n    const mid = (lo + hi) >> 1\n    if (sortedWords[mid] === w) return mid\n    if (sortedWords[mid] < w) lo = mid + 1\n    else hi = mid - 1\n  }\n  return -1\n}",
		"claim": "The list is already sorted, so this binary search is O(log n).", "ok": true,
		"say": "Correct. The data is sorted ONCE elsewhere, and each search halves the range. A million words: 20 looks."},
]

var ci := 0
var score := 0
var answered := false
var over := false
var typed_at := 0.0

var code_label: RichTextLabel
var progress: Label
var claim: Label
var feedback: Label
var approve_btn: Button
var push_btn: Button
var next_btn: Button


func _ready() -> void:
	header("The reason to learn all this: knowing when to say 'are you sure?'")
	progress = UI.label(self, "", Vector2(40, 90), 17, UI.DIM)
	code_label = UI.code(self, Rect2(40, 124, 700, 300), 17)
	UI.label(self, "THE ASSISTANT SAYS", Vector2(790, 132), 13, UI.DIM)
	claim = UI.label(self, "", Vector2(790, 160), 20, UI.INK, 430, "title")
	approve_btn = UI.button(self, "Looks right, approve", Vector2(790, 330), Vector2(210, 56), _answer.bind(true), 17, UI.ACCENT)
	push_btn = UI.button(self, "Push back", Vector2(1012, 330), Vector2(210, 56), _answer.bind(false), 17, UI.BAD)
	feedback = UI.label(self, "", Vector2(40, 450), 18, UI.INK, 1180)
	next_btn = UI.button(self, "Next", Vector2(1080, 646), Vector2(160, 48), _next, 18, tint)
	_show()


func _show() -> void:
	answered = false
	typed_at = t
	var c: Dictionary = CASES[ci]
	progress.text = "Review %d of %d          Score: %d" % [ci + 1, CASES.size(), score]
	code_label.text = UI.highlight(c["code"])
	claim.text = c["claim"]
	feedback.text = ""
	next_btn.visible = false
	approve_btn.visible = true
	push_btn.visible = true
	for b in [approve_btn, push_btn]:
		b.disabled = false
		b.modulate = Color.WHITE


func tick(_delta: float) -> void:
	claim.visible_ratio = clampf((t - typed_at) / 0.9, 0.0, 1.0)


func _answer(approve: bool) -> void:
	if answered or over:
		return
	answered = true
	var c: Dictionary = CASES[ci]
	var right: bool = approve == c["ok"]
	approve_btn.disabled = true
	push_btn.disabled = true
	var good := approve_btn if c["ok"] else push_btn
	var other := push_btn if c["ok"] else approve_btn
	good.modulate = UI.hot(UI.ACCENT, 1.5)
	other.modulate = Color(1, 1, 1, 0.35)
	if right:
		score += 1
		sfx("ok")
		burst(good.position + good.size / 2.0, UI.ACCENT, 28)
		feedback.text = ("Good call.  " if c["ok"] else "Good catch.  ") + c["say"]
		feedback.add_theme_color_override("font_color", UI.ACCENT)
	else:
		sfx("bad")
		shake()
		feedback.text = ("That one was actually fine.  " if c["ok"] else "That claim was wrong.  ") + c["say"]
		feedback.add_theme_color_override("font_color", UI.WARN)
	progress.text = "Review %d of %d          Score: %d" % [ci + 1, CASES.size(), score]
	next_btn.text = "Next" if ci < CASES.size() - 1 else "Finish"
	next_btn.visible = true


func _next() -> void:
	if over:
		over = false
		ci = 0
		score = 0
		_show()
		return
	if ci < CASES.size() - 1:
		ci += 1
		_show()
		return
	over = true
	finish(3 if score >= CASES.size() - 1 else (2 if score >= 8 else 1))
	progress.text = "Final score: %d / %d" % [score, CASES.size()]
	code_label.text = "Questions worth asking of any code, yours or a model's:\n\n  1. What is n here, and how big does it get?\n  2. Is there a loop hiding inside a library call?\n     (includes, indexOf, find, shift, sort)\n  3. Does this repeat work it already did?\n  4. Would a Map, Set, heap or sorted array\n     turn the inner step into 1 or log n?\n  5. What is the WORST input for this?"
	claim.text = "You don't need to out-code the assistant. You need to know which claims to check."
	typed_at = t
	feedback.text = ""
	approve_btn.visible = false
	push_btn.visible = false
	next_btn.text = "Play again"


func _draw() -> void:
	UI.rrect(self, Rect2(770, 124, 470, 190), UI.PANEL2, 16.0, UI.hot(tint, 1.2), 1.5)


func demo() -> void:
	ci = 4
	_show()
	await main.wait(1.0)
	await main.click(push_btn.position + Vector2(60, 28))
	await main.wait(0.5)
