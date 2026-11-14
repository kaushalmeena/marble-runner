class_name PowerUps
extends RefCounted
## Static description of every power-up.
##
## Keeping this in one place means the pickup, the game and the HUD all agree
## without any of them knowing about each other.
##
## Most power-ups are *held*: picking one up puts it in the slot, and the player
## chooses the moment to spend it. The stopwatch is the exception and fires on
## pickup, because there is never a reason to save it.

enum Kind {
	SUPER_JUMP,
	BOOST,
	FEATHER,
	MAGNET,
	STOPWATCH,
	SHIELD,
	DOUBLE_JUMP,
}

const LABELS: Dictionary = {
	Kind.SUPER_JUMP: "SUPER JUMP",
	Kind.BOOST: "BOOST",
	Kind.FEATHER: "FEATHER",
	Kind.MAGNET: "MAGNET",
	Kind.STOPWATCH: "STOPWATCH",
	Kind.SHIELD: "SHIELD",
	Kind.DOUBLE_JUMP: "DOUBLE JUMP",
}

## One line for the tip that shows the first time a kind is collected.
const HINTS: Dictionary = {
	Kind.SUPER_JUMP: "Launches you far higher than a jump.",
	Kind.BOOST: "A burst of speed the way you are facing.",
	Kind.FEATHER: "Falls slowly for a few seconds. Jump first.",
	Kind.MAGNET: "Pulls nearby gems to you.",
	Kind.STOPWATCH: "Froze the clock.",
	Kind.SHIELD: "Guards and red bars cannot hurt you for a while.",
	Kind.DOUBLE_JUMP: "Jump again in mid-air, for a while.",
}

const COLORS: Dictionary = {
	Kind.SUPER_JUMP: Color(1.0, 0.85, 0.25),
	Kind.BOOST: Color(0.3, 1.0, 0.6),
	Kind.FEATHER: Color(0.75, 0.9, 1.0),
	Kind.MAGNET: Color(1.0, 0.5, 0.25),
	Kind.STOPWATCH: Color(0.72, 0.5, 1.0),
	Kind.SHIELD: Color(0.35, 0.65, 1.0),
	Kind.DOUBLE_JUMP: Color(1.0, 0.45, 0.75),
}

## Seconds an effect lasts once triggered. Zero is a one-off impulse.
const DURATIONS: Dictionary = {
	Kind.SUPER_JUMP: 0.0,
	Kind.BOOST: 0.0,
	Kind.FEATHER: 6.0,
	Kind.MAGNET: 10.0,
	Kind.STOPWATCH: 5.0,
	Kind.SHIELD: 8.0,
	Kind.DOUBLE_JUMP: 12.0,
}


static func label(kind: Kind) -> String:
	return LABELS.get(kind, "")


static func hint(kind: Kind) -> String:
	return HINTS.get(kind, "")


static func color(kind: Kind) -> Color:
	return COLORS.get(kind, Color.WHITE)


static func duration(kind: Kind) -> float:
	return DURATIONS.get(kind, 0.0)


## True for power-ups that fire the moment they are touched.
static func is_instant(kind: Kind) -> bool:
	return kind == Kind.STOPWATCH
