extends Control
# Step-through code viewer: a small debugger for the snippets in traces.gd.
# Shows the current line, how often each line has run, the variables, the data,
# a plain-English note, and a running count of the work done.

const UI = preload("res://ui.gd")
const Traces = preload("res://traces.gd")

const CODE := Rect2(40, 84, 640, 392)
const NOTE := Rect2(700, 84, 540, 112)
const DATA := Rect2(700, 206, 540, 270)
const COUNT := Rect2(40, 488, 640, 104)
const TOTALS := Rect2(700, 488, 540, 104)

var level
var ids: Array = []
var reveal := true
var idx := 0
var size_i := 0
var tr
var cur := 0
var playing := false
var acc := 0.0
var done_once := false
var totals: Array = []
var hits: Array = []
var tm := 0.0
var bump := -9.0
var tint: Color = UI.ACCENT

var code_label: RichTextLabel
var code_marks: Control
var note_label: Label
var title_label: Label
var play_btn: Button
var next_btn: Button
var size_btns: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20
	if level != null:
		tint = level.tint
	UI.label(self, "STEP THROUGH THE CODE", Vector2(40, 18), 13, UI.DIM)
	title_label = UI.label(self, "", Vector2(40, 36), 26, UI.INK, 0.0, "title")
	UI.button(self, "Close", Vector2(1140, 26), Vector2(100, 40), close, 15, tint)
	UI.panel(self, CODE, Color("0f111b"))
	code_marks = Control.new()
	code_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code_marks.draw.connect(_draw_code_marks)
	add_child(code_marks)
	code_label = RichTextLabel.new()
	code_label.bbcode_enabled = true
	code_label.position = CODE.position + Vector2(76, 20)
	code_label.size = CODE.size - Vector2(92, 76)
	code_label.scroll_active = false
	code_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	code_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code_label.add_theme_font_override("normal_font", UI.font("mono"))
	code_label.add_theme_font_size_override("normal_font_size", 16)
	code_label.add_theme_color_override("default_color", UI.INK)
	add_child(code_label)
	note_label = UI.label(self, "", NOTE.position + Vector2(20, 34), 17, UI.INK, NOTE.size.x - 40.0)
	UI.button(self, "Restart", Vector2(40, 612), Vector2(104, 46), _restart, 15, tint)
	UI.button(self, "< Back", Vector2(152, 612), Vector2(100, 46), _step.bind(-1), 15, tint)
	UI.button(self, "Step >", Vector2(260, 612), Vector2(130, 46), _step.bind(1), 18, tint)
	play_btn = UI.button(self, "Play", Vector2(398, 612), Vector2(104, 46), _toggle_play, 15, tint)
	UI.button(self, "Run to end", Vector2(510, 612), Vector2(130, 46), _to_end, 15, tint)
	UI.label(self, "Input size", Vector2(700, 624), 14, UI.DIM)
	for i in 3:
		size_btns.append(UI.button(self, "", Vector2(786 + i * 94, 612), Vector2(86, 46), _pick_size.bind(i), 15, tint))
	next_btn = UI.button(self, "Next example", Vector2(1084, 612), Vector2(156, 46), _next_trace, 15, tint)
	UI.label(self, "Keys:  Right or Space = step     Left = back     Esc = close", Vector2(40, 676), 13, UI.DIM)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	_load()


func close() -> void:
	if level != null:
		level.overlay = null
	queue_free()


func _load() -> void:
	var id: String = ids[idx]
	var meta: Dictionary = Traces.info(id)
	var sizes: Array = meta["sizes"]
	tr = Traces.build(id, sizes[size_i])
	totals = []
	for s in sizes:
		totals.append(Traces.build(id, s).ops)
	cur = 0
	playing = false
	acc = 0.0
	play_btn.text = "Play"
	title_label.text = meta["title"]
	code_label.text = UI.highlight(tr.code)
	next_btn.visible = ids.size() > 1
	for i in 3:
		size_btns[i].text = "n = %d" % sizes[i]
		UI.select(size_btns[i], i == size_i, tint)
	_sync()


