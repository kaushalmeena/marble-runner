class_name PowerUps
extends RefCounted
## Static description of every power-up: how long it lasts and how it presents.
##
## Keeping this in one place means the pickup scene, the manager and the HUD all
## agree without any of them having to know about each other.

enum Kind {
	SHIELD,
	MAGNET,
	SLOW_MO,
}

## Seconds each power-up stays active. The shield can also end early, when it
## absorbs a hit.
const DURATIONS: Dictionary = {
	Kind.SHIELD: 10.0,
	Kind.MAGNET: 8.0,
	Kind.SLOW_MO: 5.0,
}

## Short names for the HUD chips. Kept to a few characters so the chips stay
## narrow enough to sit in a corner.
const LABELS: Dictionary = {
	Kind.SHIELD: "SHIELD",
	Kind.MAGNET: "MAGNET",
	Kind.SLOW_MO: "SLOW",
}

## Accent colour per power-up, shared by the pickup material and the HUD chip so
## the two are recognisably the same thing.
const COLORS: Dictionary = {
	Kind.SHIELD: Color(0.35, 0.75, 1.0),
	Kind.MAGNET: Color(1.0, 0.55, 0.2),
	Kind.SLOW_MO: Color(0.68, 0.45, 1.0),
}


static func duration(kind: Kind) -> float:
	return DURATIONS.get(kind, 0.0)


static func label(kind: Kind) -> String:
	return LABELS.get(kind, "")


static func color(kind: Kind) -> Color:
	return COLORS.get(kind, Color.WHITE)
