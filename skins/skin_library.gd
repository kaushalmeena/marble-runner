class_name SkinLibrary
extends Resource
## The catalogue of marble skins.
##
## Held as a resource rather than a hard-coded list so the shop, the marble and
## the save system all read the same ordered set, and a new skin needs no code.

const PATH := "res://resources/skins/skin_library.tres"

@export var skins: Array[MarbleSkin] = []


## Loads the shared catalogue.
static func load_default() -> SkinLibrary:
	var library := load(PATH) as SkinLibrary
	if library == null:
		push_error("SkinLibrary: could not load %s" % PATH)
	return library


## Returns the skin with [param id], or the first free skin as a fallback so a
## save file naming a skin that no longer exists still produces a marble.
func get_skin(id: StringName) -> MarbleSkin:
	for skin in skins:
		if skin != null and skin.id == id:
			return skin
	return get_default()


func get_default() -> MarbleSkin:
	for skin in skins:
		if skin != null and skin.is_free():
			return skin
	return skins[0] if not skins.is_empty() else null


func has(id: StringName) -> bool:
	for skin in skins:
		if skin != null and skin.id == id:
			return true
	return false
