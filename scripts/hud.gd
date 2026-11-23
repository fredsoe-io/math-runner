extends CanvasLayer

signal menu_requested
## The player pressed Save (or Enter) with this name
signal save_requested(player_name: String)

const NEW_SCORE_COLOR := Color.GOLD

@onready var healthbar = $Healthbar

var _saving := false
var _board_name := ""

func _ready() -> void:
	$GameOverScreen.visible = false
	# The last name typed is remembered for next time
	%NameEdit.text = GlobalConfig.load_player_setting("name", "")

func set_formular(formular: String):
	$Formular.text = formular

func set_score(score: int):
	$Score.text = tr("Score: %d") % score

func lose_life():
	healthbar.lose_life()

func reset_lives():
	healthbar.reset_lives()

func initialize_lives(n_lives: int) -> void:
	$Healthbar.initialize_lives(n_lives)

func show_game_over(state: bool = true):
	$GameOverScreen.visible = state
	if state:
		_saving = false
		_clear_rows()
		%StatusLabel.text = tr("Loading the scoreboard...")
		%SaveButton.disabled = false
	else:
		%NameEdit.release_focus()

## A score of 0 or less cannot be saved
func set_save_allowed(allowed: bool) -> void:
	%SaveButton.disabled = not allowed
	%NameEdit.editable = allowed

func set_board_name(board_name: String) -> void:
	_board_name = board_name
	%BoardTitle.text = tr("Top 10 - %s") % board_name

## Shows part of the board: the top 10, or after saving the 10 entries around
## the new score. new_rank > 0 means the player's score was just saved.
func show_board(entries: Array, new_rank: int) -> void:
	_clear_rows()
	var is_top := entries.is_empty() or int(entries[0].rank) == 1
	%BoardTitle.text = (tr("Top 10 - %s") if is_top else tr("Your place - %s")) % _board_name
	for entry in entries:
		var color: Color = NEW_SCORE_COLOR if entry.get("is_new", false) else Color.WHITE
		# JSON numbers arrive as floats, so make them whole numbers again
		_add_cell("%d." % int(entry.rank), color, HORIZONTAL_ALIGNMENT_RIGHT)
		_add_cell(entry.name, color, HORIZONTAL_ALIGNMENT_LEFT, true)
		_add_cell(str(int(entry.score)), color, HORIZONTAL_ALIGNMENT_RIGHT)

	if new_rank > 0:
		_saving = false
		%SaveButton.disabled = true
		%StatusLabel.text = tr("Saved! You are number %d") % new_rank
	elif entries.is_empty():
		%StatusLabel.text = tr("No scores yet. Be the first!")
	elif not _saving:
		%StatusLabel.text = ""

## Something went wrong with the scoreboard; the game itself carries on
func show_scoreboard_message(message: String) -> void:
	%StatusLabel.text = message
	if _saving:
		_saving = false
		%SaveButton.disabled = false

func _on_save_pressed() -> void:
	var player_name: String = %NameEdit.text.strip_edges()
	if player_name == "":
		%StatusLabel.text = tr("Type your name first")
		return
	GlobalConfig.save_player_setting("name", player_name)
	%NameEdit.release_focus()
	_saving = true
	%SaveButton.disabled = true
	%StatusLabel.text = tr("Saving...")
	save_requested.emit(player_name)

func _on_name_submitted(_text: String) -> void:
	if not %SaveButton.disabled:
		_on_save_pressed()

func _on_name_edit_focus_entered() -> void:
	# On a phone or tablet Godot's text field may not bring up the keyboard,
	# so ask with the browser's own prompt instead
	if OS.has_feature("web") and DisplayServer.is_touchscreen_available():
		%NameEdit.release_focus()
		var answer = JavaScriptBridge.eval("prompt(%s, %s)" % [JSON.stringify(tr("Your name")), JSON.stringify(%NameEdit.text)])
		if answer is String:
			%NameEdit.text = answer.strip_edges().left(%NameEdit.max_length)

func _on_menu_button_pressed() -> void:
	menu_requested.emit()

func _clear_rows() -> void:
	for child in %Rows.get_children():
		child.queue_free()

func _add_cell(text: String, color: Color, alignment: HorizontalAlignment, expand := false) -> void:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED # A player called "Addition" stays that
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	if expand:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%Rows.add_child(label)
