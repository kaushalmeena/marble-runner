class_name PowerUpPickup
extends Area3D
## Tags a pickup with the power-up it grants.
##
## This is the one prop that carries a script, because it is the one prop that
## carries data. It still has no per-frame work: [Track] moves it like any
## other prop.

@export var kind: PowerUps.Kind = PowerUps.Kind.SHIELD
