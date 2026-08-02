class_name MarblePreview
extends SubViewportContainer
## A live, slowly turning marble rendered into the UI.
##
## A flat colour swatch cannot show what a skin actually looks like: these are
## marbled, veined materials whose whole character is in the surface. So the
## shop renders the real mesh with the real material, in its own tiny 3D world.

## Degrees per second of idle spin.
@export var spin_speed: float = 28.0

@onready var _marble: MeshInstance3D = %PreviewMarble


func _process(delta: float) -> void:
	_marble.rotate_y(deg_to_rad(spin_speed) * delta)


## Shows [param skin] on the preview marble.
func show_skin(skin: MarbleSkin) -> void:
	if skin == null or skin.material == null:
		return
	_marble.material_override = skin.material
	# Reset the spin so every skin is first seen from the same angle.
	_marble.rotation = Vector3.ZERO
