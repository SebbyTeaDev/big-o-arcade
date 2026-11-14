extends "res://levels/level_base.gd"
# Pathfinder: BFS (queue), DFS (stack) and Dijkstra (priority queue) on a paintable grid.

const GW := 32
const GH := 15
const CS := 33.0
const X0 := 96.0
const Y0 := 178.0
const ALG := ["BFS", "DFS", "Dijkstra"]
const ALG_COL := [UI.BLUE, UI.PURPLE, UI.ACCENT]
const ALG_NOTE := [
	"BFS keeps its frontier in a QUEUE: oldest discovery first. It spreads in rings, so the first time it touches the goal is the route with the fewest steps. It is blind to mud.",
	"DFS keeps its frontier in a STACK: newest discovery first. It dives down one corridor as far as it can. It finds A route, usually a silly one.",
	"Dijkstra keeps its frontier in a PRIORITY QUEUE (a heap): cheapest total cost first. It spreads like water finding the lowest ground, so it finds the cheapest route even through mixed terrain.",
]
const MUD_COST := 5

var cells: Array = []
var start_i := 7 * GW + 4
var goal_i := 7 * GW + 27
var brush := 1
var painting := false

var alg := -1
var running := false
var frontier: Array = []
var qh := 0
var seen: Array = []
var done_cells: Array = []
var dist: Array = []
var prev: Array = []
var order: Array = []
var visit_at: Array = []
var visited := 0
var acc := 0.0
var path: Array = []
var path_at := 0.0
var results := {}
var all_three := false
var beat_bfs := false

var msg: Label
var alg_btns: Array = []
var brush_btns: Array = []


func _ready() -> void:
	header("Chapter 15: graphs and shortest paths. The frontier's data structure IS the algorithm.")
	for i in 3:
		alg_btns.append(UI.button(self, ALG[i], Vector2(40 + i * 104, 92), Vector2(96, 38), _run.bind(i), 15, ALG_COL[i]))
	UI.label(self, "Paint:", Vector2(372, 100), 14, UI.DIM)
	var names := ["Erase", "Wall", "Mud (cost 5)"]
	for i in 3:
		brush_btns.append(UI.button(self, names[i], Vector2(424 + i * 118, 92), Vector2(110, 38), _set_brush.bind(i), 14, tint))
	UI.button(self, "Mud shortcut", Vector2(800, 92), Vector2(130, 38), _preset_mud, 14, tint)
	UI.button(self, "Random walls", Vector2(938, 92), Vector2(130, 38), _preset_random, 14, tint)
	UI.button(self, "Clear map", Vector2(1076, 92), Vector2(110, 38), _preset_clear, 14, tint)
	msg = UI.label(self, "", Vector2(40, 132), 14, UI.INK, 1200)
	for i in GW * GH:
		cells.append(0)
	_preset_mud()
	_set_brush(1)
	msg.text = "The brown band is mud: crossing a mud cell costs 5 instead of 1. Run BFS, then Dijkstra, and compare the routes. Drag on the map to paint your own."


func _set_brush(i: int) -> void:
	brush = i
	for j in 3:
		UI.select(brush_btns[j], j == brush, tint)


func _map_changed() -> void:
	results = {}
	_reset_run()


func _reset_run() -> void:
	alg = -1
	running = false
	path = []
	visited = 0
	seen = []
	done_cells = []
	dist = []
	prev = []
	order = []
	visit_at = []
	for i in GW * GH:
		seen.append(false)
		done_cells.append(false)
		dist.append(1e9)
		prev.append(-1)
		order.append(-1)
		visit_at.append(0.0)


func _preset_clear() -> void:
	for i in GW * GH:
		cells[i] = 0
	_map_changed()
	msg.text = "Blank map. With no obstacles and no mud, BFS and Dijkstra agree."


func _preset_mud() -> void:
	for i in GW * GH:
		cells[i] = 0
	for y in range(3, 12):
		for x in range(10, 22):
			cells[y * GW + x] = 2
	_map_changed()
	msg.text = "Mud shortcut: the straight line runs through 12 cells of mud. Fewest steps and lowest cost are now different routes."


