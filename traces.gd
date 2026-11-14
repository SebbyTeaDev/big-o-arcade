extends RefCounted
# Execution traces for the step-through code viewer.
#
# Each generator "runs" a snippet for a small input and records one entry per executed
# line: which line, what the variables and data look like, a plain-English note, and how
# many units of work have been counted so far. An id may carry a variant: "bsearch:1".

const BASE := [7, 3, 9, 1, 8, 4, 6, 2, 12, 15, 10, 14, 11, 16, 13, 5]

const INFO := {
	"loop": {"title": "One pass over a list", "sizes": [4, 8, 16], "o": "O(n)", "n": "items in the list"},
	"indexof": {"title": "indexOf inside a loop", "sizes": [4, 8, 16], "o": "O(n²)", "n": "items in the list"},
	"first": {"title": "Reading one slot", "sizes": [4, 8, 16], "o": "O(1)", "n": "items in the list"},
	"bsearch": {"title": "Binary search", "sizes": [4, 8, 16], "o": "O(log n)", "n": "items in the sorted list"},
	"nested": {"title": "A loop inside a loop", "sizes": [4, 8, 16], "o": "O(n²)", "n": "n"},
	"doubling": {"title": "A loop that doubles", "sizes": [8, 64, 512], "o": "O(log n)", "n": "n"},
	"sethas": {"title": "Set lookups in a loop", "sizes": [4, 8, 16], "o": "O(n)", "n": "items in each list"},
	"twoloops": {"title": "Two loops in a row", "sizes": [4, 8, 16], "o": "O(n)", "n": "items in each list"},
	"innerconst": {"title": "A fixed-size inner loop", "sizes": [2, 4, 8], "o": "O(n)", "n": "items in the outer list"},
	"triangular": {"title": "Every pair, once", "sizes": [4, 8, 16], "o": "O(n²)", "n": "items in the list"},
	"sortloop": {"title": "Sort, then one pass", "sizes": [4, 8, 16], "o": "O(n log n)", "n": "items in the list"},
	"nqueries": {"title": "A binary search per query", "sizes": [4, 8, 16], "o": "O(n log n)", "n": "queries, and items"},
	"dedupe": {"title": "De-dupe with includes", "sizes": [4, 8, 16], "o": "O(n²)", "n": "items in the list"},
	"fib": {"title": "Recursive fib", "sizes": [3, 5, 7], "o": "O(2^n)", "n": "n"},
	"fibmemo": {"title": "fib that remembers its answers", "sizes": [3, 5, 7], "o": "O(n)", "n": "n"},
	"mapget": {"title": "Lookups in a Map", "sizes": [4, 8, 16], "o": "O(1) per lookup", "n": "users in the map"},
	"sortsearch": {"title": "Sorting before every search", "sizes": [4, 8, 16], "o": "O(n log n) per call", "n": "items in the list"},
	"shift": {"title": "A queue built on shift()", "sizes": [4, 8, 16], "o": "O(n²)", "n": "jobs in the queue"},
	"find": {"title": "find() inside a loop", "sizes": [4, 8, 16], "o": "O(n²) when both lists grow", "n": "orders, and products"},
	"countwords": {"title": "Counting with a hash map", "sizes": [4, 8, 16], "o": "O(n)", "n": "words"},
	"bstsorted": {"title": "A search tree fed sorted data", "sizes": [4, 8, 16], "o": "O(n) per find", "n": "ids in the tree"},
	"topten": {"title": "Re-sorting for a top ten", "sizes": [4, 8, 16], "o": "O(n log n) per new score", "n": "scores so far"},
	"unshift": {"title": "Inserting at the front of an array", "sizes": [4, 8, 16], "o": "O(n)", "n": "items in the array"},
	"brackets": {"title": "The bracket checker", "sizes": [4, 8, 16], "o": "O(n)", "n": "symbols in the text"},
	"insertion": {"title": "Insertion sort", "sizes": [4, 8, 16], "o": "O(n²)", "n": "items in the list"},
	"bstfind": {"title": "Lookup in a balanced search tree", "sizes": [7, 15, 31], "o": "O(log n)", "n": "keys in the tree"},
	"hashprobe": {"title": "Hash insert with linear probing", "sizes": [2, 5, 7], "o": "O(1) when roomy, O(n) when crowded", "n": "keys already in an 8-slot table"},
	"percolate": {"title": "Heap insert: percolate up", "sizes": [7, 15, 31], "o": "O(log n)", "n": "values in the heap"},
	"bfs": {"title": "Breadth-first search", "sizes": [4, 6, 8], "o": "O(nodes + edges)", "n": "nodes in the graph"},
	"unionfind": {"title": "Union-find", "sizes": [4, 8, 16], "o": "close to O(1) per operation", "n": "items"},
}


class Tr:
	var code := ""
	var off := 0
	var steps: Array = []
	var ops := 0
	var vars := {}
	var arrs := {}
	var marks := {}
	var dim := {}
	var grid := {}
	var stack: Array = []
	var stack_title := ""

	func at(line: int, note: String, count: int = 0, hl: Dictionary = {}, hidden: bool = false) -> void:
		ops += count
		steps.append({
			"line": line + off, "note": note, "ops": ops, "count": count, "hidden": hidden, "hl": hl,
			"vars": vars.duplicate(), "arrs": arrs.duplicate(true), "marks": marks.duplicate(true),
			"dim": dim.duplicate(true), "grid": grid.duplicate(true), "stack": stack.duplicate(), "stack_title": stack_title,
		})


static func base_id(id: String) -> String:
	return id.get_slice(":", 0)


