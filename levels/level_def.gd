class_name LevelDef
extends RefCounted
## One level: its name, its targets, and the calls that lay it out.
##
## A level is a script rather than a scene because it is easier to read, diff
## and tweak as twenty lines of "floor here, gem there" than as a scene file of
## two hundred transforms. Subclasses fill in the fields in [code]_init[/code]
## and place everything in [method build].

## Stable identifier. This is what the save file keys best times on, so
## renaming one orphans the player's record for that level.
var id: StringName = &""
var title: String = ""
## One line shown under the title on the level card and at the start.
var hint: String = ""
var biome: Biome = preload("res://resources/biomes/meadow.tres")
## Finishing at or under these earns the third and second star.
var gold_time: float = 30.0
var silver_time: float = 60.0
## Multiplier on gravity for the whole level. Below 1 is the moon.
var gravity_scale: float = 1.0


func build(_b: LevelBuilder) -> void:
	pass


## Stars earned by finishing in [param time] seconds: one for finishing at all.
func stars_for(time: float) -> int:
	if time <= gold_time:
		return 3
	if time <= silver_time:
		return 2
	return 1


## Formats seconds as [code]m:ss.cc[/code] for every clock in the game.
static func format_time(seconds: float) -> String:
	if seconds < 0.0:
		return "-:--.--"
	var whole := int(seconds)
	return "%d:%02d.%02d" % [whole / 60, whole % 60, int((seconds - whole) * 100.0)]
