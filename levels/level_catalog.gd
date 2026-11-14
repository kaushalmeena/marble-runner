class_name LevelCatalog
extends RefCounted
## The ordered list of levels. Order here is the order they unlock in.

const SCRIPTS: Array[GDScript] = [
	preload("res://levels/defs/first_roll.gd"),
	preload("res://levels/defs/mind_the_gap.gd"),
	preload("res://levels/defs/gem_garden.gd"),
	preload("res://levels/defs/high_hopes.gd"),
	preload("res://levels/defs/fast_lane.gd"),
	preload("res://levels/defs/moving_day.gd"),
	preload("res://levels/defs/pinball.gd"),
	preload("res://levels/defs/thin_ice.gd"),
	preload("res://levels/defs/updraft.gd"),
	preload("res://levels/defs/crumble_run.gd"),
	preload("res://levels/defs/gauntlet.gd"),
	preload("res://levels/defs/summit.gd"),
]

static var _levels: Array[LevelDef] = []


static func all() -> Array[LevelDef]:
	if _levels.is_empty():
		for script in SCRIPTS:
			_levels.append(script.new() as LevelDef)
	return _levels


static func count() -> int:
	return SCRIPTS.size()


static func at(index: int) -> LevelDef:
	return all()[clampi(index, 0, count() - 1)]