static func info(id: String) -> Dictionary:
	return INFO[base_id(id)]


static func build(id: String, n: int) -> Tr:
	var tr := Tr.new()
	var v := int(id.get_slice(":", 1)) if id.contains(":") else 0
	match base_id(id):
		"loop": _loop(tr, n)
		"indexof": _indexof(tr, n)
		"first": _first(tr, n)
		"bsearch": _bsearch(tr, n, v)
		"nested": _nested(tr, n)
		"doubling": _doubling(tr, n)
		"sethas": _sethas(tr, n)
		"twoloops": _twoloops(tr, n)
		"innerconst": _innerconst(tr, n, v)
		"triangular": _triangular(tr, n)
		"sortloop": _sortloop(tr, n)
		"nqueries": _nqueries(tr, n)
		"dedupe": _dedupe(tr, n, v)
		"fib": _fib_top(tr, n)
		"fibmemo": _fibmemo_top(tr, n)
		"mapget": _mapget(tr, n)
		"sortsearch": _sortsearch(tr, n)
		"shift": _shift(tr, n)
		"find": _find(tr, n)
		"countwords": _countwords(tr, n)
		"bstsorted": _bstsorted(tr, n)
		"topten": _topten(tr, n)
		"unshift": _unshift(tr, n)
		"brackets": _brackets(tr, n)
		"insertion": _insertion(tr, n)
		"bstfind": _bstfind(tr, n)
		"hashprobe": _hashprobe(tr, n)
		"percolate": _percolate(tr, n)
		"bfs": _bfs(tr, n)
		"unionfind": _unionfind(tr, n)
	return tr


static func code_for(id: String) -> String:
	return build(id, int(info(id)["sizes"][0])).code


# ---------- helpers ----------

static func _vals(n: int) -> Array:
	return BASE.slice(0, n)


static func _sorted(n: int) -> Array:
	var a: Array = []
	for i in n:
		a.append(3 * i + 2)
	return a


static func _lg(n: int) -> int:
	return int(round(n * log(maxi(n, 2)) / log(2.0)))


static func _indent(s: String) -> String:
	return "  " + s.replace("\n", "\n  ")


# Records the probes of a binary search that happens inside a library call.
static func _probe(tr: Tr, arr_name: String, a: Array, target: int, line: int, label: String) -> void:
	var lo := 0
	var hi := a.size() - 1
	while lo <= hi:
		var mid := (lo + hi) >> 1
		tr.dim[arr_name] = [lo, hi]
		tr.marks[arr_name] = {"mid": mid}
		if a[mid] == target:
			tr.at(line, "Inside %s: the middle of what is left is %d. Found it." % [label, a[mid]], 1, {arr_name: [mid]}, true)
			break
		tr.at(line, "Inside %s: the middle of what is left is %d, too %s. Half the range is gone." % [label, a[mid], "small" if a[mid] < target else "big"], 1, {arr_name: [mid]}, true)
		if a[mid] < target:
			lo = mid + 1
		else:
			hi = mid - 1
	tr.dim.erase(arr_name)
	tr.marks.erase(arr_name)


# ---------- Count the Loops ----------

static func _loop(tr: Tr, n: int) -> void:
	tr.code = "for (const x of arr) {\n  console.log(x)\n}"
	var a := _vals(n)
	tr.arrs["arr"] = a
	for i in n:
		tr.vars["x"] = a[i]
		tr.marks["arr"] = {"x": i}
		tr.at(0, "Take the next item from arr: x = %d." % a[i])
		tr.at(1, "Print x. That is one step of work.", 1, {"arr": [i]})
	tr.at(2, "The loop body ran once per item: %d items, %d steps." % [n, tr.ops])


static func _indexof(tr: Tr, n: int) -> void:
	tr.code = "for (const x of arr) {\n  const i = arr.indexOf(x)\n  console.log(i)\n}"
	var a := _vals(n)
	tr.arrs["arr"] = a
	for p in n:
		tr.vars["x"] = a[p]
		tr.marks["arr"] = {"x": p}
		tr.at(0, "Outer loop: x = %d." % a[p])
		for k in p + 1:
			tr.marks["arr"] = {"x": p, "k": k}
			tr.at(1, "Inside indexOf there is a loop you cannot see. Is arr[%d] equal to %d? %s" % [k, a[p], "Yes, found it." if k == p else "No, keep scanning."], 1, {"arr": [k]}, true)
		tr.vars["i"] = p
		tr.marks["arr"] = {"x": p}
		tr.at(2, "Print i = %d." % p)
	tr.at(3, "One visible loop, but indexOf scanned further each time: %d steps for %d items." % [tr.ops, n])


static func _first(tr: Tr, n: int) -> void:
	tr.code = "function first(arr) {\n  return arr[0]\n}"
	tr.arrs["arr"] = _vals(n)
	tr.at(0, "first(arr) is called with %d items." % n)
	tr.marks["arr"] = {"0": 0}
	tr.at(1, "Jump straight to slot 0 and return it. The other %d items are never touched." % (n - 1), 1, {"arr": [0]})