func _preset_random() -> void:
	for attempt in 30:
		for i in GW * GH:
			cells[i] = 1 if randf() < 0.27 else (2 if randf() < 0.12 else 0)
		cells[start_i] = 0
		cells[goal_i] = 0
		if _reachable():
			break
	_map_changed()
	msg.text = "Random walls with patches of mud. DFS tends to wander; BFS and Dijkstra stay disciplined."


func _reachable() -> bool:
	var q := [start_i]
	var mark := {start_i: true}
	var head := 0
	while head < q.size():
		var u: int = q[head]
		head += 1
		if u == goal_i:
			return true
		for v in _nbrs(u):
			if not mark.has(v):
				mark[v] = true
				q.append(v)
	return false


func _nbrs(u: int) -> Array:
	var out: Array = []
	var x := u % GW
	var y := u / GW
	if x + 1 < GW and cells[u + 1] != 1:
		out.append(u + 1)
	if y + 1 < GH and cells[u + GW] != 1:
		out.append(u + GW)
	if x > 0 and cells[u - 1] != 1:
		out.append(u - 1)
	if y > 0 and cells[u - GW] != 1:
		out.append(u - GW)
	return out


func _cost(i: int) -> int:
	return MUD_COST if cells[i] == 2 else 1


func _run(i: int) -> void:
	_reset_run()
	alg = i
	running = true
	acc = 0.0
	frontier = [start_i]
	qh = 0
	seen[start_i] = true
	dist[start_i] = 0
	for j in 3:
		UI.select(alg_btns[j], j == i, ALG_COL[j])
	msg.text = ALG_NOTE[i]


func _visit(u: int) -> void:
	done_cells[u] = true
	order[u] = visited
	visit_at[u] = t
	visited += 1


func _step() -> void:
	var u := -1
	match alg:
		0:
			if qh >= frontier.size():
				_fail()
				return
			u = frontier[qh]
			qh += 1
			_visit(u)
			if u == goal_i:
				_found()
				return
			for v in _nbrs(u):
				if not seen[v]:
					seen[v] = true
					prev[v] = u
					frontier.append(v)
		1:
			while not frontier.is_empty():
				var c: int = frontier.pop_back()
				if not done_cells[c]:
					u = c
					break
			if u == -1:
				_fail()
				return
			_visit(u)
			if u == goal_i:
				_found()
				return
			var nb := _nbrs(u)
			nb.reverse()
			for v in nb:
				if not done_cells[v]:
					prev[v] = u
					seen[v] = true
					frontier.append(v)
		2:
			while not frontier.is_empty():
				var bi := 0
				for k in range(1, frontier.size()):
					if dist[frontier[k]] < dist[frontier[bi]]:
						bi = k
				var c: int = frontier[bi]
				frontier[bi] = frontier.back()
				frontier.pop_back()
				if not done_cells[c]:
					u = c
					break
			if u == -1:
				_fail()
				return
			_visit(u)
			if u == goal_i:
				_found()
				return
			for v in _nbrs(u):
				var nd: float = dist[u] + _cost(v)
				if nd < dist[v]:
					dist[v] = nd
					prev[v] = u
					seen[v] = true
					frontier.append(v)


func _fail() -> void:
	running = false
	sfx("bad")
	msg.text = "No route exists: the goal is walled off. %s still had to look at every reachable cell (%d) to be sure." % [ALG[alg], visited]


func _found() -> void:
	running = false
	path = []
	var u := goal_i
	var cost := 0
	while u != -1:
		path.append(u)
		if u != start_i:
			cost += _cost(u)
		u = prev[u]
	path.reverse()
	path_at = t
	results[alg] = {"visited": visited, "steps": path.size() - 1, "cost": cost}
	sfx("ok")
	burst(_center(goal_i), ALG_COL[alg], 34)
	if results.size() == 3:
		all_three = true
	if results.has(0) and results.has(2) and int(results[2]["cost"]) < int(results[0]["cost"]):
		beat_bfs = true
	var stars := 1
	if all_three:
		stars = 2
	if all_three and beat_bfs:
		stars = 3
	finish(stars, stars == 3)
	var extra := ""
	if alg == 2 and results.has(0) and int(results[2]["cost"]) < int(results[0]["cost"]):
		extra = "  Dijkstra's route is longer in steps but cheaper: cost %d vs BFS's %d." % [results[2]["cost"], results[0]["cost"]]
	elif stars < 3:
		extra = "  For three stars: run all three on one map where Dijkstra's cost beats BFS's."
	msg.text = "%s: looked at %d cells, route is %d steps, total cost %d.%s" % [ALG[alg], visited, path.size() - 1, cost, extra]


