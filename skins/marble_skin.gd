class_name MarbleSkin
extends Resource
## One buyable look for the marble.
##
## A skin is pure presentation: it changes the material and nothing else, so no
## skin can ever be a gameplay advantage. Adding one is a material, a resource
## and an entry in the library.

## Stable identifier. This is what gets written to the save file, so renaming an
## existing one orphans whatever the player already bought.
@export var id: StringName = &"classic"

@export var display_name: String = "Classic"

## Cost in coins. Zero means it is available from the start.
@export var price: int = 0

@export var material: StandardMaterial3D

## Swatch colour for the shop card, and the tint of the pickup burst while this
## skin is equipped.
@export var accent_color: Color = Color(0.35, 0.7, 1.0)

## One line of flavour for the shop card.
@export var description: String = ""


func is_free() -> bool:
	return price <= 0