static func _bsearch(tr: Tr, n: int, variant: int) -> void:
	var body := "let lo = 0, hi = sorted.length - 1\nwhile (lo <= hi) {\n  const mid = (lo + hi) >> 1\n  if (sorted[mid] === t) return mid\n  if (sorted[mid] < t) lo = mid + 1\n  else hi = mid - 1\n}"
	tr.code = body
	if variant == 1:
		tr.code = "function findWord(sorted, t) {\n" + _indent(body) + "\n  return -1\n}"
		tr.off = 1
	var a := _sorted(n)
	var t: int = a[n - 1]
	var lo := 0
	var hi := n - 1
	tr.arrs["sorted"] = a
	tr.vars["t"] = t
	tr.vars["lo"] = lo
	tr.vars["hi"] = hi
	tr.marks["sorted"] = {"lo": lo, "hi": hi}
	tr.dim["sorted"] = [lo, hi]
	tr.at(0, "Looking for %d. Everything is still in play: lo = 0, hi = %d." % [t, hi])
	while lo <= hi:
		tr.at(1, "Anything left to search? lo (%d) <= hi (%d): yes." % [lo, hi])
		var mid := (lo + hi) >> 1
		tr.vars["mid"] = mid
		tr.marks["sorted"] = {"lo": lo, "mid": mid, "hi": hi}
		tr.at(2, "Look at the middle of what is left: mid = %d." % mid)
		if a[mid] == t:
			tr.at(3, "sorted[%d] is %d. Found it after %d looks, in a list of %d." % [mid, a[mid], tr.ops + 1, n], 1, {"sorted": [mid]})
			return
		tr.at(3, "sorted[%d] is %d, not %d." % [mid, a[mid], t], 1, {"sorted": [mid]})
		if a[mid] < t:
			lo = mid + 1
			tr.vars["lo"] = lo
			tr.dim["sorted"] = [lo, hi]
			tr.marks["sorted"] = {"lo": lo, "hi": hi}
			tr.at(4, "%d is too small, so everything up to mid is ruled out. lo = %d." % [a[mid], lo])
		else:
			hi = mid - 1
			tr.vars["hi"] = hi
			tr.dim["sorted"] = [lo, hi]
			tr.marks["sorted"] = {"lo": lo, "hi": hi}
			tr.at(5, "%d is too big, so everything from mid up is ruled out. hi = %d." % [a[mid], hi])


static func _grid(rows: int, cols: int) -> Dictionary:
	var on: Array = []
	for i in rows * cols:
		on.append(false)
	return {"rows": rows, "cols": cols, "on": on, "cur": -1}


static func _nested(tr: Tr, n: int) -> void:
	tr.code = "for (let i = 0; i < n; i++) {\n  for (let j = 0; j < n; j++) {\n    grid[i][j] = 0\n  }\n}"
	tr.vars["n"] = n
	tr.grid = _grid(n, n)
	for i in n:
		tr.vars["i"] = i
		tr.vars.erase("j")
		tr.at(0, "Outer loop: i = %d. The inner loop is about to run all the way through again." % i)
		for j in n:
			tr.vars["j"] = j
			tr.grid["on"][i * n + j] = true
			tr.grid["cur"] = i * n + j
			tr.at(2, "Inner loop: j = %d. Set grid[%d][%d]. One step." % [j, i, j], 1)
	tr.grid["cur"] = -1
	tr.at(4, "The inner loop ran %d times for each of the %d outer turns: %d x %d = %d steps." % [n, n, n, n, tr.ops])


static func _doubling(tr: Tr, n: int) -> void:
	tr.code = "for (let i = 1; i < n; i *= 2) {\n  work()\n}"
	tr.vars["n"] = n
	var i := 1
	while i < n:
		tr.vars["i"] = i
		tr.at(0, "i = %d, still below n = %d, so go round again." % [i, n])
		tr.at(1, "Do the work. One step.", 1)
		i *= 2
	tr.vars["i"] = i
	tr.at(0, "i = %d is not below %d. Stop." % [i, n])
	tr.at(2, "i doubled its way up to %d in only %d steps." % [n, tr.ops])


static func _sethas(tr: Tr, n: int) -> void:
	tr.code = "const seen = new Set(listA)\nlet hits = 0\nfor (const x of listB) {\n  if (seen.has(x)) hits++\n}"
	var a := _vals(n)
	var b: Array = []
	for i in n:
		b.append(a[(i * 3) % n] if i % 2 == 0 else 20 + i)
	tr.arrs["listA"] = a
	tr.arrs["listB"] = b
	tr.at(0, "Build a Set from listA: %d inserts at about one step each. This happens once." % n, n)
	var hits := 0
	tr.vars["hits"] = 0
	tr.at(1, "Start the counter at 0.")
	for i in n:
		tr.vars["x"] = b[i]
		tr.marks["listB"] = {"x": i}
		tr.at(2, "Next item of listB: x = %d." % b[i])
		var found := a.has(b[i])
		if found:
			hits += 1
		tr.vars["hits"] = hits
		tr.at(3, "seen.has(%d): hash it, jump to its bucket, look. One step. %s" % [b[i], "It is there." if found else "Not there."], 1, {"listB": [i]})
	tr.at(4, "%d steps to build the Set plus %d to check = %d. Twice the data would be twice the steps." % [n, n, tr.ops])


static func _twoloops(tr: Tr, n: int) -> void:
	tr.code = "let total = 0\nfor (const a of listA) total += a\nfor (const b of listB) total += b"
	var a := _vals(n)
	var b := _sorted(n)
	var total := 0
	tr.arrs["listA"] = a
	tr.arrs["listB"] = b
	tr.vars["total"] = 0
	tr.at(0, "Start at zero.")
	for i in n:
		total += int(a[i])
		tr.vars["total"] = total
		tr.marks["listA"] = {"a": i}
		tr.at(1, "First loop: add %d. One step." % a[i], 1, {"listA": [i]})
	tr.marks.erase("listA")
	for i in n:
		total += int(b[i])
		tr.vars["total"] = total
		tr.marks["listB"] = {"b": i}
		tr.at(2, "Second loop: add %d. One step." % b[i], 1, {"listB": [i]})
	tr.marks.erase("listB")
	tr.at(2, "The second loop only started after the first one finished: %d + %d = %d steps. Loops in a row add." % [n, n, tr.ops])


