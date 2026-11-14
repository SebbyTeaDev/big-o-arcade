extends "res://levels/level_base.gd"
# Stack Machine: run the balanced-symbol checker by hand, then sort stack jobs from queue jobs.

const PAIR := {"(": ")", "[": "]", "{": "}"}
const EXPRS := ["( [ ] )", "{ ( ) [ ( ) ] }", "( [ ) ]", "{ [ ( ) ] } )", "( ( [ ] )", "{ [ ( ) ( ) ] { } }"]
const SCEN := [
	{"q": "Undo in a text editor", "a": 0, "why": "The most recent change is undone first. Last in, first out."},
	{"q": "Print jobs sent to one office printer", "a": 1, "why": "First document sent is the first one printed. First in, first out."},
	{"q": "The browser's Back button", "a": 0, "why": "Back returns to the page you visited most recently, then the one before that."},
	{"q": "Function calls: main calls a(), a() calls b(). Who has to finish first?", "a": 0, "why": "b() returns before a(), which returns before main. That is the call stack, and it is why recursion works at all."},
	{"q": "Exploring a map by visiting all the nearest places first", "a": 1, "why": "Places are handled in the order they were discovered. That is breadth-first search: its frontier is a queue (see Pathfinder)."},
	{"q": "Customers waiting on hold for support", "a": 1, "why": "Whoever has waited longest is served next. Fairness is FIFO."},
]

var phase := 0          # 0 = bracket machine, 1 = stack-or-queue quiz, 2 = done
var ei := 0
var tokens: Array = []
var ti := 0
var stack: Array = []
var stack_y: Array = []
var mistakes := 0
var expr_done := false
var qi := 0
var q_answered := false
var ghost := ""
var ghost_at := -9.0

var title_l: Label
var msg: Label
var act_btns: Array = []
var next_btn: Button
var ab_btns: Array = []


func _ready() -> void:
	header("Chapters 12 and 16: last in first out, first in first out")
	title_l = UI.label(self, "", Vector2(40, 88), 20, UI.INK, 1200, "title")
	msg = UI.label(self, "", Vector2(40, 596), 16, UI.WARN, 900)
	var names := ["Push", "Pop", "Reject", "Accept"]
	var acts := ["push", "pop", "reject", "accept"]
	var cols := [UI.BLUE, UI.PINK, UI.BAD, UI.ACCENT]
	for i in 4:
		act_btns.append(UI.button(self, names[i], Vector2(40 + i * 176, 520), Vector2(166, 54), _act.bind(acts[i]), 20, cols[i]))
	ab_btns.append(UI.button(self, "STACK   last in, first out", Vector2(120, 520), Vector2(360, 56), _answer.bind(0), 18, UI.PINK))
	ab_btns.append(UI.button(self, "QUEUE   first in, first out", Vector2(640, 520), Vector2(360, 56), _answer.bind(1), 18, UI.BLUE))
	next_btn = UI.button(self, "Next", Vector2(1090, 646), Vector2(150, 48), _next, 18, tint)
	_load_expr()


func _load_expr() -> void:
	phase = 0
	tokens = Array(EXPRS[ei].split(" "))
	ti = 0
	stack = []
	stack_y = []
	expr_done = false
	next_btn.visible = false
	title_l.text = "Expression %d of %d.  You are the machine: read one symbol at a time and choose what the stack does." % [ei + 1, EXPRS.size()]
	msg.text = "Openers wait on the stack. A closer must match the TOP of the stack. At the end the stack must be empty."
	msg.add_theme_color_override("font_color", UI.DIM)
	for b in act_btns:
		b.visible = true
		b.disabled = false
	for b in ab_btns:
		b.visible = false


func _expected() -> String:
	if ti >= tokens.size():
		return "accept" if stack.is_empty() else "reject"
	var tok: String = tokens[ti]
	if PAIR.has(tok):
		return "push"
	if stack.is_empty() or PAIR[stack.back()] != tok:
		return "reject"
	return "pop"


func _hint() -> String:
	if ti >= tokens.size():
		if stack.is_empty():
			return "The input is finished and the stack is empty, so every symbol found its partner: Accept."
		return "The input is finished but the stack still holds unmatched openers: Reject."
	var tok: String = tokens[ti]
	if PAIR.has(tok):
		return "%s is an opener. Openers always go ON the stack to wait for their partner: Push." % tok
	if stack.is_empty():
		return "%s is a closer, but the stack is empty. Nothing to match it with: Reject." % tok
	if PAIR[stack.back()] != tok:
		return "The top of the stack is %s, which needs %s. This is %s: wrong partner, so Reject." % [stack.back(), PAIR[stack.back()], tok]
	return "%s closes the %s on top of the stack. They match: Pop." % [tok, stack.back()]


