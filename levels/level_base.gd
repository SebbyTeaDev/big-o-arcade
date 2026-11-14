extends Control
# Base class for every level: header, time, sound, particles, shake, toast, stars.

const UI = preload("res://ui.gd")
const World = preload("res://real_world.gd")
const Intro = preload("res://intro.gd")
const Stepper = preload("res://code_stepper.gd")

var main
var meta := {}
var t := 0.0
var tint: Color = UI.ACCENT
var _celebrated := 0
var overlay: Control = null     # the briefing or the code viewer, when one is open


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func header(sub: String) -> void:
	tint = meta.get("col", UI.ACCENT)
	UI.button(self, "< Menu", Vector2(24, 18), Vector2(96, 38), func(): main.show_menu(), 15)
	UI.label(self, meta.get("name", ""), Vector2(140, 6), 30, UI.INK, 0.0, "title")
	UI.label(self, sub, Vector2(142, 48), 15, tint)
	var id: String = meta.get("id", "")
	if World.INFO.has(id):
		var traces: Array = World.INFO[id]["traces"]
		if traces.is_empty():
			UI.button(self, "Real world", Vector2(1126, 18), Vector2(116, 38), show_intro, 14, tint)
		else:
			UI.button(self, "Real world", Vector2(1002, 18), Vector2(116, 38), show_intro, 14, tint)
			UI.button(self, "See the code", Vector2(1126, 18), Vector2(116, 38), open_code.bind(traces), 14, tint)
		if main.first_visit(id):
			show_intro.call_deferred()


func show_intro() -> void:
	if overlay != null:
		return
	var o: Control = Intro.new()
	o.level = self
	overlay = o
	add_child(o)


func open_code(ids: Array, reveal: bool = true) -> void:
	if overlay != null or ids.is_empty():
		return
	var s: Control = Stepper.new()
	s.level = self
	s.ids = ids
	s.reveal = reveal
	overlay = s
	add_child(s)


func _process(delta: float) -> void:
	t += delta
	tick(delta)
	queue_redraw()


func tick(_delta: float) -> void:
	pass


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed) or overlay != null:
		return
	if event.keycode == KEY_ESCAPE:
		main.show_menu()
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		var nb = get("next_btn")
		if nb is Button and nb.visible and not nb.disabled:
			nb.pressed.emit()


func sfx(sound: String, pitch: float = 1.0) -> void:
	main.play(sound, pitch)


# Record stars (1-3). Celebrates the first time each star count is reached in this visit.
func finish(stars: int = 3, celebrate: bool = true) -> void:
	stars = clampi(stars, 1, 3)
	main.mark_done(meta["id"], stars)
	if celebrate and stars > _celebrated:
		_celebrated = stars
		_toast(stars)
		main.fanfare()
		burst(Vector2(760, 44), UI.WARN, 40)


func burst(pos: Vector2, c: Color, amount: int = 24) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.9
	p.spread = 180.0
	p.gravity = Vector2(0, 520)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 340.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = UI.hot(c, 2.0)
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = g
	p.emitting = true
	add_child(p)
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)


func shake(amount: float = 9.0) -> void:
	var tw := create_tween()
	for i in 5:
		tw.tween_property(self, "position:x", amount * (1.0 if i % 2 == 0 else -1.0) * (1.0 - i / 5.0), 0.04)
	tw.tween_property(self, "position:x", 0.0, 0.04)


func float_text(pos: Vector2, s: String, c: Color, font_size: int = 20) -> void:
	var l := UI.label(self, s, pos, font_size, UI.hot(c, 1.4), 0.0, "title")
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "position:y", pos.y - 46.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(l.queue_free)


func _toast(stars: int) -> void:
	var c := Control.new()
	c.position = Vector2(600, 10)
	c.size = Vector2(320, 64)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		UI.rrect(c, Rect2(Vector2.ZERO, c.size), Color(0.09, 0.1, 0.16, 0.96), 14.0, UI.hot(UI.WARN, 1.4), 1.5)
		UI.text(c, Vector2(18, 39), "Level complete", 19, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
		for i in 3:
			UI.star(c, Vector2(206 + i * 36, 32), 14.0, UI.hot(UI.WARN, 1.7) if i < stars else Color(1, 1, 1, 0.12)))
	add_child(c)
	c.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(c, "modulate:a", 1.0, 0.25)
	tw.tween_interval(3.2)
	tw.tween_property(c, "modulate:a", 0.0, 0.5)
	tw.tween_callback(c.queue_free)
