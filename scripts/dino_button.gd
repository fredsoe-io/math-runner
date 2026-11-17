extends Button
## A dino you can pick in the main menu. There is one for each problem type.

signal dino_selected(problem_type: Constants.ProblemType)

# The first frames of dino.png are the idle animation
const IDLE_FRAMES = 4
const FRAME_WIDTH = 24

@export var problem_type: Constants.ProblemType
@export var dino_name: String
@export var symbol: String

var idle_frame: int = 0

func _ready() -> void:
	$VBoxContainer/NameLabel.text = dino_name
	$VBoxContainer/SymbolLabel.text = symbol
	$VBoxContainer/Dino.material.set_shader_parameter("hue_shift", GlobalConfig.get_dino_hue_shift(problem_type))

func _pressed() -> void:
	dino_selected.emit(problem_type)

func _on_idle_timer_timeout() -> void:
	# Show the next idle frame, so the dino moves its hands and bobs its head
	idle_frame = (idle_frame + 1) % IDLE_FRAMES
	var region: Rect2 = $VBoxContainer/Dino.texture.region
	region.position.x = idle_frame * FRAME_WIDTH
	$VBoxContainer/Dino.texture.region = region