func _sync() -> void:
	var st: Dictionary = tr.steps[cur]
	note_label.text = st["note"]
	hits = []
	for i in tr.code.count("\n") + 1:
		hits.append(0)
	for i in cur + 1:
		var ln: int = tr.steps[i]["line"]
		if ln < hits.size():
			hits[ln] += 1
	if cur == tr.steps.size() - 1:
		done_once = true
		playing = false
		play_btn.text = "Play"


func _step(d: int) -> void:
	var before := cur
	cur = clampi(cur + d, 0, tr.steps.size() - 1)
	if cur == before:
		return
	_sync()
	if d > 0 and int(tr.steps[cur]["count"]) > 0:
		bump = tm
		if level != null:
			level.sfx("tick", 0.8 + minf(float(tr.steps[cur]["ops"]) * 0.02, 1.4))


func _restart() -> void:
	cur = 0
	playing = false
	play_btn.text = "Play"
	_sync()


func _to_end() -> void:
	cur = tr.steps.size() - 1
	bump = tm
	_sync()


func _toggle_play() -> void:
	if cur >= tr.steps.size() - 1:
		cur = 0
	playing = not playing
	play_btn.text = "Pause" if playing else "Play"
	_sync()


func _pick_size(i: int) -> void:
	size_i = i
	_load()


func _next_trace() -> void:
	idx = (idx + 1) % ids.size()
	size_i = 0
	done_once = false
	_load()


func _process(delta: float) -> void:
	tm += delta
	if playing:
		acc += delta * (5.0 if tr.steps.size() < 60 else (12.0 if tr.steps.size() < 200 else 30.0))
		while acc >= 1.0 and playing:
			acc -= 1.0
			_step(1)
	queue_redraw()
	code_marks.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT, KEY_SPACE:
				_step(1)
			KEY_LEFT:
				_step(-1)
			KEY_ESCAPE:
				close()
		get_viewport().set_input_as_handled()


func _line_y(line: int) -> float:
	if line < code_label.get_line_count():
		return code_label.position.y + code_label.get_line_offset(line)
	return code_label.position.y + line * 24.0