func _act(a: String) -> void:
	if expr_done or phase != 0:
		return
	if a != _expected():
		mistakes += 1
		sfx("bad")
		shake()
		msg.text = _hint()
		msg.add_theme_color_override("font_color", UI.WARN)
		return
	msg.add_theme_color_override("font_color", UI.DIM)
	match a:
		"push":
			stack.append(tokens[ti])
			stack_y.append(-260.0)
			ti += 1
			sfx("pop", 0.9 + 0.1 * stack.size())
			msg.text = "Pushed. The stack now remembers %d unmatched opener%s, most recent on top." % [stack.size(), "" if stack.size() == 1 else "s"]
		"pop":
			ghost = stack.pop_back()
			stack_y.pop_back()
			ghost_at = t
			ti += 1
			sfx("tick", 1.5)
			msg.text = "Matched and popped. Only the top is ever touched: push and pop are both O(1)."
		"reject":
			_end_expr(false)
		"accept":
			_end_expr(true)


func _end_expr(ok: bool) -> void:
	expr_done = true
	sfx("ok")
	burst(Vector2(1110, 300), UI.ACCENT if ok else UI.BAD, 30)
	msg.text = ("Balanced. " if ok else "Not balanced, and you caught it. ") + "One pass, one stack: O(n). This is exactly how compilers check your brackets."
	msg.add_theme_color_override("font_color", UI.ACCENT)
	for b in act_btns:
		b.disabled = true
	next_btn.text = "Next"
	next_btn.visible = true


func _load_q() -> void:
	phase = 1
	q_answered = false
	next_btn.visible = false
	for b in act_btns:
		b.visible = false
	for b in ab_btns:
		b.visible = true
		b.disabled = false
		b.modulate = Color.WHITE
	title_l.text = "Stack or queue?   %d of %d:   %s" % [qi + 1, SCEN.size(), SCEN[qi]["q"]]
	msg.text = "Watch the two below: the same five items go in. They come out in opposite orders."
	msg.add_theme_color_override("font_color", UI.DIM)


func _answer(i: int) -> void:
	if q_answered or phase != 1:
		return
	q_answered = true
	var a: int = SCEN[qi]["a"]
	for b in ab_btns:
		b.disabled = true
		b.modulate = Color(1, 1, 1, 0.4)
	ab_btns[a].modulate = UI.hot(UI.ACCENT, 1.5)
	if i == a:
		sfx("ok")
		burst(ab_btns[a].position + ab_btns[a].size / 2.0, UI.ACCENT, 26)
		msg.text = "Right. " + SCEN[qi]["why"]
		msg.add_theme_color_override("font_color", UI.ACCENT)
	else:
		mistakes += 1
		sfx("bad")
		shake()
		msg.text = "Not quite. " + SCEN[qi]["why"]
		msg.add_theme_color_override("font_color", UI.WARN)
	next_btn.text = "Next" if qi < SCEN.size() - 1 else "Finish"
	next_btn.visible = true


func _next() -> void:
	if phase == 2:
		ei = 0
		qi = 0
		mistakes = 0
		_load_expr()
		return
	if phase == 0:
		if ei < EXPRS.size() - 1:
			ei += 1
			_load_expr()
		else:
			_load_q()
		return
	if qi < SCEN.size() - 1:
		qi += 1
		_load_q()
		return
	phase = 2
	finish(3 if mistakes <= 1 else (2 if mistakes <= 5 else 1))
	for b in ab_btns:
		b.visible = false
	title_l.text = "Done with %d mistake%s." % [mistakes, "" if mistakes == 1 else "s"]
	msg.text = "A stack and a queue are the same idea with one rule changed: which end do you take from? Both do their two operations in O(1). Choosing between them is about ORDER, not speed."
	msg.add_theme_color_override("font_color", UI.INK)
	next_btn.text = "Play again"


func tick(delta: float) -> void:
	var k := 1.0 - exp(-delta * 14.0)
	for i in stack_y.size():
		stack_y[i] = lerpf(stack_y[i], 0.0, k)


func _tok_col(s: String) -> Color:
	if s == "(" or s == ")":
		return UI.BLUE
	if s == "[" or s == "]":
		return UI.ACCENT
	return UI.PINK


func _draw() -> void:
	if phase == 0:
		_draw_machine()
	else:
		_draw_tubes()


