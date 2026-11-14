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
##
## The last few kinds are *ailments*: the same machinery, but they come from
## traps, work against the player, and a shield turns them away.

enum Kind {
	SUPER_JUMP,
	BOOST,
	UMBRELLA,
	MAGNET,
	STOPWATCH,
	SHIELD,
	DOUBLE_JUMP,
	GRIP,
	FLARE,
	SLOW,
	DIZZY,
	HEAVY,
}

const AILMENTS: Array[Kind] = [Kind.SLOW, Kind.DIZZY, Kind.HEAVY]

const LABELS: Dictionary = {
	Kind.SUPER_JUMP: "SUPER JUMP",
	Kind.BOOST: "BOOST",
	Kind.UMBRELLA: "UMBRELLA",
	Kind.MAGNET: "MAGNET",
	Kind.STOPWATCH: "STOPWATCH",
	Kind.SHIELD: "SHIELD",
	Kind.DOUBLE_JUMP: "DOUBLE JUMP",
	Kind.GRIP: "GRIP",
	Kind.FLARE: "FLARE",
	Kind.SLOW: "SLOWED",
	Kind.DIZZY: "DIZZY",
	Kind.HEAVY: "HEAVY",
}

## One line for the tip that shows the first time a kind is collected.
const HINTS: Dictionary = {
	Kind.SUPER_JUMP: "Your jumps go far higher for a while.",
	Kind.BOOST: "A shove now, and a higher top speed for a while.",
	Kind.UMBRELLA: "You fall slowly for a while. Leap off something high and glide.",
	Kind.MAGNET: "Pulls nearby gems to you.",
	Kind.STOPWATCH: "The clock is frozen.",
	Kind.SHIELD: "Rival marbles and red bars cannot hurt you.",
	Kind.DOUBLE_JUMP: "Press SPACE again in mid-air for a second jump.",
	Kind.GRIP: "Ice, tar and wind cannot move you.",
	Kind.FLARE: "Lights up the dark for a while.",
	Kind.SLOW: "A trap. You crawl until it wears off.",
	Kind.DIZZY: "A trap. Your steering is back to front.",
	Kind.HEAVY: "A trap. You weigh a ton and barely jump.",
}

const COLORS: Dictionary = {
	Kind.SUPER_JUMP: Color(1.0, 0.85, 0.25),
	Kind.BOOST: Color(0.3, 1.0, 0.6),
	Kind.UMBRELLA: Color(0.75, 0.9, 1.0),
	Kind.MAGNET: Color(1.0, 0.5, 0.25),
	Kind.STOPWATCH: Color(0.72, 0.5, 1.0),
	Kind.SHIELD: Color(0.35, 0.65, 1.0),
	Kind.DOUBLE_JUMP: Color(1.0, 0.45, 0.75),
	Kind.GRIP: Color(0.2, 0.92, 0.88),
	Kind.FLARE: Color(1.0, 0.95, 0.62),
	Kind.SLOW: Color(1.0, 0.3, 0.3),
	Kind.DIZZY: Color(0.95, 0.3, 0.8),
	Kind.HEAVY: Color(0.92, 0.42, 0.2),
}

## Seconds an effect lasts from one pickup.
const DURATIONS: Dictionary = {
	Kind.SUPER_JUMP: 12.0,
	Kind.BOOST: 10.0,
	Kind.UMBRELLA: 10.0,
	Kind.MAGNET: 15.0,
	Kind.STOPWATCH: 8.0,
	Kind.SHIELD: 12.0,
	Kind.DOUBLE_JUMP: 18.0,
	Kind.GRIP: 14.0,
	Kind.FLARE: 14.0,
	Kind.SLOW: 6.0,
	Kind.DIZZY: 6.0,
	Kind.HEAVY: 7.0,
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


## True for the kinds that work against the player.
static func is_ailment(kind: Kind) -> bool:
	return AILMENTS.has(kind)
