extends CharacterBody2D

func _ready() -> void:
	# The knight's color and weapon go with the problem type picked in the main menu
	$Knight.hue_shift = GlobalConfig.get_knight_hue_shift()
	$Knight.weapon = GlobalConfig.get_weapon()

## Hits the answer the player just ran into
func swing() -> void:
	$Knight.swing()

func _physics_process(delta: float) -> void:
	if not get_parent().game_running:
		velocity.x = 0
		$Knight.play("idle")
		return

	# Add the gravity.
	if not is_on_floor():
		velocity.y += GlobalConfig.gravity * delta

	# Handle jump.
	if is_on_floor():
		$Knight.play("running")
		if Input.is_action_just_pressed("Jump"):
			velocity.y = GlobalConfig.jump_velocity
			$Knight.play("jumping")
	else:
		$Knight.play("jumping")

	move_and_slide()
