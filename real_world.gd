extends RefCounted
# Per-level briefing: how to play, where the idea shows up in real software,
# an animated illustration of one real use, and which code traces belong to the level.

const UI = preload("res://ui.gd")

const INFO := {
	"search": {
		"how": ["Click a face-down card to flip it. Find the target number in as few flips as you can.",
			"Round 1 is shuffled, so it is pure luck. From round 2 the cards are sorted: every flip rules out one whole side.",
			"Always flip the middle of what is still lit. Stars are for matching the best possible count."],
		"uses": [["git bisect", "1,000 commits since the last good build? Test the middle one and keep halving: the bad commit turns up in 10 builds."],
			["Database indexes", "An index keeps a column sorted so the database can halve its way to your row instead of reading the whole table."],
			["Autocomplete", "Finding where 'alg...' starts in a sorted word list is a binary search."]],
		"caption": "git bisect: every test build halves the list of suspect commits.",
		"traces": ["bsearch"],
	},
	"bigo": {
		"how": ["Read the snippet and pick how its step count grows as the input (n) grows.",
			"Press 'Step through it' to run the code line by line and watch the steps add up.",
			"Look for loops, loops inside loops, and library calls that hide a loop."],
		"uses": [["The endpoint that was fine in testing", "100 rows in dev, 100,000 in production. An O(n²) loop is a million times slower there, not a thousand."],
			["Code review", "Most real performance bugs are an accidental nested loop: a find() or includes() inside a for."],
			["Capacity planning", "The growth rate tells you whether 10x the users needs 10x the servers or 100x."]],
		"caption": "Same code, more rows. One of these still answers in time.",
		"traces": [],
	},
	"listarr": {
		"how": ["Read the operation, then predict which structure does it in fewer steps.",
			"Watch both run at the same speed per step. The counters are the answer.",
			"Six operations. Five right earns three stars."],
		"uses": [["Playlists and 'play next'", "Queueing a song in the middle of a playlist is a relink: two pointers change and nothing shifts."],
			["Images, audio, spreadsheets", "Pixels and samples live in arrays, so 'the value at position i' is a single jump."],
			["LRU caches", "A doubly linked list lets a cache unhook an entry from the middle and move it to the front in O(1)."]],
		"caption": "'Play next' splices one song in by changing two pointers.",
		"traces": ["unshift"],
	},
	"stackq": {
		"how": ["Part 1: you are the machine. For each symbol choose Push, Pop, Reject or Accept.",
			"Openers wait on the stack. A closer must match the top of the stack.",
			"Part 2: decide whether each real job needs a stack or a queue."],
		"uses": [["The call stack", "Every function call pushes a frame and every return pops one. A stack overflow is that stack running out of room."],
			["Undo and the Back button", "The most recent action is the first one reversed: last in, first out."],
			["Job queues", "Print spoolers, message brokers and web servers hand out work in arrival order: first in, first out."]],
		"caption": "The Back button is a stack. The office printer is a queue.",
		"traces": ["brackets"],
	},
	"sortlab": {
		"how": ["Pick how many items there are and what order they start in.",
			"Click a panel to bet on the winner, then press Race. Every sort runs at the same steps per second.",
			"Try three starting orders and two sizes for three stars."],
		"uses": [["ORDER BY and 'sort by date'", "Every sorted column in a file browser, inbox or SQL query is one of these algorithms."],
			["Your language's built-in sort", "Python and Java use Timsort: mergesort that hands small or nearly-sorted runs to insertion sort."],
			["Sorting as preparation", "Sort once, then binary search, drop duplicate neighbours or merge two lists cheaply."]],
		"caption": "Clicking a column header runs a sort.",
		"traces": ["insertion"],
	},
	"recursion": {
		"how": ["Press n + 1 to grow the call tree. Each circle is one function call.",
			"Same colour means the same question being answered again.",
			"Turn on 'Remember answers', compare the call counts, then try the bonus question."],
		"uses": [["Walking folders", "A folder's size is its files plus the size of each subfolder: the same question, one level down."],
			["Caches everywhere", "Memoization is why DNS answers, compiled templates and API responses are remembered instead of recomputed."],
			["Diff and route tools", "git diff, spell-check distance and route planners reuse sub-answers. That is dynamic programming."]],
		"caption": "Folder size: ask every subfolder the same question, then add up.",
		"traces": ["fib", "fibmemo"],
	},
	"tree": {
		"how": ["Insert values and watch where the comparisons send them.",
			"Insert 15 in sorted order with balancing off. Then turn balancing on.",
			"Click any node to trace a lookup from the root."],
		"uses": [["Database indexes", "Postgres and MySQL keep indexes in B-trees: wide balanced trees where any row among millions is three or four hops away."],
			["Sorted maps", "C++ std::map and Java TreeMap are red-black trees: lookup plus 'next bigger key' in log n."],
			["File systems", "Directories with millions of files stay fast because their entries live in balanced trees."]],
		"caption": "A database index: three page reads to reach one row in a million.",
		"traces": ["bstfind"],
	},
	"hash": {
		"how": ["Insert keys and watch them jump to slot  key % table size.",
			"Use 'Insert look-alikes' to force collisions, and switch modes to compare strategies.",
			"Click a stored key to replay its lookup. Rehash when the table gets crowded."],
		"uses": [["Objects, dicts and Maps", "Every JavaScript object, Python dict and JSON lookup by key is a hash table."],
			["Caches", "Redis and memcached are giant hash tables: 'user:42' goes straight to its value."],
			["De-duplication and joins", "'Have I seen this before?' and database hash joins are set lookups at about one step each."]],
		"caption": "A cache hit: from key to value in one jump, no searching.",
		"traces": ["hashprobe", "sethas"],
	},
	"heap": {
		"how": ["Insert a value. If it lands out of place, click the node it should swap with.",
			"Going up there is one candidate: the parent. Going down, pick the smaller child.",
			"Remove the smallest a few times and watch the values come out in order."],
		"uses": [["Schedulers", "Operating systems and job runners keep ready tasks in a heap and always run the most urgent one."],
			["Timers", "'What fires next?' across thousands of timeouts is a heap's remove-min."],
			["Top-K and Dijkstra", "Keeping the best 10 of a million scores, or the cheapest next road, is a small heap."]],
		"caption": "A scheduler: jobs arrive in any order, the most urgent always runs next.",
		"traces": ["percolate"],
	},
	"race": {
		"how": ["Read the workload: which operations happen, and how often.",
			"Pick the structure you would reach for, then watch all six run it.",
			"Green is the best choice. Six best picks out of seven earns three stars."],
		"uses": [["One app, many structures", "A web app uses a hash map for sessions, a tree for its database index, a queue for jobs and a heap for its scheduler."],
			["Reading the workload", "Lookup-heavy? Hash. Ordered output or ranges? Tree or sorted array. Always the smallest? Heap."],
			["Talking to an AI assistant", "'Use a Map here' is often the entire fix. You need to know when to say it."]],
		"caption": "Different parts of one app lean on different structures.",
		"traces": ["mapget"],
	},
	"graph": {
		"how": ["Drag on the map to paint walls or mud. Mud costs 5 to cross instead of 1.",
			"Run BFS, DFS and Dijkstra on the same map and compare the scoreboard.",
			"Find a map where Dijkstra's route is cheaper than BFS's for three stars."],
		"uses": [["Maps and navigation", "Roads are edges weighted by travel time. Your route is a shortest-path search."],
			["Social networks", "'People you may know' is a breadth-first search two steps out from you."],
			["Build and package tools", "npm, make and CI pipelines order their tasks by walking a dependency graph."]],
		"caption": "Fewest roads and fastest route are different questions.",
		"traces": ["bfs"],
	},
	"maze": {
		"how": ["Press Step to test one wall at a time, or Run to watch the sets merge.",
			"Click two cells to ask: are these connected yet?",
			"When one set remains, press Solve it."],
		"uses": [["Network connectivity", "'Can server A reach server B?' as cables are added is exactly union-find."],
			["Image regions", "Grouping touching pixels into blobs, for selection tools or OCR, merges sets of neighbours."],
			["Cheapest network", "Kruskal's minimum spanning tree adds the cheapest cable that joins two separate groups."]],
		"caption": "Plug in a cable and two groups become one. Can A reach H yet?",
		"traces": ["unionfind"],
	},
	"boss": {
		"how": ["Read the code and the assistant's claim about its cost.",
			"Approve it if the claim is right. Push back if it is not.",
			"Not sure? Step through the code and count for yourself."],
		"uses": [["Reviewing AI-written code", "Assistants write plausible code fast. The complexity claim is the part most worth checking."],
			["Pull request review", "'This is O(n²) on the hot path, can we use a Set?' is one of the most valuable comments you can leave."],
			["Incident reviews", "'It was fine until the table grew' is almost always a growth-rate bug that a review could have caught."]],
		"caption": "One comment in review beats one incident in production.",
		"traces": [],
	},
}