static func _innerconst(tr: Tr, n: int, variant: int) -> void:
	var inner := 3
	var item := "pixel"
	tr.code = "for (const pixel of image) {\n  for (let c = 0; c < 3; c++) {\n    brighten(pixel, c)\n  }\n}"
	if variant == 1:
		inner = 7
		item = "order"
		tr.code = "for (const order of orders) {\n  for (let d = 0; d < 7; d++) {\n    tally[d] += order.byDay[d]\n  }\n}"
	tr.grid = _grid(n, inner)
	for i in n:
		tr.at(0, "Outer loop: %s %d of %d." % [item, i + 1, n])
		for c in inner:
			tr.vars["d" if variant == 1 else "c"] = c
			tr.grid["on"][i * inner + c] = true
			tr.grid["cur"] = i * inner + c
			tr.at(2, "Inner step %d of %d. It is always %d, however long the outer list gets." % [c + 1, inner, inner], 1)
	tr.grid["cur"] = -1
	tr.at(4, "%d x %d = %d steps. The %d never grows with the input, so this is linear." % [n, inner, tr.ops, inner])


static func _triangular(tr: Tr, n: int) -> void:
	tr.code = "for (let i = 0; i < n; i++) {\n  for (let j = i + 1; j < n; j++) {\n    compare(arr[i], arr[j])\n  }\n}"
	tr.vars["n"] = n
	tr.grid = _grid(n, n)
	for i in n:
		tr.vars["i"] = i
		tr.vars.erase("j")
		tr.at(0, "Outer loop: i = %d. The inner loop starts just past it, at %d." % [i, i + 1])
		for j in range(i + 1, n):
			tr.vars["j"] = j
			tr.grid["on"][i * n + j] = true
			tr.grid["cur"] = i * n + j
			tr.at(2, "Compare item %d with item %d. One step." % [i, j], 1)
	tr.grid["cur"] = -1
	tr.at(4, "Every pair exactly once: %d steps. That is half of %d x %d, and half of n² still grows like n²." % [tr.ops, n, n])


static func _sortloop(tr: Tr, n: int) -> void:
	tr.code = "arr.sort((a, b) => a - b)\nfor (const x of arr) console.log(x)"
	var a := _vals(n)
	tr.arrs["arr"] = a.duplicate()
	tr.at(0, "About to sort %d items." % n)
	a.sort()
	tr.arrs["arr"] = a
	tr.at(0, "sort() is a library call. A good sort makes about n x log2(n) comparisons: %d for %d items." % [_lg(n), n], _lg(n), {}, true)
	for i in n:
		tr.vars["x"] = a[i]
		tr.marks["arr"] = {"x": i}
		tr.at(1, "Print %d. One step." % a[i], 1, {"arr": [i]})
	tr.at(1, "Sorting cost %d, printing cost %d. The bigger term is what matters as n grows." % [_lg(n), n])


static func _nqueries(tr: Tr, n: int) -> void:
	tr.code = "for (const x of queries) {\n  binarySearch(sortedArr, x)\n}"
	var a := _sorted(n)
	var q: Array = []
	for i in n:
		q.append(a[(i * 5 + 1) % n])
	tr.arrs["queries"] = q
	tr.arrs["sortedArr"] = a
	for i in n:
		tr.vars["x"] = q[i]
		tr.marks["queries"] = {"x": i}
		tr.at(0, "Next query: x = %d." % q[i])
		_probe(tr, "sortedArr", a, int(q[i]), 1, "binarySearch")
	tr.at(2, "%d queries, each needing about log2(%d) looks: %d steps in all." % [n, n, tr.ops])


static func _dedupe(tr: Tr, n: int, variant: int) -> void:
	var src := "arr"
	var x := "x"
	tr.code = "const out = []\nfor (const x of arr) {\n  if (!out.includes(x)) out.push(x)\n}"
	if variant == 1:
		src = "emails"
		x = "e"
		tr.code = "function dedupe(emails) {\n  const out = []\n  for (const e of emails) {\n    if (!out.includes(e)) out.push(e)\n  }\n  return out\n}"
		tr.off = 1
	var a := _vals(n)
	var out: Array = []
	tr.arrs[src] = a
	tr.arrs["out"] = out
	tr.at(0, "Start with an empty output list.")
	for i in n:
		tr.vars[x] = a[i]
		tr.marks[src] = {x: i}
		tr.at(1, "Next item: %s = %d." % [x, a[i]])
		for k in out.size():
			tr.marks["out"] = {"k": k}
			tr.at(2, "Inside includes, a hidden loop: is out[%d] equal to %d? No." % [k, a[i]], 1, {"out": [k]}, true)
		tr.marks.erase("out")
		out.append(a[i])
		tr.at(2, "Not found, so push it. out now holds %d item%s, and the next scan will be that much longer." % [out.size(), "" if out.size() == 1 else "s"])
	tr.at(3, "The list being scanned grew with every push: %d steps for %d items." % [tr.ops, n])


