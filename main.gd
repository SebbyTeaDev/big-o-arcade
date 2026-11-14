extends Control

const UI = preload("res://ui.gd")
const MenuCard = preload("res://menu_card.gd")
const SAVE_PATH := "user://big_o_arcade.json"

const LEVELS := [
	{"id": "search", "name": "Card Hunt", "tag": "O(n) vs O(log n)", "icon": "search", "col": UI.BLUE, "book": "Ch. 6  Binary search",
		"desc": "Find a number in shuffled cards, then in sorted ones. Feel the halving."},
	{"id": "bigo", "name": "Count the Loops", "tag": "Estimating Big-O", "icon": "bigo", "col": UI.ACCENT, "book": "Ch. 6  Big-Oh rules",
		"desc": "Read a snippet, call its growth rate, watch the steps pile up."},
	{"id": "listarr", "name": "Shift or Relink", "tag": "Arrays vs linked lists", "icon": "list", "col": UI.WARN, "book": "Ch. 1, 17  Vectors, lists",
		"desc": "Same operation, two memory layouts. Predict which one is cheaper."},
	{"id": "stackq", "name": "Stack Machine", "tag": "LIFO and FIFO", "icon": "stack", "col": UI.PINK, "book": "Ch. 12, 16  Stacks, queues",
		"desc": "Run a bracket checker by hand, then tell stack jobs from queue jobs."},
	{"id": "sortlab", "name": "Sort Lab", "tag": "O(n²) vs O(n log n)", "icon": "sort", "col": UI.PURPLE, "book": "Ch. 9  Sorting",
		"desc": "Six sorts, same data, same speed per step. See who falls apart."},
	{"id": "recursion", "name": "Call Tree", "tag": "Recursion, memoization", "icon": "rec", "col": UI.BAD, "book": "Ch. 8  Recursion, DP",
		"desc": "Watch fib explode into repeated work, then cache it away."},
	{"id": "tree", "name": "Tree Shape", "tag": "Why balance matters", "icon": "tree", "col": UI.ACCENT, "book": "Ch. 19  Search trees",
		"desc": "Sorted input turns a search tree into a linked list. Rotations fix it."},
	{"id": "hash", "name": "Hash Buckets", "tag": "How O(1) lookup works", "icon": "hash", "col": UI.BLUE, "book": "Ch. 20  Hash tables",
		"desc": "Collisions, clustering, load factor and rehashing, one key at a time."},
	{"id": "heap", "name": "Heap Climb", "tag": "Priority queues", "icon": "heap", "col": UI.WARN, "book": "Ch. 21  Binary heap",
		"desc": "Percolate values up and down a binary heap by hand."},
	{"id": "race", "name": "Pick Your Structure", "tag": "Choosing by workload", "icon": "race", "col": UI.PURPLE, "book": "Ch. 7  The structures",
		"desc": "A workload arrives. Bet on a structure, then watch all six race."},
	{"id": "graph", "name": "Pathfinder", "tag": "BFS, DFS, Dijkstra", "icon": "graph", "col": UI.PINK, "book": "Ch. 15  Graphs and paths",
		"desc": "Paint walls and mud, then watch three searches spread across the map."},
	{"id": "maze", "name": "Maze Forge", "tag": "Union-find", "icon": "maze", "col": UI.BAD, "book": "Ch. 24  Disjoint sets",
		"desc": "Knock down walls between separate sets until only one set is left."},
]
const BOSS := {"id": "boss", "name": "Challenge the AI", "tag": "Boss round: code review", "icon": "boss", "col": UI.ACCENT, "book": "Everything above",
	"desc": "An assistant hands you code and a confident complexity claim. Approve it, or push back and say why."}
const SHEET := {"id": "sheet", "name": "Cheat Sheet", "tag": "Every cost on one page", "icon": "sheet", "col": UI.DIM, "book": "Reference",
	"desc": "Structures, sorts and the rules of thumb."}