static func _box(ci: CanvasItem, r: Rect2, s: String, c: Color, lit: bool = false, font_size: int = 13) -> void:
	UI.rrect(ci, r, c.lightened(0.15) if lit else Color(c.r, c.g, c.b, 0.22), 8.0, UI.hot(c, 1.8) if lit else Color(c.r, c.g, c.b, 0.6), 1.5)
	UI.ctext(ci, r.get_center(), s, font_size, UI.BG if lit else UI.INK, "title")


static func draw(ci: CanvasItem, id: String, r: Rect2, t: float, c: Color) -> void:
	UI.rrect(ci, r, Color("0f111b"), 12.0, Color(1, 1, 1, 0.07), 1.0)
	var o := r.position
	var mid := r.get_center()
	match id:
		"search":
			var tests := [[7, true], [11, false], [9, true], [10, true]]
			var phase := int(t / 1.2) % 6
			var good := 0
			var bad := 15
			for k in mini(phase, 4):
				if tests[k][1]:
					good = int(tests[k][0])
				else:
					bad = int(tests[k][0])
			ci.draw_line(Vector2(o.x + 34, mid.y), Vector2(r.end.x - 34, mid.y), Color(1, 1, 1, 0.2), 2.0)
			for i in 16:
				var p := Vector2(o.x + 34 + i * (r.size.x - 68) / 15.0, mid.y)
				var col := Color(1, 1, 1, 0.3)
				if i <= good:
					col = UI.ACCENT
				elif i >= bad:
					col = UI.BAD
				ci.draw_circle(p, 9.0, col)
				if phase >= 1 and phase <= 4 and i == int(tests[phase - 1][0]):
					ci.draw_arc(p, 15.0, 0.0, TAU, 24, UI.hot(Color.WHITE, 2.0), 2.5, true)
					UI.ctext(ci, p + Vector2(0, -32), "build %d" % phase, 13, UI.INK, "title")
			UI.text(ci, Vector2(o.x + 24, mid.y + 44), "last good release", 12, UI.ACCENT)
			UI.text(ci, Vector2(r.end.x - 144, mid.y + 44), "today: it is broken", 12, UI.BAD)
			UI.ctext(ci, Vector2(mid.x, r.end.y - 24), "16 commits. Found the culprit in 4 builds." if phase == 5 else "Which commit broke it?", 14, UI.hot(UI.WARN, 1.3) if phase == 5 else UI.DIM, "title")
		"bigo":
			var rows := ["100", "1,000", "10,000", "100,000"]
			var fast := ["0.1 ms", "1 ms", "10 ms", "0.1 s"]
			var slow := ["10 ms", "1 s", "1.7 minutes", "2.8 hours"]
			var wf := [0.05, 0.08, 0.12, 0.18]
			var ws := [0.08, 0.3, 0.72, 1.0]
			var ph := int(t / 1.5) % 4
			var bw := r.size.x - 260.0
			UI.text(ci, o + Vector2(24, 36), "rows in the table:  %s" % rows[ph], 16, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
			UI.text(ci, o + Vector2(24, 86), "one loop", 13, UI.DIM)
			UI.rrect(ci, Rect2(o.x + 150, o.y + 72, bw * float(wf[ph]), 20), UI.hot(UI.ACCENT, 1.4), 6.0)
			UI.text(ci, Vector2(o.x + 160 + bw * float(wf[ph]), o.y + 88), fast[ph], 13, UI.ACCENT)
			UI.text(ci, o + Vector2(24, 136), "loop in a loop", 13, UI.DIM)
			UI.rrect(ci, Rect2(o.x + 150, o.y + 122, bw * float(ws[ph]), 20), UI.hot(UI.BAD if ph >= 2 else UI.WARN, 1.4), 6.0)
			UI.text(ci, Vector2(o.x + 150, o.y + 164), slow[ph], 13, UI.BAD if ph >= 2 else UI.WARN)
			var tx := o.x + 150 + bw * 0.5
			ci.draw_dashed_line(Vector2(tx, o.y + 60), Vector2(tx, o.y + 176), Color(1, 1, 1, 0.5), 1.5, 6.0)
			UI.text(ci, Vector2(tx + 8, o.y + 196), "request times out here", 12, UI.DIM)
		"listarr":
			var songs := ["Intro", "Verse", "Hook", "Bridge", "Outro"]
			var spliced := fposmod(t, 3.2) > 1.6
			var w := 92.0
			var gap := (r.size.x - 48.0 - 5 * w) / 4.0
			var y := mid.y - 44.0
			for i in 5:
				var bx := o.x + 24 + i * (w + gap)
				_box(ci, Rect2(bx, y, w, 40), songs[i], c)
				if i < 4 and not (spliced and i == 1):
					UI.arrow(ci, Vector2(bx + w + 3, y + 20), Vector2(bx + w + gap - 3, y + 20), Color(1, 1, 1, 0.6), 2.0)
			var a := Vector2(o.x + 24 + 1 * (w + gap) + w / 2.0, y + 40)
			var b := Vector2(o.x + 24 + 2 * (w + gap) + w / 2.0, y + 40)
			var nb := Rect2((a.x + b.x) / 2.0 - 60, y + 86, 120, 40)
			_box(ci, nb, "Play next", UI.WARN, spliced)
			if spliced:
				UI.arrow(ci, a + Vector2(8, 4), nb.position + Vector2(30, -4), UI.hot(UI.ACCENT, 1.6), 2.5)
				UI.arrow(ci, nb.position + Vector2(90, -4), b + Vector2(-8, 4), UI.hot(UI.ACCENT, 1.6), 2.5)
			UI.ctext(ci, Vector2(mid.x, r.end.y - 22), "2 pointers changed, 0 songs moved" if spliced else "playlist: each song points at the next", 13, UI.hot(UI.WARN, 1.3) if spliced else UI.DIM, "title")
		"stackq":
			var pages := ["Home", "Search", "Article", "Comments"]
			var ph := int(t / 0.8) % 8
			var depth := ph + 1 if ph < 4 else 8 - ph
			UI.text(ci, o + Vector2(28, 30), "BROWSER HISTORY", 12, UI.DIM)
			for i in depth:
				_box(ci, Rect2(o.x + 28, r.end.y - 62 - i * 36.0, 170, 30), pages[i], UI.PINK, i == depth - 1)
			UI.text(ci, Vector2(o.x + 28, r.end.y - 10) , "Back pops the top" if ph >= 4 else "each click pushes", 12, UI.DIM)
			UI.text(ci, Vector2(o.x + 290, o.y + 30), "PRINT QUEUE", 12, UI.DIM)
			var served := int(t / 1.1) % 4
			for i in range(served, 4):
				_box(ci, Rect2(o.x + 290 + (3 - (i - served)) * 62.0 - 62.0 * 0.0, mid.y - 20, 54, 44), "doc %d" % (i + 1), UI.BLUE, i == served, 12)
			_box(ci, Rect2(r.end.x - 86, mid.y - 26, 64, 56), "printer", UI.ACCENT, false, 12)
			UI.text(ci, Vector2(o.x + 290, r.end.y - 10), "first sent, first printed", 12, UI.DIM)
		"sortlab":
			var names := ["notes.txt", "video.mp4", "logo.png", "backup.zip", "todo.md"]
			var sizes := [0.12, 0.95, 0.3, 0.7, 0.05]
			var rank := [1, 4, 2, 3, 0]
			var k := smoothstep(0.0, 1.0, clampf(sin(t * 0.9) * 1.6 + 0.5, 0.0, 1.0))
			UI.text(ci, o + Vector2(28, 30), "Name", 12, UI.DIM)
			UI.text(ci, o + Vector2(200, 30), "Size   (click the header to sort)", 12, UI.hot(c, 1.3) if k > 0.5 else UI.DIM)
			for i in 5:
				var y := o.y + 44 + lerpf(float(i), float(rank[i]), k) * 34.0
				UI.rrect(ci, Rect2(o.x + 20, y, r.size.x - 40, 28), Color(1, 1, 1, 0.04), 6.0)
				UI.text(ci, Vector2(o.x + 28, y + 19), names[i], 13, UI.INK)
				UI.rrect(ci, Rect2(o.x + 200, y + 7, (r.size.x - 240) * float(sizes[i]), 14), UI.hue(float(sizes[i]) * 5.0, 6.0), 5.0)
		"recursion":
			var nodes := [["photos", 0.5, 0, -1], ["2023", 0.25, 1, 0], ["2024", 0.75, 1, 0], ["beach", 0.12, 2, 1], ["snow", 0.38, 2, 1], ["city", 0.62, 2, 2], ["pets", 0.88, 2, 2]]
			var order := [0, 1, 3, 4, 2, 5, 6]
			var ph := int(t * 1.4) % 9
			for i in range(1, 7):
				var p: Array = nodes[i]
				var q: Array = nodes[p[3]]
				ci.draw_line(Vector2(o.x + float(p[1]) * r.size.x, o.y + 30 + int(p[2]) * 60), Vector2(o.x + float(q[1]) * r.size.x, o.y + 62 + int(q[2]) * 60), Color(1, 1, 1, 0.25), 1.5, true)
			for i in 7:
				var p: Array = nodes[i]
				_box(ci, Rect2(o.x + float(p[1]) * r.size.x - 44, o.y + 30 + int(p[2]) * 60, 88, 32), p[0], c, order.find(i) == ph - 1)
			UI.ctext(ci, Vector2(mid.x, r.end.y - 20), "size(folder) = its files + size(each subfolder)", 13, UI.DIM, "mono")
		"tree":
			var ph := int(t * 1.3) % 5
			var root := Rect2(mid.x - 60, o.y + 22, 120, 30)
			_box(ci, root, "root page", c, ph >= 1)
			for i in 3:
				var mr := Rect2(o.x + 70 + i * (r.size.x - 260) / 2.0, o.y + 88, 120, 30)
				ci.draw_line(Vector2(mid.x, root.end.y), Vector2(mr.get_center().x, mr.position.y), UI.hot(c, 1.6) if (i == 1 and ph >= 2) else Color(1, 1, 1, 0.2), 2.0, true)
				_box(ci, mr, "branch", c, i == 1 and ph >= 2)
				for j in 3:
					var lr := Rect2(mr.position.x - 22 + j * 56.0, o.y + 152, 50, 28)
					var on := i == 1 and j == 2 and ph >= 3
					ci.draw_line(Vector2(mr.get_center().x, mr.end.y), Vector2(lr.get_center().x, lr.position.y), UI.hot(c, 1.6) if on else Color(1, 1, 1, 0.15), 1.5, true)
					_box(ci, lr, "rows", c, on, 11)
			UI.ctext(ci, Vector2(mid.x, r.end.y - 20), "1,000,000 rows, found in 3 page reads" if ph >= 3 else "SELECT * FROM users WHERE id = 731204", 13, UI.hot(UI.WARN, 1.3) if ph >= 3 else UI.DIM, "mono")
		"hash":
			var f := fposmod(t * 0.45, 1.0)
			_box(ci, Rect2(o.x + 24, mid.y - 20, 130, 40), "GET user:42", UI.INK)
			ci.draw_circle(Vector2(o.x + 236, mid.y), 34.0, Color(c.r, c.g, c.b, 0.25))
			ci.draw_arc(Vector2(o.x + 236, mid.y), 34.0, 0.0, TAU, 32, UI.hot(c, 1.5), 2.0, true)
			UI.ctext(ci, Vector2(o.x + 236, mid.y), "hash()", 13, UI.INK, "mono")
			for i in 6:
				UI.rrect(ci, Rect2(o.x + 340, o.y + 22 + i * 31.0, 60, 26), UI.hot(c, 1.5) if (i == 3 and f > 0.55) else Color(1, 1, 1, 0.07), 5.0)
				UI.text(ci, Vector2(o.x + 320, o.y + 40 + i * 31.0), str(i), 11, UI.DIM)
			_box(ci, Rect2(r.end.x - 170, o.y + 22 + 3 * 31.0 - 7, 146, 40), "{ name: \"Ada\" }", UI.ACCENT, f > 0.8, 12)
			var pts := [Vector2(o.x + 154, mid.y), Vector2(o.x + 202, mid.y), Vector2(o.x + 270, mid.y), Vector2(o.x + 340, o.y + 35 + 3 * 31.0), Vector2(r.end.x - 170, o.y + 35 + 3 * 31.0)]
			ci.draw_polyline(PackedVector2Array(pts), Color(1, 1, 1, 0.25), 2.0, true)
			var seg := minf(f * 4.0, 3.999)
			var p: Vector2 = pts[int(seg)].lerp(pts[int(seg) + 1], seg - int(seg))
			ci.draw_circle(p, 6.0, UI.hot(Color.WHITE, 2.4))
			UI.ctext(ci, Vector2(mid.x, r.end.y - 16), "bucket 3 of 6", 12, UI.DIM)
		"heap":
			var vals := [2, 5, 3, 9, 7, 8, 4]
			var pos := [Vector2(0, 0), Vector2(-70, 54), Vector2(70, 54), Vector2(-105, 108), Vector2(-35, 108), Vector2(35, 108), Vector2(105, 108)]
			var cen := Vector2(o.x + 190, o.y + 46)
			for i in range(1, 7):
				ci.draw_line(cen + pos[i], cen + pos[(i - 1) >> 1], Color(1, 1, 1, 0.22), 1.5, true)
			for i in 7:
				ci.draw_circle(cen + pos[i], 18.0 + (sin(t * 5.0) * 2.0 if i == 0 else 0.0), c.lightened(0.3) if i == 0 else Color(c.r, c.g, c.b, 0.35))
				UI.ctext(ci, cen + pos[i], str(vals[i]), 14, UI.BG if i == 0 else UI.INK, "title")
			var cpu := Rect2(r.end.x - 170, o.y + 26, 140, 44)
			_box(ci, cpu, "CPU runs: 2", UI.ACCENT, true)
			UI.arrow(ci, cen + Vector2(26, 0), cpu.position + Vector2(-6, 22), UI.hot(UI.ACCENT, 1.5), 2.5)
			var inc := fposmod(t * 0.6, 1.0)
			_box(ci, Rect2(r.end.x - 150, o.y + 110 + inc * 40.0, 100, 32), "new job: 6", UI.WARN, false, 12)
			UI.text(ci, Vector2(r.end.x - 196, r.end.y - 18), "priority numbers: smallest first", 12, UI.DIM)
		"race":
			var parts := [["Sessions", "hash map"], ["DB index", "balanced tree"], ["Job queue", "queue"], ["Scheduler", "heap"], ["Undo", "stack"], ["Activity feed", "array"]]
			var live := int(t / 1.1) % 6
			for i in 6:
				var br := Rect2(o.x + 24 + (i % 3) * (r.size.x - 48) / 3.0, o.y + 26 + (i / 3) * 96.0, (r.size.x - 48) / 3.0 - 12, 78)
				var on := i == live
				UI.rrect(ci, br, Color(c.r, c.g, c.b, 0.3 if on else 0.1), 10.0, UI.hot(c, 1.7) if on else Color(c.r, c.g, c.b, 0.4), 1.5)
				UI.ctext(ci, br.get_center() + Vector2(0, -12), parts[i][0], 14, UI.INK, "title")
				UI.ctext(ci, br.get_center() + Vector2(0, 14), parts[i][1], 13, UI.hot(UI.WARN, 1.3) if on else UI.DIM, "mono")
		"graph":
			var city := [Vector2(0.08, 0.5), Vector2(0.3, 0.2), Vector2(0.36, 0.8), Vector2(0.62, 0.22), Vector2(0.66, 0.78), Vector2(0.92, 0.5)]
			var edges := [[0, 1, 10], [1, 3, 12], [3, 5, 11], [0, 2, 30], [2, 5, 34], [2, 4, 14], [4, 5, 16], [1, 2, 9]]
			var fastest := fposmod(t, 4.0) > 2.0
			var route := [[0, 1], [1, 3], [3, 5]] if fastest else [[0, 2], [2, 5]]
			var area := Rect2(o + Vector2(10, 10), r.size - Vector2(20, 50))
			for e in edges:
				var a: Vector2 = area.position + city[e[0]] * area.size
				var b: Vector2 = area.position + city[e[1]] * area.size
				var on := route.has([e[0], e[1]])
				ci.draw_line(a, b, UI.hot(UI.ACCENT if fastest else UI.WARN, 1.8) if on else Color(1, 1, 1, 0.2), 4.0 if on else 1.5, true)
				UI.ctext(ci, (a + b) / 2.0 + Vector2(0, -10), "%d" % e[2], 12, UI.INK if on else UI.DIM)
			for i in 6:
				var p: Vector2 = area.position + city[i] * area.size
				ci.draw_circle(p, 11.0, UI.hot(c, 1.4) if (i == 0 or i == 5) else Color(c.r, c.g, c.b, 0.6))
				UI.ctext(ci, p, char(65 + i), 12, UI.BG, "title")
			UI.ctext(ci, Vector2(mid.x, r.end.y - 20), "fastest: 3 roads, 33 minutes" if fastest else "fewest roads: 2 roads, 64 minutes", 14, UI.hot(UI.ACCENT if fastest else UI.WARN, 1.3), "title")
		"maze":
			var pc := [Vector2(0.08, 0.3), Vector2(0.26, 0.7), Vector2(0.38, 0.22), Vector2(0.52, 0.66), Vector2(0.64, 0.2), Vector2(0.76, 0.7), Vector2(0.88, 0.28), Vector2(0.94, 0.74)]
			var cables := [[0, 1], [2, 4], [5, 7], [1, 3], [4, 6], [3, 5], [2, 3]]
			var count := int(t / 0.9) % (cables.size() + 3)
			var par := [0, 1, 2, 3, 4, 5, 6, 7]
			var area := Rect2(o + Vector2(10, 10), r.size - Vector2(20, 50))
			for k in mini(count, cables.size()):
				var ra: int = cables[k][0]
				var rb: int = cables[k][1]
				while par[ra] != ra:
					ra = par[ra]
				while par[rb] != rb:
					rb = par[rb]
				par[ra] = rb
				ci.draw_line(area.position + pc[cables[k][0]] * area.size, area.position + pc[cables[k][1]] * area.size, Color(1, 1, 1, 0.5), 2.0, true)
			var roots: Array = []
			for i in 8:
				var x: int = i
				while par[x] != x:
					x = par[x]
				roots.append(x)
			for i in 8:
				var p: Vector2 = area.position + pc[i] * area.size
				UI.rrect(ci, Rect2(p - Vector2(15, 12), Vector2(30, 24)), UI.hue(float(roots[i]) * 1.7, 8.0), 5.0)
				UI.ctext(ci, p, char(65 + i), 12, UI.BG, "title")
			var linked: bool = roots[0] == roots[7]
			UI.ctext(ci, Vector2(mid.x, r.end.y - 20), "Can A reach H?  %s" % ("Yes: same group." if linked else "Not yet."), 14, UI.hot(UI.ACCENT if linked else UI.WARN, 1.3), "title")
		"boss":
			var ph := int(t / 1.6) % 3
			var lines := ["  for (const e of emails) {", "    if (!out.includes(e)) out.push(e)", "  }"]
			UI.text(ci, o + Vector2(24, 30), "Pull request #418   dedupe signups", 13, UI.DIM)
			for i in 3:
				if i == 1:
					UI.rrect(ci, Rect2(o.x + 16, o.y + 42 + i * 24.0, r.size.x - 32, 24), Color(UI.BAD.r, UI.BAD.g, UI.BAD.b, 0.22), 4.0)
				UI.text(ci, Vector2(o.x + 24, o.y + 60 + i * 24.0), lines[i], 13, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "mono")
			if ph >= 1:
				UI.rrect(ci, Rect2(o.x + 40, o.y + 122, r.size.x - 150, 40), UI.PANEL2, 10.0, UI.hot(UI.WARN, 1.4), 1.5)
				UI.text(ci, Vector2(o.x + 54, o.y + 147), "You: includes() scans out every time. O(n²) at 50k emails. Set?", 13, UI.INK)
			if ph >= 2:
				UI.rrect(ci, Rect2(o.x + 160, o.y + 172, r.size.x - 200, 36), UI.PANEL2, 10.0, UI.hot(UI.ACCENT, 1.4), 1.5)
				UI.text(ci, Vector2(o.x + 174, o.y + 195), "Assistant: Good catch. Switched to a Set: O(n).", 13, UI.INK)