static func _fib(tr: Tr, k: int) -> int:
	tr.stack.append("fib(%d)" % k)
	tr.at(0, "fib(%d) is called. A new frame goes on the call stack." % k, 1)
	if k < 2:
		tr.at(1, "%d is less than 2: the base case. Return %d straight away." % [k, k])
		tr.stack.pop_back()
		return k
	tr.at(2, "To answer fib(%d) it needs fib(%d) AND fib(%d): two more calls, each from scratch." % [k, k - 1, k - 2])
	var a := _fib(tr, k - 1)
	var b := _fib(tr, k - 2)
	tr.at(2, "Both came back: fib(%d) = %d + %d = %d. Return." % [k, a, b, a + b])
	tr.stack.pop_back()
	return a + b


static func _fib_top(tr: Tr, n: int) -> void:
	tr.code = "function fib(n) {\n  if (n < 2) return n\n  return fib(n - 1) + fib(n - 2)\n}"
	tr.stack_title = "call stack"
	var r := _fib(tr, n)
	tr.at(3, "fib(%d) = %d, and it took %d calls to get there." % [n, r, tr.ops])


static func _fibmemo(tr: Tr, k: int, memo: Dictionary) -> int:
	tr.stack.append("fib(%d)" % k)
	tr.at(1, "fib(%d) is called." % k, 1)
	if k < 2:
		tr.at(2, "Base case: return %d." % k)
		tr.stack.pop_back()
		return k
	if memo.has(k):
		tr.at(3, "fib(%d) is already in the memo: %d. Return it without any more calls." % [k, memo[k]])
		tr.stack.pop_back()
		return memo[k]
	tr.at(3, "fib(%d) is not in the memo yet, so it has to be worked out this once." % k)
	var a := _fibmemo(tr, k - 1, memo)
	var b := _fibmemo(tr, k - 2, memo)
	memo[k] = a + b
	var parts: Array = []
	for key in memo:
		parts.append("%d: %d" % [key, memo[key]])
	tr.vars["memo"] = "{" + ", ".join(parts) + "}"
	tr.at(4, "fib(%d) = %d + %d = %d. Write it in the memo so nobody has to ask twice." % [k, a, b, a + b])
	tr.stack.pop_back()
	return a + b


static func _fibmemo_top(tr: Tr, n: int) -> void:
	tr.code = "const memo = {}\nfunction fib(n) {\n  if (n < 2) return n\n  if (memo[n]) return memo[n]\n  memo[n] = fib(n - 1) + fib(n - 2)\n  return memo[n]\n}"
	tr.stack_title = "call stack"
	tr.vars["memo"] = "{}"
	tr.at(0, "One empty memo, shared by every call.")
	var r := _fibmemo(tr, n, {})
	tr.at(6, "fib(%d) = %d in %d calls. Each answer was worked out once, then looked up." % [n, r, tr.ops])


# ---------- Challenge the AI ----------

static func _mapget(tr: Tr, n: int) -> void:
	tr.code = "const byId = new Map(users.map(u => [u.id, u]))\n\nfunction getUser(id) {\n  return byId.get(id)\n}"
	var ids: Array = []
	for i in n:
		ids.append(101 + i * 3)
	tr.arrs["users (ids)"] = ids
	tr.at(0, "Build the map once: %d users, one insert each. A one-time cost, not counted below." % n)
	for q in 3:
		var at_i := (q * 3 + 1) % n
		tr.vars["id"] = ids[at_i]
		tr.at(2, "getUser(%d) is called." % ids[at_i])
		tr.at(3, "byId.get: hash the id and jump to its bucket. One step, however many users there are.", 1, {"users (ids)": [at_i]})
	tr.at(3, "Three lookups, three steps. With %d users or 16 million it would still be three." % n)


static func _sortsearch(tr: Tr, n: int) -> void:
	tr.code = "function has(items, target) {\n  items.sort((a, b) => a - b)\n  return binarySearch(items, target) !== -1\n}"
	var a := _vals(n)
	var target: int = a[n - 1]
	tr.arrs["items"] = a.duplicate()
	tr.vars["target"] = target
	tr.at(0, "has(items, %d) is called." % target)
	a.sort()
	tr.arrs["items"] = a
	tr.at(1, "Sort everything first: about n x log2(n) = %d comparisons. And this happens on EVERY call." % _lg(n), _lg(n), {}, true)
	_probe(tr, "items", a, target, 2, "binarySearch")
	tr.at(2, "This one call cost %d steps. Scanning the unsorted list would have cost at most %d." % [tr.ops, n])


static func _shift(tr: Tr, n: int) -> void:
	tr.code = "const queue = [...jobs]\nwhile (queue.length > 0) {\n  const job = queue.shift()\n  run(job)\n}"
	var q: Array = []
	for i in n:
		q.append("J%d" % (i + 1))
	tr.arrs["queue"] = q
	tr.at(0, "Copy %d jobs into the queue." % n)
	while not q.is_empty():
		tr.at(1, "%d job%s left, keep going." % [q.size(), "" if q.size() == 1 else "s"])
		var job: String = q[0]
		for k in range(1, q.size()):
			tr.marks["queue"] = {"slides": k}
			tr.at(2, "Inside shift: slot 0 is being removed, so %s has to slide one slot left." % q[k], 1, {"queue": [k]}, true)
		tr.marks.erase("queue")
		var moved := q.size() - 1
		q.pop_front()
		tr.vars["job"] = job
		tr.at(2, "shift() returns %s. It had to move %d other job%s to close the gap." % [job, moved, "" if moved == 1 else "s"])
		tr.at(3, "Run %s." % job)
	tr.at(4, "Only %d jobs, but %d slides. An index that walks forward would have cost nothing." % [n, tr.ops])


