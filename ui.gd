extends RefCounted
# Shared palette, fonts and drawing helpers. Everything is laid out on a 1280x720 canvas.
# Colours brighter than 1.0 (see hot()) bloom, because the project renders 2D in HDR with glow.

const BG := Color("0b0d14")
const PANEL := Color("161a28")
const PANEL2 := Color("222741")
const INK := Color("eef0f8")
const DIM := Color("8b93ae")
const ACCENT := Color("4fe0b6")
const WARN := Color("ffc24d")
const BAD := Color("ff6b7a")
const BLUE := Color("5fa8ff")
const PURPLE := Color("b592ff")
const PINK := Color("ff7fd1")
const CLEAR := Color(0, 0, 0, 0)

static var on_click: Callable = Callable()
static var _sb: StyleBoxFlat = null
static var _fonts: Dictionary = {}
static var _re: RegEx = null


static func hot(c: Color, k: float = 1.8) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, c.a)


static func hue(i: float, n: float, s: float = 0.62, v: float = 0.95) -> Color:
	return Color.from_hsv(fposmod(i / maxf(n, 1.0), 1.0) * 0.83, s, v)


static func font(kind: String = "body") -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var f := SystemFont.new()
	match kind:
		"title":
			f.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Segoe UI", "Arial"])
			f.font_weight = 700
		"mono":
			f.font_names = PackedStringArray(["SF Mono", "Menlo", "Consolas", "Courier New", "monospace"])
		_:
			f.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Segoe UI", "Arial"])
			f.font_weight = 500
	_fonts[kind] = f
	return f


static func label(parent: Node, text: String, pos: Vector2, font_size: int = 18, color: Color = INK, width: float = 0.0, kind: String = "") -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if kind != "":
		l.add_theme_font_override("font", font(kind))
	# Wrapping has to be switched on before the text goes in, or a long first text
	# stretches the label to its unwrapped width and it never shrinks back.
	if width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(width, 0)
		l.size = Vector2(width, 0)
	l.text = text
	parent.add_child(l)
	if width > 0.0:
		l.size = Vector2(width, 0)
	return l


static func _box(c: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	sb.set_border_width_all(1)
	sb.border_color = border
	return sb


static func button(parent: Node, text: String, pos: Vector2, btn_size: Vector2, cb: Callable, font_size: int = 16, accent: Color = BLUE) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = btn_size
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_stylebox_override("normal", _box(PANEL2, Color(1, 1, 1, 0.10)))
	b.add_theme_stylebox_override("hover", _box(PANEL2.lightened(0.10), accent))
	b.add_theme_stylebox_override("pressed", _box(accent.darkened(0.5), accent))
	b.add_theme_stylebox_override("disabled", _box(PANEL, Color(1, 1, 1, 0.05)))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", DIM)
	b.pressed.connect(cb)
	if on_click.is_valid():
		b.pressed.connect(on_click)
	parent.add_child(b)
	return b


static func select(b: Button, on: bool, c: Color = ACCENT) -> void:
	b.modulate = c.lightened(0.35) if on else Color.WHITE


static func panel(parent: Node, rect: Rect2, c: Color = PANEL, radius: int = 12) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.07)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


static func code(parent: Node, rect: Rect2, font_size: int = 18) -> RichTextLabel:
	panel(parent, rect, Color("0f111b"))
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.position = rect.position + Vector2(22, 16)
	r.size = rect.size - Vector2(44, 32)
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", font("mono"))
	r.add_theme_font_size_override("normal_font_size", font_size)
	r.add_theme_color_override("default_color", INK)
	parent.add_child(r)
	return r


# Tiny JavaScript-ish syntax highlighter that returns BBCode.
static func highlight(src: String) -> String:
	if _re == null:
		_re = RegEx.new()
		_re.compile("(//[^\\n]*)|\\b(for|const|let|while|if|else|return|function|of|new)\\b|\\b(\\d+)\\b|([A-Za-z_]\\w*)(?=\\()")
	var out := ""
	var last := 0
	for m in _re.search_all(src):
		out += src.substr(last, m.get_start() - last).replace("[", "[lb]")
		var c := "5fa8ff"
		if m.get_string(1) != "":
			c = "8b93ae"
		elif m.get_string(2) != "":
			c = "b592ff"
		elif m.get_string(3) != "":
			c = "ffc24d"
		out += "[color=#%s]%s[/color]" % [c, m.get_string().replace("[", "[lb]")]
		last = m.get_end()
	out += src.substr(last).replace("[", "[lb]")
	return out


# --- immediate-mode drawing helpers (call from _draw) ---

static func rrect(ci: CanvasItem, r: Rect2, c: Color, rad: float = 8.0, border: Color = CLEAR, bw: float = 0.0) -> void:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	if _sb == null:
		_sb = StyleBoxFlat.new()
	_sb.bg_color = c
	_sb.set_corner_radius_all(int(rad))
	_sb.set_border_width_all(int(ceil(bw)))
	_sb.border_color = border
	ci.draw_style_box(_sb, r)


static func text(ci: CanvasItem, pos: Vector2, s: String, font_size: int = 16, c: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0, kind: String = "body") -> void:
	ci.draw_string(font(kind), pos, s, align, width, font_size, c)


static func ctext(ci: CanvasItem, center: Vector2, s: String, font_size: int = 16, c: Color = INK, kind: String = "body") -> void:
	ci.draw_string(font(kind), Vector2(center.x - 200.0, center.y + font_size * 0.36), s, HORIZONTAL_ALIGNMENT_CENTER, 400.0, font_size, c)


static func star(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, color)


static func arrow(ci: CanvasItem, a: Vector2, b: Vector2, c: Color, w: float = 2.0, head: float = 8.0) -> void:
	if a.distance_to(b) < 1.0:
		return
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	ci.draw_line(a, b - d * head * 0.6, c, w, true)
	ci.draw_colored_polygon(PackedVector2Array([b, b - d * head + n * head * 0.55, b - d * head - n * head * 0.55]), c)


static func fmt(x: float) -> String:
	var s := str(int(round(x)))
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "," + out
	return out