# Drawn on its own layer so it sits above the code panel but below the code text.
func _draw_code_marks() -> void:
	var st: Dictionary = tr.steps[cur]
	var lc := UI.WARN if st["hidden"] else tint
	var lh := _line_y(1) - _line_y(0)
	if lh <= 1.0:
		lh = 22.0
	var ly := _line_y(st["line"])
	UI.rrect(code_marks, Rect2(CODE.position.x + 6, ly - 2, CODE.size.x - 12, lh + 3), Color(lc.r, lc.g, lc.b, 0.22), 6.0)
	code_marks.draw_rect(Rect2(CODE.position.x + 6, ly - 2, 4, lh + 3), UI.hot(lc, 1.8))
	code_marks.draw_line(Vector2(CODE.position.x + 64, CODE.position.y + 14), Vector2(CODE.position.x + 64, CODE.end.y - 44), Color(1, 1, 1, 0.08), 1.0)
	for i in hits.size():
		if hits[i] > 0:
			var here := i == int(st["line"])
			UI.text(code_marks, Vector2(CODE.position.x + 10, _line_y(i) + lh * 0.74), "%dx" % hits[i], 12, UI.hot(lc, 1.4) if here else UI.DIM, HORIZONTAL_ALIGNMENT_RIGHT, 46.0, "mono")
	UI.text(code_marks, Vector2(CODE.position.x + 20, CODE.end.y - 16), "The bar marks the line that just ran. The left column counts the stops on each line so far.", 12, UI.DIM)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.03, 0.035, 0.06, 1.0))
	var st: Dictionary = tr.steps[cur]
	var hidden: bool = st["hidden"]
	var lc := UI.WARN if hidden else tint

	# note
	UI.rrect(self, NOTE, UI.PANEL2, 12.0, UI.hot(lc, 1.2), 1.5)
	UI.text(self, NOTE.position + Vector2(20, 24), "LIBRARY CALL: A LOOP YOU CANNOT SEE IN THE CODE" if hidden else "WHAT JUST HAPPENED", 12, UI.hot(UI.WARN, 1.3) if hidden else UI.DIM)

	_draw_data(st)

	# running count
	UI.rrect(self, COUNT, UI.PANEL, 12.0, Color(1, 1, 1, 0.07), 1.0)
	UI.text(self, COUNT.position + Vector2(20, 26), "STEPS OF WORK SO FAR", 12, UI.DIM)
	var pulse := clampf(1.0 - (tm - bump) / 0.35, 0.0, 1.0)
	UI.text(self, COUNT.position + Vector2(20, 82), UI.fmt(st["ops"]), 46 + int(pulse * 5.0), UI.hot(tint, 1.25 + pulse * 0.35), HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	UI.text(self, COUNT.position + Vector2(330, 52), "line-by-line: %d of %d" % [cur + 1, tr.steps.size()], 13, UI.DIM)
	UI.rrect(self, Rect2(COUNT.position.x + 330, COUNT.position.y + 64, 290, 8), Color(1, 1, 1, 0.08), 4.0)
	UI.rrect(self, Rect2(COUNT.position.x + 330, COUNT.position.y + 64, maxf(290.0 * (cur + 1) / tr.steps.size(), 8.0), 8), UI.hot(tint, 1.4), 4.0)

	# how the total grows
	var meta: Dictionary = Traces.info(ids[idx])
	var sizes: Array = meta["sizes"]
	UI.rrect(self, TOTALS, UI.PANEL, 12.0, Color(1, 1, 1, 0.07), 1.0)
	UI.text(self, TOTALS.position + Vector2(20, 26), "TOTAL STEPS AS THE INPUT GROWS   (n = %s)" % meta["n"], 12, UI.DIM)
	for i in 3:
		var x := TOTALS.position.x + 20 + i * 104.0
		UI.text(self, Vector2(x, TOTALS.position.y + 52), "n = %d" % sizes[i], 14, UI.INK if i == size_i else UI.DIM)
		UI.text(self, Vector2(x, TOTALS.position.y + 84), UI.fmt(totals[i]) if done_once else "?", 24, UI.hot(tint, 1.3) if done_once else UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	var verdict := "Run to the end to fill these in."
	var vc := UI.DIM
	if done_once:
		verdict = ("That growth is %s." % meta["o"]) if reveal else "How fast is that growing? Close this and decide."
		vc = UI.hot(UI.WARN, 1.3)
	draw_multiline_string(UI.font("title"), Vector2(TOTALS.position.x + 336, TOTALS.position.y + 52), verdict, HORIZONTAL_ALIGNMENT_LEFT, 190.0, 15, 3, vc)


func _draw_data(st: Dictionary) -> void:
	UI.rrect(self, DATA, UI.PANEL, 12.0, Color(1, 1, 1, 0.07), 1.0)
	var stack: Array = st["stack"]
	var has_stack: bool = st["stack_title"] != ""
	var width := DATA.size.x - 32.0 - (170.0 if has_stack else 0.0)
	var y := DATA.position.y + 30.0
	var arrs: Dictionary = st["arrs"]
	var hl: Dictionary = st["hl"]
	var marks: Dictionary = st["marks"]
	var dim: Dictionary = st["dim"]
	for arr_name in arrs:
		var a: Array = arrs[arr_name]
		UI.text(self, Vector2(DATA.position.x + 16, y - 8), arr_name, 12, UI.DIM)
		var cw := minf(46.0, width / maxi(a.size(), 1))
		var lit: Array = hl.get(arr_name, [])
		for i in a.size():
			var r := Rect2(DATA.position.x + 16 + i * cw, y, cw - 3.0, 30)
			var out := dim.has(arr_name) and (i < int(dim[arr_name][0]) or i > int(dim[arr_name][1]))
			var c := Color(0.09, 0.1, 0.16) if out else UI.PANEL2.lightened(0.08)
			var tc := Color(1, 1, 1, 0.25) if out else UI.INK
			if lit.has(i):
				c = tint.lightened(0.2)
				tc = UI.BG
				UI.rrect(self, r.grow(3.0), UI.CLEAR, 8.0, UI.hot(tint, 2.0), 2.0)
			UI.rrect(self, r, c, 6.0)
			var s := str(a[i])
			if cw >= 14.0:
				UI.ctext(self, r.get_center(), s, 15 if (cw >= 34.0 and s.length() <= 3) else (11 if cw >= 22.0 else 9), tc, "title")
		if marks.has(arr_name):
			var used := {}
			for mk in marks[arr_name]:
				var at_i := int(marks[arr_name][mk])
				var row := int(used.get(at_i, 0))
				used[at_i] = row + 1
				var cx := DATA.position.x + 16 + (at_i + 0.5) * cw - 1.5
				UI.ctext(self, Vector2(cx, y + 40 + row * 13.0), str(mk), 12, UI.hot(UI.WARN, 1.4), "title")
		y += 76.0
	# a grid for loops that fill a table
	var g: Dictionary = st["grid"]
	if not g.is_empty():
		var rows: int = g["rows"]
		var cols: int = g["cols"]
		var cs := minf(40.0, minf((DATA.size.y - 96.0) / rows, width / cols))
		UI.text(self, Vector2(DATA.position.x + 16, y - 8), "one square per step of work  (%d rows x %d columns)" % [rows, cols], 12, UI.DIM)
		for i in rows * cols:
			var r := Rect2(DATA.position.x + 16 + (i % cols) * cs, y + (i / cols) * cs, cs - 2.0, cs - 2.0)
			var c := Color(1, 1, 1, 0.06)
			if i == int(g["cur"]):
				c = UI.hot(Color.WHITE, 2.0)
			elif g["on"][i]:
				c = UI.hot(tint, 1.2)
			draw_rect(r, c)
	# a stack (call stack, bracket stack, or a queue)
	if has_stack:
		var sx := DATA.end.x - 166.0
		UI.text(self, Vector2(sx, DATA.position.y + 22), str(st["stack_title"]).to_upper(), 11, UI.DIM)
		var base := DATA.end.y - 52.0
		var cap := 7
		var first := maxi(0, stack.size() - cap)
		for i in range(first, stack.size()):
			var r := Rect2(sx, base - (i - first) * 28.0, 150, 25)
			var top := i == stack.size() - 1
			UI.rrect(self, r, tint.lightened(0.2) if top else UI.PANEL2.lightened(0.08), 6.0)
			UI.ctext(self, r.get_center(), str(stack[i]), 13, UI.BG if top else UI.INK, "mono")
		if first > 0:
			UI.text(self, Vector2(sx, base + 44), "+ %d more below" % first, 11, UI.DIM)
		elif stack.is_empty():
			UI.text(self, Vector2(sx, base + 18), "(empty)", 12, UI.DIM)
	# variables
	var vars: Dictionary = st["vars"]
	var prev: Dictionary = tr.steps[maxi(cur - 1, 0)]["vars"]
	var vx := DATA.position.x + 16.0
	var vy := DATA.end.y - 20.0
	for vn in vars:
		var s := "%s = %s" % [vn, str(vars[vn])]
		var w := UI.font("mono").get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 20.0
		if vx + w > DATA.end.x - (176.0 if has_stack else 10.0):
			break
		var changed: bool = cur > 0 and str(prev.get(vn, "")) != str(vars[vn])
		UI.rrect(self, Rect2(vx, vy - 20, w, 28), Color(0.06, 0.07, 0.11), 7.0, UI.hot(UI.WARN, 1.5) if changed else Color(1, 1, 1, 0.12), 1.5)
		UI.text(self, Vector2(vx + 10, vy), s, 14, UI.hot(UI.WARN, 1.2) if changed else UI.INK, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "mono")
		vx += w + 8.0