static func _find(tr: Tr, n: int) -> void:
	tr.code = "for (const order of orders) {\n  const p = products.find(p => p.id === order.productId)\n  order.price = p.price\n}"
	var products: Array = []
	var wants: Array = []
	for i in n:
		products.append(10 * (i + 1))
	for i in n:
		wants.append(products[(i * 3 + n - 1) % n])
	tr.arrs["orders (productId)"] = wants
	tr.arrs["products (id)"] = products
	for i in n:
		tr.marks["orders (productId)"] = {"order": i}
		tr.at(0, "Next order wants product %d." % wants[i])
		var idx := products.find(wants[i])
		for k in idx + 1:
			tr.marks["products (id)"] = {"p": k}
			tr.at(1, "Inside find, a hidden loop: is products[%d] (id %d) the one? %s" % [k, products[k], "Yes." if k == idx else "No."], 1, {"products (id)": [k]}, true)
		tr.marks.erase("products (id)")
		tr.at(2, "Copy the price onto the order.")
	tr.at(3, "%d orders, and each one scanned the product list: %d steps. A Map of products by id would make it %d." % [n, tr.ops, n])


static func _countwords(tr: Tr, n: int) -> void:
	tr.code = "function count(words) {\n  const freq = {}\n  for (const w of words) {\n    freq[w] = (freq[w] || 0) + 1\n  }\n  return freq\n}"
	var pool := ["tea", "code", "tea", "mug", "code", "tea", "cat", "mug"]
	var words: Array = []
	for i in n:
		words.append(pool[i % pool.size()])
	var freq := {}
	tr.arrs["words"] = words
	tr.vars["freq"] = "{}"
	tr.at(1, "Start with an empty object.")
	for i in n:
		var w: String = words[i]
		tr.marks["words"] = {"w": i}
		tr.at(2, "Next word: \"%s\"." % w)
		freq[w] = int(freq.get(w, 0)) + 1
		var parts: Array = []
		for key in freq:
			parts.append("%s: %d" % [key, freq[key]])
		tr.vars["freq"] = "{" + ", ".join(parts) + "}"
		tr.at(3, "freq[\"%s\"]: hash the word, jump to its slot, add one. One step, no scanning." % w, 1, {"words": [i]})
	tr.at(5, "%d words, %d steps. The object can hold a thousand different words and each update is still one step." % [n, tr.ops])


static func _bstsorted(tr: Tr, n: int) -> void:
	tr.code = "// ids arrive already sorted: 1, 2, 3, 4, ...\nconst tree = new BinarySearchTree()\nfor (const id of ids) tree.insert(id)\n\ntree.find(someId)"
	var chain: Array = []
	for i in n:
		chain.append(i + 1)
	var label := "the tree, root first (each node's only child is to its right)"
	tr.at(1, "An empty search tree.")
	tr.arrs[label] = chain
	tr.at(2, "Insert %d ids in sorted order. Every new id is bigger than all before it, so it always goes right. The 'tree' is a chain." % n)
	tr.vars["someId"] = n
	for k in n:
		tr.marks[label] = {"node": k}
		tr.at(4, "find(%d): is this node it? %s" % [n, "Yes." if k == n - 1 else "No, %d is smaller. Go right." % (k + 1)], 1, {label: [k]})
	tr.at(4, "It walked all %d nodes. A balanced tree of this size would have needed about %d." % [n, int(ceil(log(n + 1) / log(2.0)))])


static func _topten(tr: Tr, n: int) -> void:
	tr.code = "function topTen(scores, incoming) {\n  scores.push(incoming)\n  scores.sort((a, b) => b - a)\n  return scores.slice(0, 10)\n}"
	var a := _vals(n)
	tr.arrs["scores"] = a.duplicate()
	tr.vars["incoming"] = 20
	tr.at(0, "A new score, 20, arrives. There are already %d." % n)
	a.append(20)
	tr.arrs["scores"] = a.duplicate()
	tr.at(1, "Push it on the end. One step.", 1, {"scores": [n]})
	a.sort()
	a.reverse()
	tr.arrs["scores"] = a
	tr.at(2, "Re-sort the ENTIRE list: about n x log2(n) = %d comparisons, for one new score." % _lg(n + 1), _lg(n + 1), {}, true)
	var take := mini(10, n + 1)
	tr.at(3, "Copy out the first %d." % take, take)
	tr.at(3, "One new score cost %d steps. A heap holding just the best ten would have cost about 4, at any size." % tr.ops)


# ---------- the algorithms behind the hands-on levels ----------

static func _unshift(tr: Tr, n: int) -> void:
	tr.code = "function insertFront(arr, value) {\n  for (let i = arr.length; i > 0; i--) {\n    arr[i] = arr[i - 1]\n  }\n  arr[0] = value\n}"
	var a := _vals(n)
	a.append("")
	tr.arrs["arr"] = a
	tr.vars["value"] = 99
	tr.at(0, "Insert 99 at the front of %d items. Slot 0 is taken, so a gap has to be opened." % n)
	for i in range(n, 0, -1):
		tr.vars["i"] = i
		a[i] = a[i - 1]
		tr.marks["arr"] = {"i": i}
		tr.at(2, "Copy slot %d into slot %d. One step." % [i - 1, i], 1, {"arr": [i]})
	a[0] = 99
	tr.marks["arr"] = {"0": 0}
	tr.at(4, "Every item has moved one slot right. Now slot 0 is free: write 99.", 1, {"arr": [0]})
	tr.at(5, "%d shifts to insert one value. A linked list would have changed one pointer." % n)


