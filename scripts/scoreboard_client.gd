class_name ScoreboardClient
extends Node
## Talks to the scoreboard API (github.com/fredsoe-io/scoreboard). It asks for a
## run when a game starts and sends the score with that run when the game is
## over. The server uses the run to check that the score fits the time played.
##
## On the web it talks to the site the game was loaded from. Elsewhere (in the
## editor) it is off unless GlobalConfig.scoreboard_url is set.

## Part of the board arrived: the top 10, or after saving the 10 entries
## around the new score (5 above, 4 below). entries is an Array of Dictionaries
## with rank, name, score and is_new. new_rank is the rank of the score just
## saved, or 0 when nothing was saved.
signal board_loaded(entries: Array, new_rank: int)
## Something went wrong; message is meant for the player
signal failed(message: String)

const GAME := "math-runner"
const API_PATH := "/api/scoreboard"
## Written by tools/export_web.sh from $SCOREBOARD_KEY; not in git
const KEY_FILE := "res://secrets/scoreboard.cfg"
const TIMEOUT := 10.0

var _base_url := ""
var _key := ""
var _board := ""
var _run_id := ""
var _run_request := 0 # counts start_run calls, so only the newest one counts


func _ready() -> void:
	_base_url = _find_base_url()
	_key = _read_key()


func is_enabled() -> bool:
	return _base_url != ""


## Call when a game starts
func start_run(board: String) -> void:
	_board = board
	_run_id = ""
	if not is_enabled():
		return
	_run_request += 1
	var this_request := _run_request
	var body = await _request(HTTPClient.METHOD_POST, "/runs", {"game": GAME, "board": board})
	# A restart can start a newer run before this one answers
	if body != null and this_request == _run_request:
		_run_id = body.run_id


## Saves the score of the current run and then emits board_loaded
func submit(player_name: String, score: int) -> void:
	if not is_enabled():
		failed.emit("The scoreboard is not available")
		return
	if _run_id == "":
		failed.emit("This game could not be saved")
		return
	var run_id := _run_id
	var payload := {
		"run_id": run_id,
		"name": player_name,
		"score": score,
		"signature": _sign("%s|%s|%d" % [run_id, player_name, score]),
	}
	var body = await _request(HTTPClient.METHOD_POST, "/scores", payload)
	if body == null:
		return
	if _run_id == run_id:
		_run_id = "" # a run gets one score
	board_loaded.emit(body.scores, int(body.rank))


## Loads the top 10 of the current board and then emits board_loaded
func load_board() -> void:
	if not is_enabled():
		failed.emit("The scoreboard is not available")
		return
	var body = await _request(HTTPClient.METHOD_GET, "/%s/%s" % [GAME, _board])
	if body != null:
		board_loaded.emit(body.scores, 0)


# Sends one request and returns the parsed JSON answer, or null after emitting failed
func _request(method: HTTPClient.Method, path: String, payload = null) -> Variant:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	var data := "" if payload == null else JSON.stringify(payload)
	var error := http.request(_base_url + API_PATH + path, headers, method, data)
	if error != OK:
		http.queue_free()
		failed.emit("The scoreboard is not available")
		return null

	var response: Array = await http.request_completed # result, code, headers, body
	http.queue_free()
	var code: int = response[1]
	if response[0] != HTTPRequest.RESULT_SUCCESS or code == 0:
		failed.emit("The scoreboard is not available")
		return null
	# JSON.new().parse() only returns an error code; JSON.parse_string() would
	# also print one when a proxy answers with HTML
	var json := JSON.new()
	var body = json.data if json.parse(response[3].get_string_from_utf8()) == OK else null
	if code >= 400:
		failed.emit(_message_for(code, body))
		return null
	return body


func _message_for(code: int, body) -> String:
	match code:
		403:
			return "That score could not be saved" # bad signature
		409:
			return "This score is already saved"
		410:
			return "Too late to save this score"
		422:
			# Usually a name with symbols in it. The server says what is wrong in "detail".
			if body is Dictionary and body.get("detail") is Array:
				return "Names can only have letters, numbers, spaces, - and _"
			return "That score could not be saved"
		429:
			return "Too many games at once, wait a minute"
	return "The scoreboard is not available"


func _sign(message: String) -> String:
	if _key == "":
		return ""
	var digest := Crypto.new().hmac_digest(HashingContext.HASH_SHA256, _key.to_utf8_buffer(), message.to_utf8_buffer())
	return digest.hex_encode()


func _find_base_url() -> String:
	if GlobalConfig.scoreboard_url != "":
		return GlobalConfig.scoreboard_url
	if OS.has_feature("web"):
		var origin = JavaScriptBridge.eval("window.location.origin")
		if origin is String:
			return origin
	return ""


func _read_key() -> String:
	var config := ConfigFile.new()
	if config.load(KEY_FILE) != OK:
		return ""
	return config.get_value("scoreboard", "key", "")