const BG_SHADER := """
shader_type canvas_item;
uniform vec3 tint : source_color = vec3(0.31, 0.88, 0.71);
uniform bool srgb_out = false;
void fragment() {
	vec2 uv = UV;
	vec2 asp = vec2(1.78, 1.0);
	vec3 c = mix(vec3(0.006, 0.007, 0.014), vec3(0.012, 0.014, 0.03), uv.y);
	float t = TIME * 0.07;
	vec2 a = vec2(0.22 + 0.2 * sin(t * 1.3), 0.18 + 0.15 * cos(t));
	vec2 b = vec2(0.82 + 0.15 * cos(t * 0.9), 0.8 + 0.2 * sin(t * 1.1));
	c += tint * 0.045 * smoothstep(0.75, 0.0, distance(uv * asp, a * asp));
	c += vec3(0.2, 0.12, 0.6) * 0.05 * smoothstep(0.8, 0.0, distance(uv * asp, b * asp));
	vec2 g = fract(uv * vec2(1280.0, 720.0) / 32.0) - 0.5;
	c += vec3(0.4, 0.5, 0.9) * smoothstep(0.07, 0.0, length(g)) * 0.03;
	c *= 1.0 - 0.5 * pow(length(uv - 0.5) * 1.25, 2.0);
	if (srgb_out) {
		c = pow(c, vec3(1.0 / 2.2));
	}
	COLOR = vec4(c, 1.0);
}
"""

var save := {"stars": {}, "mute": false}
var current: Control = null
var bg_mat: ShaderMaterial
var players: Array = []
var sounds := {}
var _pi := 0
var _testing := false
var _tint_now: Color = UI.ACCENT


func _ready() -> void:
	_load()
	var th := Theme.new()
	th.default_font = UI.font()
	theme = th

	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = BG_SHADER
	bg_mat = ShaderMaterial.new()
	bg_mat.shader = sh
	# Forward+ renders 2D in linear light; the OpenGL renderer expects display-ready colour.
	bg_mat.set_shader_parameter("srgb_out", _compat())
	bg.material = bg_mat
	add_child(bg)

	sounds["click"] = _tone(720.0, 0.05, 0)
	sounds["tick"] = _tone(520.0, 0.045, 0)
	sounds["pop"] = _tone(340.0, 0.09, 0)
	sounds["ok"] = _tone(880.0, 0.22, 1)
	sounds["bad"] = _tone(150.0, 0.24, 2)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	UI.on_click = func(): play("click")

	show_menu()
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	if "--monkey" in OS.get_cmdline_user_args():
		_monkey()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			_shots(a.trim_prefix("--shots="), only)


func _compat() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


# --- sound: short synthesised blips, no asset files ---