static func _brackets(tr: Tr, n: int) -> void:
	tr.code = "const stack = []\nfor (const ch of text) {\n  if (isOpener(ch)) stack.push(ch)\n  else if (stack.pop() !== partner(ch)) return false\n}\nreturn stack.length === 0"
	var openers := ["(", "[", "{"]
	var pair := {"(": ")", "[": "]", "{": "}"}
	var text: Array = []
	for i in n / 2:
		text.append(openers[i % 3])
	for i in range(n / 2 - 1, -1, -1):
		text.append(pair[openers[i % 3]])
	tr.arrs["text"] = text
	tr.stack_title = "stack"
	tr.at(0, "An empty stack.")
	for i in n:
		var ch: String = text[i]
		tr.vars["ch"] = ch
		tr.marks["text"] = {"ch": i}
		if pair.has(ch):
			tr.stack.append(ch)
			tr.at(2, "%s is an opener. Push it: it waits on the stack for its partner. One step." % ch, 1, {"text": [i]})
		else:
			var top: String = tr.stack.pop_back()
			tr.at(3, "%s is a closer. Pop the top of the stack: %s. They match, carry on. One step." % [ch, top], 1, {"text": [i]})
	tr.at(5, "End of text and the stack is empty: balanced. %d symbols, %d steps, each symbol touched once." % [n, tr.ops])


static func _insertion(tr: Tr, n: int) -> void:
	tr.code = "for (let p = 1; p < arr.length; p++) {\n  const tmp = arr[p]\n  let j = p\n  while (j > 0 && arr[j - 1] > tmp) {\n    arr[j] = arr[j - 1]\n    j--\n  }\n  arr[j] = tmp\n}"
	var a := _vals(n)
	tr.arrs["arr"] = a
	for p in range(1, n):
		var tmp: int = a[p]
		var j := p
		tr.vars["p"] = p
		tr.vars["tmp"] = tmp
		tr.vars["j"] = j
		tr.marks["arr"] = {"p": p}
		tr.at(1, "Pick up arr[%d] = %d. Everything to its left is already in order." % [p, tmp], 0, {"arr": [p]})
		while true:
			if j == 0:
				tr.at(3, "j is 0: reached the front, nothing left to compare.")
				break
			if a[j - 1] > tmp:
				tr.at(3, "Is %d bigger than %d? Yes, so it is in the way." % [a[j - 1], tmp], 1, {"arr": [j - 1]})
				a[j] = a[j - 1]
				j -= 1
				tr.vars["j"] = j
				tr.marks["arr"] = {"j": j}
				tr.at(4, "Slide %d one slot right." % a[j + 1], 0, {"arr": [j + 1]})
			else:
				tr.at(3, "Is %d bigger than %d? No. This is the spot." % [a[j - 1], tmp], 1, {"arr": [j - 1]})
				break
		a[j] = tmp
		tr.marks["arr"] = {"j": j}
		tr.at(7, "Drop %d into slot %d." % [tmp, j], 0, {"arr": [j]})
	tr.marks.erase("arr")
	tr.at(8, "Sorted, after %d comparisons. On already-sorted input it would have been just %d." % [tr.ops, n - 1])


static func _bstfind(tr: Tr, n: int) -> void:
	tr.code = "let node = root\nwhile (node !== null) {\n  if (key === node.key) return node\n  node = key < node.key ? node.left : node.right\n}"
	var a := _sorted(n)
	var key: int = a[n - 1]
	var label := "keys in order (the lit range is the current subtree)"
	var lo := 0
	var hi := n - 1
	tr.arrs[label] = a
	tr.vars["key"] = key
	tr.dim[label] = [lo, hi]
	var mid := (lo + hi) >> 1
	tr.marks[label] = {"node": mid}
	tr.vars["node.key"] = a[mid]
	tr.at(0, "Start at the root, which in a balanced tree is the middle key: %d." % a[mid])
	while lo <= hi:
		mid = (lo + hi) >> 1
		tr.marks[label] = {"node": mid}
		tr.vars["node.key"] = a[mid]
		if a[mid] == key:
			tr.at(2, "%d is the key. Found it %d levels down, in a tree of %d keys." % [a[mid], tr.ops + 1, n], 1, {label: [mid]})
			return
		tr.at(2, "Is %d the key? No." % a[mid], 1, {label: [mid]})
		if key < a[mid]:
			hi = mid - 1
		else:
			lo = mid + 1
		tr.dim[label] = [lo, hi]
		tr.at(3, "%d is %s, so step into the %s subtree. Half of what was left is gone." % [key, "smaller" if key < a[mid] else "bigger", "left" if key < a[mid] else "right"])


static func _hashprobe(tr: Tr, n: int) -> void:
	tr.code = "function insert(table, key) {\n  let i = key % table.length\n  while (table[i] !== EMPTY) {\n    i = (i + 1) % table.length\n  }\n  table[i] = key\n}"
	var table: Array = ["", "", "", "", "", "", "", ""]
	for k in n:
		var s := (2 + k) % 8
		table[s] = 8 * (k + 1) + s
	tr.arrs["table"] = table
	tr.vars["key"] = 42
	tr.at(0, "Insert 42 into an 8-slot table that already holds %d key%s." % [n, "" if n == 1 else "s"])
	var i := 42 % 8
	tr.vars["i"] = i
	tr.marks["table"] = {"i": i}
	tr.at(1, "42 % 8 = 2, so its home is slot 2. Getting here took no searching at all.")
	while str(table[i]) != "":
		tr.at(2, "Slot %d is taken by %s. A collision." % [i, str(table[i])], 1, {"table": [i]})
		i = (i + 1) % 8
		tr.vars["i"] = i
		tr.marks["table"] = {"i": i}
		tr.at(3, "Try the next slot along: i = %d." % i)
	tr.at(2, "Slot %d is empty." % i, 1, {"table": [i]})
	table[i] = 42
	tr.at(5, "Store 42 here. It took %d probes, because the table is %d/8 full." % [tr.ops, n], 0, {"table": [i]})


