extends CharacterBody2D

func _ready() -> void:
	# Color the dino to match the problem type picked in the main menu
	$AnimatedSprite2D.material.set_shader_parameter("hue_shift", GlobalConfig.get_dino_hue_shift())

func _physics_process(delta: float) -> void:
	if not get_parent().game_running:
		velocity.x = 0
		$AnimatedSprite2D.play("idle")
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += GlobalConfig.gravity * delta

	# Handle jump.
	if is_on_floor():
		$AnimatedSprite2D.play("running")
		if Input.is_action_just_pressed("Jump"):
			$AudioStreamPlayer.play()
			velocity.y = GlobalConfig.jump_velocity
			$AnimatedSprite2D.play("jumping")
	else:
		$AnimatedSprite2D.play("jumping")

	move_and_slide()
