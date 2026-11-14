class_name Ui
extends RefCounted
## Shorthand for building interface in code.
##
## Every screen is assembled from scripts, because their contents are driven by
## data (how many levels, which skin, which power-up). Their *look* still comes
## from the project theme: everything here takes a theme type variation and
## sets no fonts or colours of its own.

## How long one thing takes to arrive on screen, and the gap between one item
## of a list and the next.
const ENTER_SECONDS := 0.24
const STAGGER_SECONDS := 0.045


static func label(text: String, variation: StringName = &"",
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = alignment
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if variation != &"":
		node.theme_type_variation = variation
	return node


static func column(separation: int = 4) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


static func row(separation: int = 12) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override(&"separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


static func gap(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


## A spacer that soaks up the spare width of a row.
static func spring() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


## A covering sheet of colour that lets clicks through.
static func shade(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## A push button. [param variation] picks its family: the default slate one,
## [code]PrimaryButton[/code] for the one thing a screen is for, or
## [code]GhostButton[/code] for the way out.
static func button(text: String, min_width: float = 0.0, icon: Icon.Kind = Icon.Kind.NONE,
		variation: StringName = &"") -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.x = min_width
	if variation != &"":
		node.theme_type_variation = variation
	if icon != Icon.Kind.NONE:
		decorate(node, icon)
	return node


## Puts an icon at the left edge of [param node], leaving its label centred.
static func decorate(node: Button, kind: Icon.Kind) -> Icon:
	var dark := node.theme_type_variation == &"PrimaryButton"
	var icon := Icon.new(kind, 22.0, Icon.DARK if dark else Icon.LIGHT)
	node.add_child(icon)
	icon.anchor_top = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = 20.0
	icon.offset_right = 42.0
	# Sits a little high: the bottom of a button is its lip, not its face.
	icon.offset_top = -13.5
	icon.offset_bottom = 8.5
	return icon


## A round button that is nothing but an icon.
static func round_button(kind: Icon.Kind, side: float = 60.0) -> Button:
	var node := Button.new()
	node.theme_type_variation = &"RoundButton"
	node.custom_minimum_size = Vector2(side, side + 5.0)
	var icon := Icon.new(kind, side * 0.4)
	node.add_child(icon)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -side * 0.2
	icon.offset_right = side * 0.2
	icon.offset_top = -side * 0.2 - 2.5
	icon.offset_bottom = side * 0.2 - 2.5
	return node


## One key of the keyboard, as a little cap.
static func keycap(text: String) -> PanelContainer:
	var cap := PanelContainer.new()
	cap.theme_type_variation = &"KeyCap"
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(label(text, &"ChipLabel", HORIZONTAL_ALIGNMENT_CENTER))
	return cap


## Some keys and what they do: [code][Q] [E]  CAMERA[/code].
static func key_hint(keys: PackedStringArray, caption: String) -> HBoxContainer:
	var box := row(5)
	for key in keys:
		box.add_child(keycap(key))
	var text := label("  " + caption, &"ChipLabel")
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(text)
	return box


## A soft horizontal line that fades out at both ends.
static func rule(color := Color(0.42, 0.74, 1.0, 0.85)) -> TextureRect:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([Color(color, 0.0), color, Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 4
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.custom_minimum_size = Vector2(0.0, 4.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Pins [param control] to a corner or edge of its parent, [param margin] in
## from it, growing inward as its content grows.
static func pin(control: Control, preset: Control.LayoutPreset, margin := Vector2.ZERO) -> void:
	control.set_anchors_preset(preset)
	var right := preset in [Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_RIGHT]
	var left := preset in [Control.PRESET_TOP_LEFT, Control.PRESET_BOTTOM_LEFT]
	var bottom := preset in [
		Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT, Control.PRESET_CENTER_BOTTOM]
	var top := preset in [
		Control.PRESET_TOP_LEFT, Control.PRESET_TOP_RIGHT, Control.PRESET_CENTER_TOP]
	control.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else (
		Control.GROW_DIRECTION_END if left else Control.GROW_DIRECTION_BOTH)
	control.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else (
		Control.GROW_DIRECTION_END if top else Control.GROW_DIRECTION_BOTH)
	var x := -margin.x if right else (margin.x if left else 0.0)
	var y := -margin.y if bottom else (margin.y if top else 0.0)
	control.offset_left = x
	control.offset_right = x
	control.offset_top = y
	control.offset_bottom = y


# --- Arriving and leaving -----------------------------------------------------
#
# Only opacity is animated on anything a container lays out: a container owns
# its children's position and scale and takes them back whenever it re-sorts.
# [method rise_in] moves its control, so it is for free-standing ones only.


## Fades [param control] in after [param delay] seconds.
static func fade_in(control: CanvasItem, delay: float = 0.0,
		seconds: float = ENTER_SECONDS) -> Tween:
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_interval(maxf(delay, 0.001))
	tween.tween_property(control, ^"modulate:a", 1.0, seconds)
	return tween


## Fades each of [param items] in, one after the other.
static func cascade(items: Array, delay: float = 0.0, step: float = STAGGER_SECONDS) -> void:
	for index in items.size():
		fade_in(items[index], delay + index * step)


## Fades a free-standing control in while it settles up into place from
## [param distance] below.
static func rise_in(control: Control, distance: float = 26.0,
		seconds: float = ENTER_SECONDS) -> Tween:
	var rest := control.position.y
	control.position.y = rest + distance
	control.modulate.a = 0.0
	var tween := control.create_tween().set_parallel()
	tween.tween_property(control, ^"modulate:a", 1.0, seconds)
	tween.tween_property(control, ^"position:y", rest, seconds) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## The reverse of [method rise_in]: sinks and fades, then returns to rest so
## the next arrival starts from the right place.
static func sink_out(control: Control, distance: float = 18.0, seconds: float = 0.14) -> Tween:
	var rest := control.position.y
	var tween := control.create_tween().set_parallel()
	tween.tween_property(control, ^"modulate:a", 0.0, seconds)
	tween.tween_property(control, ^"position:y", rest + distance, seconds) \
		.set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void: control.position.y = rest)
	return tween
