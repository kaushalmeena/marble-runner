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
	preload("res://levels/defs/belt_line.gd"),
	preload("res://levels/defs/lights_out.gd"),
	preload("res://levels/defs/red_light.gd"),
	preload("res://levels/defs/push_button.gd"),
	preload("res://levels/defs/tar_pit.gd"),
	preload("res://levels/defs/cannonball.gd"),
	preload("res://levels/defs/sentry_row.gd"),
	preload("res://levels/defs/booby_traps.gd"),
	preload("res://levels/defs/night_watch.gd"),
	preload("res://levels/defs/assembly_line.gd"),
	preload("res://levels/defs/switchyard.gd"),
	preload("res://levels/defs/graveyard_shift.gd"),
	preload("res://levels/defs/crosswind.gd"),
	preload("res://levels/defs/headwind.gd"),
	preload("res://levels/defs/heavy_metal.gd"),
	preload("res://levels/defs/gale_force.gd"),
	preload("res://levels/defs/mire.gd"),
	preload("res://levels/defs/blackout.gd"),
	preload("res://levels/defs/barrage.gd"),
	preload("res://levels/defs/lead_boots.gd"),
	preload("res://levels/defs/stormglass.gd"),
	preload("res://levels/defs/flooded_works.gd"),
	preload("res://levels/defs/eye_of_storm.gd"),
	preload("res://levels/defs/storm_peak.gd"),
	preload("res://levels/defs/long_way_round.gd"),
	preload("res://levels/defs/switchback.gd"),
	preload("res://levels/defs/parasol.gd"),
	preload("res://levels/defs/clockwork_yard.gd"),
	preload("res://levels/defs/thin_line.gd"),
	preload("res://levels/defs/night_flight.gd"),
	preload("res://levels/defs/rogues_gallery.gd"),
	preload("res://levels/defs/heavy_going.gd"),
	preload("res://levels/defs/windward.gd"),
	preload("res://levels/defs/moonshot.gd"),
	preload("res://levels/defs/medley.gd"),
	preload("res://levels/defs/grand_tour.gd"),
]

## Levels shown per page of the level select, and what each page is called.
const PAGE_SIZE := 12
const PAGE_TITLES: Array[String] = [
	"SKY COURSES", "FAR SIDE", "NIGHT SHIFT", "STORM PEAK", "GRAND TOUR"]

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
