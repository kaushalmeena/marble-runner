class_name StatPill
extends PanelContainer
## An icon and a number in a pill: the purse of gems, the stars, the secret diamonds.

var text: String = "":
	set(value):
		text = value
		_value.text = value

var _value: Label


func _init(kind: Icon.Kind, tint: Color, value: String = "") -> void:
	theme_type_variation = &"HudPill"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := Ui.row(8)
	var icon := Icon.new(kind, 20.0, tint)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	_value = Ui.label("", &"AccentLabel")
	_value.add_theme_color_override(&"font_color", Color.WHITE)
	box.add_child(_value)
	add_child(box)
	text = value