static func _percolate(tr: Tr, n: int) -> void:
	tr.code = "function insert(heap, value) {\n  let i = heap.length\n  heap[i] = value\n  while (i > 1 && heap[i] < heap[i >> 1]) {\n    swap(heap, i, i >> 1)\n    i = i >> 1\n  }\n}"
	var h: Array = ["-"]
	for k in range(1, n + 1):
		h.append(k * 2)
	tr.arrs["heap (slot 0 unused)"] = h
	var name := "heap (slot 0 unused)"
	tr.vars["value"] = 1
	tr.at(0, "Insert 1 into a heap of %d values. Every parent is smaller than its children." % n)
	var i := h.size()
	h.append(1)
	tr.vars["i"] = i
	tr.marks[name] = {"i": i}
	tr.at(2, "Put it in the next free slot, %d, at the bottom of the tree." % i, 0, {name: [i]})
	while i > 1:
		var par := i >> 1
		tr.marks[name] = {"i": i, "parent": par}
		if h[i] < h[par]:
			tr.at(3, "Its parent is at %d / 2 = %d and holds %d. Smaller than its parent? Yes." % [i, par, h[par]], 1, {name: [i, par]})
			var tmp = h[i]
			h[i] = h[par]
			h[par] = tmp
			i = par
			tr.vars["i"] = i
			tr.marks[name] = {"i": i}
			tr.at(4, "Swap them. The new value climbs one level.", 0, {name: [i]})
		else:
			tr.at(3, "Smaller than its parent? No. Heap order holds.", 1, {name: [i, par]})
			break
	tr.at(7, "Done in %d comparison%s. Each one skipped a whole level, and a heap of %d has only %d levels." % [tr.ops, "" if tr.ops == 1 else "s", n + 1, int(floor(log(n + 1) / log(2.0))) + 1])


static func _bfs(tr: Tr, n: int) -> void:
	tr.code = "const queue = [start]\nseen.add(start)\nwhile (queue.length > 0) {\n  const node = queue.shift()\n  for (const next of neighbours(node)) {\n    if (!seen.has(next)) {\n      seen.add(next)\n      queue.push(next)\n    }\n  }\n}"
	var seen: Array = []
	for i in n:
		seen.append("")
	var q: Array = [0]
	seen[0] = "yes"
	tr.arrs["seen (one slot per node)"] = seen
	var name := "seen (one slot per node)"
	tr.stack_title = "queue, front at bottom"
	tr.stack = ["0"]
	tr.at(1, "Each node is linked to the two nodes on either side of it. Start at node 0: queue it and mark it seen.")
	while not q.is_empty():
		var node: int = q.pop_front()
		tr.stack.pop_front()
		tr.vars["node"] = node
		tr.marks[name] = {"node": node}
		tr.at(3, "Take the OLDEST node off the front of the queue: %d." % node)
		for d in [-2, -1, 1, 2]:
			var nx: int = node + d
			if nx < 0 or nx >= n:
				continue
			tr.vars["next"] = nx
			if str(seen[nx]) == "":
				seen[nx] = "yes"
				q.append(nx)
				tr.stack.append(str(nx))
				tr.at(5, "Neighbour %d is new. Mark it seen and join the back of the queue." % nx, 1, {name: [nx]})
			else:
				tr.at(5, "Neighbour %d was already seen. Skip it." % nx, 1, {name: [nx]})
	tr.marks.erase(name)
	tr.at(10, "The queue is empty: every reachable node was visited once, nearest first. %d edge checks for %d nodes." % [tr.ops, n])


static func _unionfind(tr: Tr, n: int) -> void:
	tr.code = "function find(x) {\n  while (parent[x] !== x) x = parent[x]\n  return x\n}\nfunction union(a, b) {\n  const ra = find(a), rb = find(b)\n  if (ra !== rb) parent[ra] = rb\n}"
	var parent: Array = []
	for i in n:
		parent.append(i)
	tr.arrs["parent (index = item, value = who it points to)"] = parent
	var name := "parent (index = item, value = who it points to)"
	tr.at(0, "%d items, each its own set: every item points at itself." % n)
	var gap := 1
	while gap < n:
		for a in range(0, n - gap, gap * 2):
			var b := a + gap
			tr.vars["a"] = a
			tr.vars["b"] = b
			tr.at(4, "union(%d, %d): are they already in the same set? Find each one's root." % [a, b])
			var roots: Array = []
			for start in [a, b]:
				var x: int = start
				while parent[x] != x:
					tr.marks[name] = {"x": x}
					tr.at(1, "find(%d): item %d points at %d, so climb." % [start, x, parent[x]], 1, {name: [x]})
					x = parent[x]
				tr.marks[name] = {"x": x}
				tr.at(2, "find(%d): item %d points at itself. It is the root." % [start, x], 1, {name: [x]})
				roots.append(x)
			tr.marks.erase(name)
			parent[roots[0]] = roots[1]
			tr.at(6, "Different roots, so point %d at %d. Two sets are now one." % [roots[0], roots[1]], 0, {name: [roots[0]]})
		gap *= 2
	tr.at(7, "One set left after %d unions and %d pointer steps. No searching, just following pointers." % [n - 1, tr.ops])
