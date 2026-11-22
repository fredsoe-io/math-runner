class_name Weapon
extends Sprite2D
## The weapon in the knight's hand. Frame N of weapons.png is Kind N.
## The picture is moved so that its grip sits on this node's origin, so turning
## the node turns the weapon around the hand.

## Same order as WEAPONS in tools/make_assets.py
enum Kind { SWORD, SPEAR, MACE, AXE }

const FRAME_SIZE := Vector2(16, 24)

## How each weapon hits: it turns to "angle" degrees (0 = straight up,
## 90 = pointing forward) and moves "reach" pixels forward
const SWINGS := {
	Kind.SWORD: {"angle": 110.0, "reach": 0.0}, # a slash
	Kind.SPEAR: {"angle": 90.0, "reach": 5.0}, # a stab
	Kind.MACE: {"angle": 135.0, "reach": 0.0}, # a smash
	Kind.AXE: {"angle": 125.0, "reach": 0.0}, # a chop
}
const HIT_TIME := 0.06 # seconds from upright to the hit
const HOLD_TIME := 0.1
const RETURN_TIME := 0.15

@export var kind: Kind = Kind.SWORD:
	set(value):
		kind = value
		region_rect = Rect2(Vector2(kind * FRAME_SIZE.x, 0), FRAME_SIZE)

var _tween: Tween


func swing() -> void:
	# Start again from upright if it is already swinging
	if _tween:
		_tween.kill()
	rotation_degrees = 0.0
	position = Vector2.ZERO

	var move: Dictionary = SWINGS[kind]
	_tween = create_tween()
	_tween.tween_property(self, "rotation_degrees", move.angle, HIT_TIME)
	_tween.parallel().tween_property(self, "position:x", move.reach, HIT_TIME)
	_tween.tween_interval(HOLD_TIME)
	_tween.tween_property(self, "rotation_degrees", 0.0, RETURN_TIME)
	_tween.parallel().tween_property(self, "position:x", 0.0, RETURN_TIME)
