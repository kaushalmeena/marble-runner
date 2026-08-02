class_name PowerUps
extends RefCounted
## Static description of every pickup effect, good and bad.
##
## Keeping this in one place means the pickup scene, the manager, the HUD and
## the spawn table all agree without any of them knowing about each other.
##
## The good/bad split is deliberately legible before a player can read a label:
## helpful pickups are rounded and cool-coloured, hostile ones share a single
## spiked silhouette in hot red. One rule, no memorisation.

enum Kind {
	SHIELD,
	MAGNET,
	SLOW_MO,
	BOOST,
	SUPER_JUMP,
	FOG,
	SLUGGISH,
	REVERSED,
}

## Everything from here on is a debuff. Ordering the enum this way means the
## test is a comparison rather than a lookup table that can fall out of date.
const FIRST_DEBUFF := Kind.FOG

## Seconds each effect lasts. Debuffs are short: they should sting, not ruin a
## run that was going well.
const DURATIONS: Dictionary = {
	Kind.SHIELD: 10.0,
	Kind.MAGNET: 8.0,
	Kind.SLOW_MO: 5.0,
	Kind.BOOST: 4.5,
	Kind.SUPER_JUMP: 8.0,
	Kind.FOG: 4.0,
	Kind.SLUGGISH: 4.5,
	Kind.REVERSED: 3.5,
}

## Short names for the HUD chips.
const LABELS: Dictionary = {
	Kind.SHIELD: "SHIELD",
	Kind.MAGNET: "MAGNET",
	Kind.SLOW_MO: "SLOW",
	Kind.BOOST: "BOOST",
	Kind.SUPER_JUMP: "HIGH JUMP",
	Kind.FOG: "FOG",
	Kind.SLUGGISH: "SLUGGISH",
	Kind.REVERSED: "REVERSED",
}

## Buffs get cool, distinct hues. Debuffs all sit in the same hot red band, so
## the colour reads as a warning before the shape or the label registers.
const COLORS: Dictionary = {
	Kind.SHIELD: Color(0.35, 0.75, 1.0),
	Kind.MAGNET: Color(1.0, 0.55, 0.2),
	Kind.SLOW_MO: Color(0.68, 0.45, 1.0),
	Kind.BOOST: Color(0.3, 1.0, 0.6),
	Kind.SUPER_JUMP: Color(1.0, 0.88, 0.3),
	Kind.FOG: Color(0.85, 0.35, 0.45),
	Kind.SLUGGISH: Color(0.92, 0.25, 0.3),
	Kind.REVERSED: Color(0.95, 0.2, 0.6),
}


static func duration(kind: Kind) -> float:
	return DURATIONS.get(kind, 0.0)


static func label(kind: Kind) -> String:
	return LABELS.get(kind, "")


static func color(kind: Kind) -> Color:
	return COLORS.get(kind, Color.WHITE)


## True for pickups the player should be dodging.
static func is_debuff(kind: Kind) -> bool:
	return kind >= FIRST_DEBUFF
