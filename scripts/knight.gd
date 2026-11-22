class_name Knight
extends Node2D
## The knight from Jumpy Boi with a weapon in its hand. The player and the
## buttons in the main menu both use this scene.

## How many pixels lower than normal the knight's body is in each frame of an
## animation (running repeats every 4 frames). The hand moves the same way, so
## the weapon stays in the hand when the knight bobs up and down.
const BOB := {
	&"idle": [-1, 0, 1, 0],
	&"running": [0, 0, 1, 0],
	&"jumping": [0],
}

## Turns the knight's colors around the color wheel, see knight_color.gdshader
@export_range(0.0, 1.0) var hue_shift: float = 0.0:
	set(value):
		hue_shift = value
		if is_node_ready():
			_apply_hue_shift()

@export var weapon: Weapon.Kind = Weapon.Kind.SWORD:
	set(value):
		weapon = value
		if is_node_ready():
			_weapon.kind = weapon

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hand: Node2D = $Hand
@onready var _weapon: Weapon = $Hand/Weapon
@onready var _hand_y: float = _hand.position.y


func _ready() -> void:
	# The setters skip this when they run before the children are ready
	_apply_hue_shift()
	_weapon.kind = weapon
	_move_hand()


func play(animation: StringName) -> void:
	_sprite.play(animation)


func swing() -> void:
	_weapon.swing()


func _apply_hue_shift() -> void:
	_sprite.material.set_shader_parameter("hue_shift", hue_shift)


# Connected to the sprite's frame_changed and animation_changed
func _move_hand() -> void:
	var bob: Array = BOB[_sprite.animation]
	_hand.position.y = _hand_y + bob[_sprite.frame % bob.size()]