func _tone(freq: float, dur: float, kind: int) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var x := float(i) / rate
		var envl := exp(-x * 5.0 / dur) * minf(1.0, x * 400.0)
		var s := sin(TAU * freq * x)
		if kind == 1:
			s = 0.6 * s + 0.4 * sin(TAU * freq * 1.5 * x)
		elif kind == 2:
			s = signf(s) * 0.5 + 0.5 * sin(TAU * freq * 0.5 * x)
		data.encode_s16(i * 2, int(clampf(s * envl, -1.0, 1.0) * 11000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


func play(sound: String, pitch: float = 1.0, db: float = -12.0) -> void:
	if save["mute"] or not sounds.has(sound):
		return
	var p: AudioStreamPlayer = players[_pi]
	_pi = (_pi + 1) % players.size()
	p.stream = sounds[sound]
	p.pitch_scale = clampf(pitch, 0.2, 4.0)
	p.volume_db = db
	p.play()


func fanfare() -> void:
	var notes := [1.0, 1.26, 1.5, 2.0]
	for i in notes.size():
		get_tree().create_timer(i * 0.09).timeout.connect(play.bind("ok", notes[i], -10.0))


# --- save file ---

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		if parsed.get("stars") is Dictionary:
			save["stars"] = parsed["stars"]
		save["mute"] = bool(parsed.get("mute", false))


func _store() -> void:
	if _testing:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(save))


func stars_for(id: String) -> int:
	return int(save["stars"].get(id, 0))


func mark_done(id: String, stars: int) -> void:
	if stars > stars_for(id):
		save["stars"][id] = stars
		_store()


# --- screens ---

func _swap(n: Control) -> void:
	if current != null:
		current.queue_free()
	current = n
	add_child(n)
	n.modulate.a = 0.0
	n.position.y = 16.0
	var tw := create_tween().set_parallel()
	tw.tween_property(n, "modulate:a", 1.0, 0.28)
	tw.tween_property(n, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _tint(c: Color) -> void:
	var from: Color = _tint_now
	_tint_now = c
	create_tween().tween_method(func(v: Color): bg_mat.set_shader_parameter("tint", v), from, c, 0.8)


func _card(parent: Control, meta: Dictionary, rect: Rect2, number: String, with_stars: bool) -> void:
	var c: Control = MenuCard.new()
	c.meta = meta
	c.position = rect.position
	c.size = rect.size
	c.number = number
	c.show_stars = with_stars
	c.stars = stars_for(meta["id"])
	c.cb = start.bind(meta)
	parent.add_child(c)


func show_menu() -> void:
	_tint(UI.ACCENT)
	var m := Control.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.label(m, "BIG-O ARCADE", Vector2(46, 14), 46, UI.hot(UI.INK, 1.35), 0.0, "title")
	UI.label(m, "One skill underneath all of it: how does the work grow when the data grows?", Vector2(50, 76), 17, UI.DIM)
	var total := 0
	for lv in LEVELS:
		total += stars_for(lv["id"])
	total += stars_for("boss")
	var sl := UI.label(m, "%d / %d stars" % [total, (LEVELS.size() + 1) * 3], Vector2(880, 34), 20, UI.hot(UI.WARN, 1.3), 0.0, "title")
	sl.size = Vector2(200, 30)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI.button(m, "Sound: off" if save["mute"] else "Sound: on", Vector2(1100, 28), Vector2(132, 38), _toggle_mute, 15)
	for i in LEVELS.size():
		var r := Rect2(46 + (i % 4) * 300, 118 + (i / 4) * 156, 288, 144)
		_card(m, LEVELS[i], r, "%02d   " % (i + 1), true)
	_card(m, BOSS, Rect2(46, 590, 788, 112), "", true)
	_card(m, SHEET, Rect2(846, 590, 388, 112), "", false)
	_swap(m)


func _toggle_mute() -> void:
	save["mute"] = not save["mute"]
	_store()
	show_menu()


func start(meta: Dictionary) -> void:
	play("pop", 1.4)
	var lvl: Control = load("res://levels/%s.gd" % meta["id"]).new()
	lvl.main = self
	lvl.meta = meta
	_tint(meta["col"])
	_swap(lvl)


# --- test harness: godot --path . -- --shots=/some/dir [--only=id] ---

func click(p: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = p
		e.global_position = p
		get_viewport().push_input(e, true)
	await get_tree().process_frame


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _shots(dir: String, only: String) -> void:
	_testing = true
	save = {"stars": {"search": 3, "bigo": 2, "tree": 1}, "mute": true}
	show_menu()
	await wait(0.8)
	if only == "":
		await _snap(dir + "/00_menu.png")
	var all: Array = LEVELS + [BOSS, SHEET]
	for i in all.size():
		var meta: Dictionary = all[i]
		if only != "" and meta["id"] != only:
			continue
		if not ResourceLoader.exists("res://levels/%s.gd" % meta["id"]):
			continue
		start(meta)
		await wait(0.5)
		if current.has_method("demo"):
			await current.demo()
		await wait(1.2)
		await _snap(dir + "/%02d_%s.png" % [i + 1, meta["id"]])
	get_tree().quit()


func _snap(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if _compat():
		img.convert(Image.FORMAT_RGBA8)
	elif img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBAF)
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				img.set_pixel(x, y, Color(minf(c.r, 1.0), minf(c.g, 1.0), minf(c.b, 1.0), 1.0).linear_to_srgb())
		img.convert(Image.FORMAT_RGBA8)
	img.save_png(path)


# Random-input smoke test: godot --path . -- --monkey
func _monkey() -> void:
	_testing = true
	save = {"stars": {}, "mute": true}
	Engine.time_scale = 6.0
	var all: Array = LEVELS + [BOSS, SHEET]
	for meta in all:
		print("MONKEY ", meta["id"])
		start(meta)
		await wait(0.4)
		for i in 900:
			var btns: Array = []
			for c in current.get_children():
				if c is Button and c.visible and not c.disabled and c.text != "< Menu":
					btns.append(c)
			if randf() < 0.7 and not btns.is_empty():
				var b: Button = btns[randi() % btns.size()]
				await click(b.position + b.size / 2.0)
			else:
				await click(Vector2(randf_range(40, 1240), randf_range(150, 700)))
			if i % 10 == 0:
				await wait(0.3)
	print("MONKEY DONE stars=", save["stars"])
	get_tree().quit()
