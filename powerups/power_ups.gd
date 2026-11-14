class_name PowerUps
extends RefCounted
## Static description of every power-up.
##
## Keeping this in one place means the pickup, the game and the HUD all agree
## without any of them knowing about each other.
##
## A power-up takes effect the moment it is picked up and runs for a while.
## Different ones run side by side, and picking up another of one that is
## already running adds its time on top, up to [constant MAX_STACK] of them.

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
	Kind.SUPER_JUMP: "Your jumps go far higher for a while.",
	Kind.BOOST: "A shove now, and a higher top speed for a while.",
	Kind.FEATHER: "You fall slowly for a while. Jump and glide.",
	Kind.MAGNET: "Pulls nearby gems to you.",
	Kind.STOPWATCH: "The clock is frozen.",
	Kind.SHIELD: "Rival marbles and red bars cannot hurt you.",
	Kind.DOUBLE_JUMP: "Press SPACE again in mid-air for a second jump.",
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

## Seconds an effect lasts from one pickup.
const DURATIONS: Dictionary = {
	Kind.SUPER_JUMP: 12.0,
	Kind.BOOST: 10.0,
	Kind.FEATHER: 10.0,
	Kind.MAGNET: 15.0,
	Kind.STOPWATCH: 8.0,
	Kind.SHIELD: 12.0,
	Kind.DOUBLE_JUMP: 18.0,
}

## How many pickups' worth of time one effect can hold at once.
const MAX_STACK := 3.0


static func label(kind: Kind) -> String:
	return LABELS.get(kind, "")


static func hint(kind: Kind) -> String:
	return HINTS.get(kind, "")


static func color(kind: Kind) -> Color:
	return COLORS.get(kind, Color.WHITE)


static func duration(kind: Kind) -> float:
	return DURATIONS.get(kind, 0.0)
