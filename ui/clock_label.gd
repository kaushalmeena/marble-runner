class_name ClockLabel
extends HBoxContainer
## A time readout whose width never changes while it ticks.
##
## The project font is proportional: a 1 is narrower than an 8, so a clock set
## as one label twitches sideways every hundredth of a second. Here each
## character sits in its own cell, and every digit cell is as wide as the
## widest digit.

var text: String = "":
	set(value):
		if text == value:
			return
		text = value
		_refresh()

var _variation: StringName
var _cells: Array[Label] = []
var _digit_width: float = 0.0


func _init(variation: StringName = &"ScoreLabel") -> void:
	_variation = variation
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", 0)


func _ready() -> void:
	var probe := Label.new()
	probe.theme_type_variation = _variation
	add_child(probe)
	var font := probe.get_theme_font(&"font")
	var font_size := probe.get_theme_font_size(&"font_size")
	for digit in "0123456789":
		_digit_width = maxf(_digit_width, font.get_string_size(
			digit, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	probe.queue_free()
	remove_child(probe)
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	while _cells.size() < text.length():
		var cell := Ui.label("", _variation, HORIZONTAL_ALIGNMENT_CENTER)
		add_child(cell)
		_cells.append(cell)
	for index in _cells.size():
		var cell := _cells[index]
		cell.visible = index < text.length()
		if not cell.visible:
			continue
		var character := text[index]
		cell.text = character
		# Punctuation keeps its natural width; only digits are padded.
		cell.custom_minimum_size.x = _digit_width if character.is_valid_int() else 0.0