func _draw_machine() -> void:
	var n := tokens.size()
	var w := 66.0
	var x0 := 40.0 + (900.0 - n * (w + 10.0)) / 2.0
	UI.text(self, Vector2(40, 170), "INPUT", 13, UI.DIM)
	for i in n:
		var r := Rect2(x0 + i * (w + 10.0), 190, w, 84)
		var c := _tok_col(tokens[i])
		var here := i == ti and not expr_done
		if here:
			UI.rrect(self, r.grow(5.0), UI.CLEAR, 16.0, UI.hot(Color.WHITE, 1.8), 3.0)
		UI.rrect(self, r, UI.PANEL2 if i >= ti else UI.PANEL, 12.0, Color(c.r, c.g, c.b, 0.9 if i >= ti else 0.15), 2.0)
		UI.ctext(self, r.get_center(), tokens[i], 38, UI.hot(c, 1.4) if i >= ti else Color(c.r, c.g, c.b, 0.3), "mono")
	if ti >= n and not expr_done:
		UI.text(self, Vector2(x0 + n * (w + 10.0) + 6, 240), "end of input", 15, UI.hot(Color.WHITE, 1.4))
	# the stack
	var base := Vector2(1010, 500)
	UI.text(self, Vector2(base.x, 170), "STACK", 13, UI.DIM)
	draw_line(base + Vector2(-8, 8), base + Vector2(208, 8), Color(1, 1, 1, 0.5), 3.0)
	draw_line(base + Vector2(-8, 8), base + Vector2(-8, -300), Color(1, 1, 1, 0.2), 3.0)
	draw_line(base + Vector2(208, 8), base + Vector2(208, -300), Color(1, 1, 1, 0.2), 3.0)
	for i in stack.size():
		var c := _tok_col(stack[i])
		var r := Rect2(base.x, base.y - 46.0 - i * 50.0 + stack_y[i], 200, 44)
		var top := i == stack.size() - 1
		UI.rrect(self, r, UI.hot(c, 1.35) if top else c.darkened(0.35), 10.0)
		UI.ctext(self, r.get_center(), stack[i], 28, UI.BG, "mono")
		if top:
			UI.text(self, Vector2(r.position.x - 56, r.position.y + 28), "top", 14, UI.hot(Color.WHITE, 1.4))
	if stack.is_empty():
		UI.ctext(self, base + Vector2(100, -30), "empty", 15, UI.DIM)
	var g := (t - ghost_at) / 0.5
	if g < 1.0:
		var c := _tok_col(ghost)
		UI.ctext(self, base + Vector2(100, -60.0 - stack.size() * 50.0 - g * 90.0), ghost + " " + PAIR[ghost], 30, Color(c.r * 1.6, c.g * 1.6, c.b * 1.6, 1.0 - g), "mono")


func _draw_tubes() -> void:
	if phase == 2:
		return
	var tau := fposmod(t, 7.5)
	var entered := clampi(int(tau / 0.5), 0, 5)
	var left := clampi(int((tau - 3.5) / 0.5), 0, 5)
	# stack tube
	var sb := Vector2(250, 470)
	UI.text(self, Vector2(sb.x - 30, 170), "STACK", 14, UI.hot(UI.PINK, 1.3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	draw_line(sb + Vector2(-8, 6), sb + Vector2(108, 6), Color(1, 1, 1, 0.5), 3.0)
	draw_line(sb + Vector2(-8, 6), sb + Vector2(-8, -250), Color(1, 1, 1, 0.2), 3.0)
	draw_line(sb + Vector2(108, 6), sb + Vector2(108, -250), Color(1, 1, 1, 0.2), 3.0)
	for i in range(0, entered - left):
		UI.rrect(self, Rect2(sb.x, sb.y - 44.0 - i * 48.0, 100, 42), UI.hue(i, 6.0), 9.0)
		UI.ctext(self, Vector2(sb.x + 50, sb.y - 23.0 - i * 48.0), str(i + 1), 22, UI.BG, "title")
	UI.text(self, Vector2(sb.x - 30, 500), "out:", 14, UI.DIM)
	for j in left:
		UI.ctext(self, Vector2(sb.x + 24 + j * 26, 495), str(5 - j), 20, UI.hot(UI.hue(4 - j, 6.0), 1.4), "title")
	# queue pipe
	var qb := Vector2(620, 330)
	UI.text(self, Vector2(qb.x, 170), "QUEUE", 14, UI.hot(UI.BLUE, 1.3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	draw_line(qb + Vector2(0, -8), qb + Vector2(420, -8), Color(1, 1, 1, 0.3), 3.0)
	draw_line(qb + Vector2(0, 56), qb + Vector2(420, 56), Color(1, 1, 1, 0.3), 3.0)
	UI.text(self, qb + Vector2(-44, 30), "in", 14, UI.DIM)
	UI.text(self, qb + Vector2(432, 30), "out", 14, UI.DIM)
	for i in range(left, entered):
		var slot := i - left
		var x := qb.x + 420.0 - 82.0 - slot * 82.0
		UI.rrect(self, Rect2(x, qb.y, 76, 48), UI.hue(i, 6.0), 9.0)
		UI.ctext(self, Vector2(x + 38, qb.y + 24), str(i + 1), 22, UI.BG, "title")
	UI.text(self, Vector2(qb.x, 500), "out:", 14, UI.DIM)
	for j in left:
		UI.ctext(self, Vector2(qb.x + 54 + j * 26, 495), str(j + 1), 20, UI.hot(UI.hue(j, 6.0), 1.4), "title")


func demo() -> void:
	ei = 2
	_load_expr()
	await main.click(act_btns[0].position + Vector2(40, 20))
	await main.click(act_btns[0].position + Vector2(40, 20))
	await main.click(act_btns[1].position + Vector2(40, 20))
	await main.wait(0.5)
