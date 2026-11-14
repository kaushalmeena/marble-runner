class_name Ui
extends RefCounted
## Shorthand for building interface in code.
##
## The HUD, the results card and the level select are assembled from scripts,
## because their contents are driven by data (how many levels, which power-up).
## Their *look* still comes from the project theme: everything here takes a
## theme type variation and sets no fonts or colours of its own.


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


static func button(text: String, min_width: float = 0.0) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.x = min_width
	return node


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
