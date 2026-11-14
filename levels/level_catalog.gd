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
	preload("res://levels/defs/guard_duty.gd"),
	preload("res://levels/defs/lock_and_key.gd"),
	preload("res://levels/defs/shortcut.gd"),
	preload("res://levels/defs/deep_end.gd"),
	preload("res://levels/defs/springboard.gd"),
	preload("res://levels/defs/moonwalk.gd"),
	preload("res://levels/defs/hunted.gd"),
	preload("res://levels/defs/pad_rally.gd"),
	preload("res://levels/defs/sunken_vault.gd"),
	preload("res://levels/defs/clockwork.gd"),
	preload("res://levels/defs/lunar_garden.gd"),
	preload("res://levels/defs/far_side.gd"),
]

## Levels shown per page of the level select, and what each page is called.
const PAGE_SIZE := 12
const PAGE_TITLES: Array[String] = ["SKY COURSES", "FAR SIDE"]

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


static func page_count() -> int:
	return ceili(float(count()) / PAGE_SIZE)


## The page a level sits on.
static func page_of(index: int) -> int:
	return clampi(index / PAGE_SIZE, 0, page_count() - 1)


static func page_title(page: int) -> String:
	return PAGE_TITLES[page] if page < PAGE_TITLES.size() else "PAGE %d" % (page + 1)
