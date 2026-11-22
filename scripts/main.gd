extends Node

var game_running: bool = false
var last_ground_x: float = 0.0
var ground_width: float
var current_speed: float
var score: float = 0.0
var lives: int = 0 # Will be set in reset_game
var problems := []

var problem_screen = preload("res://scenes/problem.tscn")

func _ready() -> void:
	# Get the width from the sprite or collision shape
	ground_width = $Ground/Sprite2D.texture.get_width()
	last_ground_x = $Ground.position.x
	
	# The knight was picked in the main menu, so start running right away
	reset_game()
	game_running = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_to_menu()
	elif event.is_action_pressed("Jump") and not game_running:
		# Jump after a game over to try again. A click on a HUD button never
		# gets here, so pressing "Pick another knight" does not restart the game
		reset_game()
		game_running = true

func go_to_menu() -> void:
	Engine.time_scale = 1.0 # In case we leave during the damage slowdown
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _process(delta: float) -> void:
	if not game_running:
		return

	# Gradually increase speed up to maximum
	current_speed = min(
		current_speed + GlobalConfig.acceleration * delta,
		GlobalConfig.max_speed
	)

	$Player.position.x += current_speed * delta
	$Camera2D.position.x += current_speed * delta

	manage_ground($Camera2D.position.x)
	remove_problems()
	generate_problem()
	move_problems(delta)
	manage_score(delta)
	check_game_over()

func report_score(correct: bool, value: int):
	$Player.swing() # The knight hits the answer it ran into, right or wrong
	if correct:
		$Player/CorrectSound.play()
		score += value
	else:
		$Player/IncorrectSound.play()
		score -= value
		lives -= 1
		$HUD.lose_life()
		$DmgTimer.start()
		Engine.time_scale = 0.5
		

func check_game_over() -> void:
	if lives <= 0:
		# The last wrong answer has just started the wrong sound. Stop it, so
		# the two recordings don't play on top of each other
		$Player/IncorrectSound.stop()
		$Player/GameOverSound.play()
		$HUD.show_game_over(true)
		$HUD.set_save_allowed(int(score) > 0)
		$ScoreboardClient.load_board()
		# Free all existing problems from the scene
		for problem in problems:
			problem.queue_free()
		problems.clear()
		game_running = false

func reset_game():
	problems.clear()
	score = 0.0
	lives = GlobalConfig.initial_lives
	$HUD.initialize_lives(GlobalConfig.initial_lives)
	$HUD.set_score(score)
	current_speed = GlobalConfig.initial_speed
	$HUD.reset_lives()
	$HUD.show_game_over(false)
	# Each knight has its own board. The server starts the clock for this game now.
	var board: String = GlobalConfig.get_scoreboard_board()
	$HUD.set_board_name(board.capitalize())
	$ScoreboardClient.start_run(board)

func _on_save_requested(player_name: String) -> void:
	$ScoreboardClient.submit(player_name, int(score))

func manage_score(delta: float):
	var speed_multiplier = max(
		1.0,
		(current_speed - GlobalConfig.initial_speed) / GlobalConfig.speed_multiplier_step + 1.0
	)
	score += GlobalConfig.score_per_second * delta * speed_multiplier
	$HUD.set_score(int(score))

func generate_problem() -> void:
	if problems.is_empty():
		var question = GlobalConfig.question_generator.generate_question()

		var current_problem = problem_screen.instantiate()
		current_problem.initialize(question, $Player.position.x)
		problems.append(current_problem)
		add_child(current_problem)

func move_problems(delta: float):
	for problem in problems:
		problem.move(delta, current_speed)

func remove_problems():
	for problem in problems:
		if problem.get_position().x < $Player.position.x - 200:
			problem.queue_free()
			problems.erase(problem)
		

func manage_ground(camera_x: float) -> void:
	# Spawn new ground when camera approaches the end of the last ground
	if camera_x + get_viewport().size.x > last_ground_x:
		spawn_ground()
	
	cleanup_old_ground(camera_x)

func spawn_ground() -> void:
	var new_ground = $Ground.duplicate()
	new_ground.position.x = last_ground_x + ground_width
	add_child(new_ground)
	last_ground_x = new_ground.position.x

func cleanup_old_ground(camera_x: float) -> void:
	for ground in get_tree().get_nodes_in_group("ground"):
		if ground.position.x + ground_width < camera_x - get_viewport().size.x:
			ground.queue_free()


func _on_dmg_timer_timeout() -> void:
	Engine.time_scale = 1.0
