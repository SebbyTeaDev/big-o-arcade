extends Control

const UI = preload("res://ui.gd")
const Icons = preload("res://icons.gd")

var meta := {}
var stars := 0
var show_stars := true
var number := ""
var cb: Callable
var hover := 0.0
var over := false
var tm := 0.0


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pivot_offset = size / 2.0
	mouse_entered.connect(func(): over = true)
	mouse_exited.connect(func(): over = false)
	tm = randf() * 10.0


func _process(delta: float) -> void:
	tm += delta
	hover = move_toward(hover, 1.0 if over else 0.0, delta * 7.0)
	scale = Vector2.ONE * (1.0 + 0.025 * hover)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cb.call()


func _draw() -> void:
	var c: Color = meta["col"]
	var r := Rect2(Vector2.ZERO, size)
	UI.rrect(self, r, UI.PANEL.lerp(c, 0.05 + 0.09 * hover), 14.0, UI.hot(Color(c.r, c.g, c.b, 0.22 + 0.78 * hover), 1.0 + 0.8 * hover), 1.5)
	Icons.draw(self, meta["icon"], Vector2(48, 48), tm, UI.hot(c, 1.0 + 0.9 * hover))
	UI.text(self, Vector2(92, 40), meta["name"], 21, UI.INK, HORIZONTAL_ALIGNMENT_LEFT, -1.0, "title")
	UI.text(self, Vector2(92, 62), meta["tag"], 14, c)
	if size.y < 130.0:
		UI.text(self, Vector2(92, 88), meta["desc"], 13, UI.DIM)
	else:
		draw_multiline_string(UI.font(), Vector2(20, 98), meta["desc"], HORIZONTAL_ALIGNMENT_LEFT, size.x - 40.0, 13, 2, UI.DIM)
		UI.text(self, Vector2(20, size.y - 14.0), number + meta["book"], 12, Color(c.r, c.g, c.b, 0.75))
	if show_stars:
		for i in 3:
			var on := i < stars
			UI.star(self, Vector2(size.x - 66.0 + i * 22.0, size.y - 19.0), 8.0, UI.hot(UI.WARN, 1.5) if on else Color(1, 1, 1, 0.10))
