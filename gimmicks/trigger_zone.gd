class_name TriggerZone
extends Area3D
## An invisible region that reports the marble entering it.
##
## Used for two things that are otherwise unrelated: tips, which carry a line
## of text for the HUD, and hazards, which send the marble back to a checkpoint.

signal entered(zone: TriggerZone)

## Shown on the HUD when the marble arrives. Empty for hazards.
var text: String = ""
## Tips only fire once per attempt.
var one_shot: bool = true

var _spent: bool = false


func _init(shape: Shape3D = null, tip: String = "") -> void:
	text = tip
	collision_layer = 0
	collision_mask = 2
	if shape != null:
		add_child(Mats.collider(shape))
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is Marble or (one_shot and _spent):
		return
	_spent = true
	entered.emit(self)
