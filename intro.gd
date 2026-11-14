extends Control
# Level briefing overlay: how to play, plus where the idea turns up in real software.

const UI = preload("res://ui.gd")
const World = preload("res://real_world.gd")

const CARD := Rect2(60, 44, 1160, 632)
const ART := Rect2(560, 176, 620, 232)

var level
var tm := 0.0
var laid_out := false
var how_rows: Array = []
var use_rows: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20
	var id: String = level.meta["id"]
	var d: Dictionary = World.INFO[id]
	var c: Color = level.tint
	UI.label(self, level.meta["name"], Vector2(100, 62), 36, UI.INK, 0.0, "title")
	UI.label(self, level.meta["tag"] + "     " + level.meta["book"], Vector2(102, 112), 15, c)
	UI.label(self, "HOW TO PLAY", Vector2(100, 160), 13, UI.DIM)
	var y := 190.0
	for i in d["how"].size():
		how_rows.append([UI.label(self, str(i + 1), Vector2(100, y - 2), 22, UI.hot(c, 1.3), 0.0, "title"),
			UI.label(self, d["how"][i], Vector2(130, y), 16, UI.INK, 390.0)])
		y += 90.0
	UI.label(self, "IN THE REAL WORLD", Vector2(560, 160), 13, UI.DIM)
	UI.label(self, d["caption"], Vector2(560, 414), 14, UI.DIM, 620.0)
	var uy := 448.0
	for u in d["uses"]:
		use_rows.append([UI.label(self, u[0], Vector2(560, uy), 15, UI.hot(c, 1.25), 0.0, "title"),
			UI.label(self, u[1], Vector2(560, uy + 21), 14, UI.INK, 620.0)])
		uy += 62.0
	UI.button(self, "Start", Vector2(100, 604), Vector2(170, 50), close, 19, c)
	var traces: Array = d["traces"]
	if not traces.is_empty():
		UI.button(self, "Step through the code", Vector2(282, 604), Vector2(236, 50), _code.bind(traces), 16, c)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


# Wrapped labels only know their height once they are in the tree, so stack them here.
func _layout() -> void:
	laid_out = true
	var y := 190.0
	for row in how_rows:
		row[0].position.y = y - 3.0
		row[1].position.y = y
		y += row[1].size.y + 22.0
	var uy := 446.0
	for row in use_rows:
		row[0].position.y = uy
		row[1].position.y = uy + 21.0
		uy += 21.0 + row[1].size.y + 10.0


func close() -> void:
	level.overlay = null
	queue_free()


func _code(traces: Array) -> void:
	close()
	level.open_code(traces)


func _process(delta: float) -> void:
	if not laid_out:
		_layout()
	tm += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			close()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.025, 0.045, 0.95))
	UI.rrect(self, CARD, Color(0.07, 0.08, 0.13, 0.99), 20.0, UI.hot(level.tint, 1.2), 1.5)
	World.draw(self, level.meta["id"], ART, tm, level.tint)