func tick(delta: float) -> void:
	if not running:
		return
	acc += delta * 150.0
	var k := int(acc)
	acc -= k
	for i in k:
		if running:
			_step()
	if k > 0 and visited % 4 == 0:
		sfx("tick", 0.6 + float(visited) / (GW * GH) * 1.6)


func _cell_at(p: Vector2) -> int:
	var x := int((p.x - X0) / CS)
	var y := int((p.y - Y0) / CS)
	if p.x < X0 or p.y < Y0 or x >= GW or y >= GH:
		return -1
	return y * GW + x


func _paint(p: Vector2) -> void:
	var i := _cell_at(p)
	if i < 0 or i == start_i or i == goal_i or cells[i] == brush:
		return
	cells[i] = brush
	_map_changed()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		painting = event.pressed
		if painting:
			_paint(event.position)
	elif event is InputEventMouseMotion and painting:
		_paint(event.position)


func _rect(i: int) -> Rect2:
	return Rect2(X0 + (i % GW) * CS + 1.0, Y0 + (i / GW) * CS + 1.0, CS - 2.0, CS - 2.0)


func _center(i: int) -> Vector2:
	return _rect(i).get_center()


func _draw() -> void:
	var total := float(maxi(visited, 1))
	var base: Color = ALG_COL[alg] if alg >= 0 else UI.BLUE
	for i in GW * GH:
		var r := _rect(i)
		var kind: int = cells[i]
		if kind == 1:
			UI.rrect(self, r, Color("3b4263"), 6.0, Color(1, 1, 1, 0.14), 1.0)
			continue
		var c := Color(0.085, 0.1, 0.16, 0.9)
		if kind == 2:
			c = Color("5a3f22")
		if alg >= 0 and done_cells[i]:
			var age := clampf((t - visit_at[i]) / 0.5, 0.0, 1.0)
			var vc := base.lerp(UI.PINK, float(order[i]) / total * 0.8)
			vc = vc.darkened(0.45)
			if kind == 2:
				vc = vc.lerp(Color("5a3f22"), 0.45)
			c = UI.hot(vc.lerp(Color.WHITE, (1.0 - age) * 0.7), 1.0 + (1.0 - age) * 1.4)
		elif alg >= 0 and seen[i] and running:
			c = UI.hot(base, 1.5)
		draw_rect(r, c)
	# route
	if path.size() > 1:
		var n := mini(path.size(), int((t - path_at) * 70.0) + 2)
		var pts := PackedVector2Array()
		for i in n:
			pts.append(_center(path[i]))
		if pts.size() > 1:
			draw_polyline(pts, UI.hot(Color.WHITE, 2.6), 5.0, true)
	draw_circle(_center(start_i), 12.0, UI.hot(UI.ACCENT, 2.0))
	UI.ctext(self, _center(start_i), "S", 14, UI.BG, "title")
	draw_circle(_center(goal_i), 12.0 + sin(t * 5.0) * 1.5, UI.hot(UI.WARN, 2.0))
	UI.ctext(self, _center(goal_i), "G", 14, UI.BG, "title")
	# scoreboard
	for a in 3:
		var x := 96.0 + a * 366.0
		var s := "%s:  not run on this map" % ALG[a]
		var c := Color(1, 1, 1, 0.3)
		if results.has(a):
			var r: Dictionary = results[a]
			s = "%s:  %d cells searched,  %d steps,  cost %d" % [ALG[a], r["visited"], r["steps"], r["cost"]]
			c = UI.hot(ALG_COL[a], 1.3)
		UI.text(self, Vector2(x, 702), s, 14, c, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")


func demo() -> void:
	await main.click(Vector2(88, 110))
	await main.wait(3.5)
	await main.click(Vector2(290, 110))
	await main.wait(3.2)
