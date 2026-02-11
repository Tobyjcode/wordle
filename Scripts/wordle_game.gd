# Core Wordle game logic (minimal: load + start).
class_name WordleGame
extends RefCounted

const DEFAULT_WORD_LENGTH := 5
const DEFAULT_MAX_ATTEMPTS := 6

# Coverage points for core logic (manual tracking).
static var COVERAGE_POINTS := [
	"start_new_game_empty_list",
	"start_new_game_pick",
	"guess_over",
	"guess_not_started",
	"guess_wrong_len",
	"guess_not_in_list",
	"guess_ok",
	"guess_win",
	"attempts_exhausted",
	"feedback_green",
	"feedback_yellow",
	"feedback_gray",
	"is_all_correct_true",
	"is_all_correct_false",
]

var _word_length := DEFAULT_WORD_LENGTH
var _max_attempts := DEFAULT_MAX_ATTEMPTS
var _word_list: PackedStringArray = PackedStringArray()
var _secret_word := ""
var _attempts_used := 0
var _is_over := false
var _is_win := false
var _coverage_hits: Dictionary = {}

# Mark a coverage point as hit.
func _cov_hit(point: String) -> void:
	_coverage_hits[point] = int(_coverage_hits.get(point, 0)) + 1

# Reset coverage tracking for this instance.
func reset_coverage() -> void:
	_coverage_hits.clear()

# Report coverage stats for core logic.
func get_coverage_report() -> Dictionary:
	var hit := 0
	var missing: Array = []
	for point in COVERAGE_POINTS:
		if int(_coverage_hits.get(point, 0)) > 0:
			hit += 1
		else:
			missing.append(point)
	var total := COVERAGE_POINTS.size()
	var percent := 0.0
	if total > 0:
		percent = (float(hit) / float(total)) * 100.0
	return {
		"hit": hit,
		"total": total,
		"percent": percent,
		"missing": missing
	}

# Load a word list from a text file (one word per line).
func load_word_list(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var words: PackedStringArray = PackedStringArray()
	while not file.eof_reached():
		var line := file.get_line().strip_edges().to_lower()
		if line.length() == _word_length:
			words.append(line)
	set_word_list(words)

# Replace the current word list.
func set_word_list(words: PackedStringArray) -> void:
	_word_list = PackedStringArray()
	for word in words:
		var cleaned := String(word).strip_edges().to_lower()
		if cleaned.length() == _word_length:
			_word_list.append(cleaned)

# Pick a random secret word from the list and reset state.
func start_new_game() -> void:
	_secret_word = ""
	_attempts_used = 0
	_is_over = false
	_is_win = false
	if _word_list.size() == 0:
		_cov_hit("start_new_game_empty_list")
		return
	var index := randi() % _word_list.size()
	_secret_word = _word_list[index]
	_cov_hit("start_new_game_pick")

# Get the current secret word (for UI/testing).
func get_secret_word() -> String:
	return _secret_word

# Submit a guess and get minimal feedback.
func guess(guess_word: String) -> Dictionary:
	if _is_over:
		_cov_hit("guess_over")
		return {"ok": false, "error": "Game is over."}
	if _secret_word == "":
		_cov_hit("guess_not_started")
		return {"ok": false, "error": "Game not started."}
	var cleaned := guess_word.strip_edges().to_lower()
	if cleaned.length() != _word_length:
		_cov_hit("guess_wrong_len")
		return {"ok": false, "error": "Guess must be %d letters." % _word_length}
	if not _word_list.has(cleaned):
		_cov_hit("guess_not_in_list")
		return {"ok": false, "error": "Guess is not in word list."}

	_attempts_used += 1
	var feedback := _evaluate_feedback(cleaned)
	_is_win = _is_all_correct(feedback)
	_cov_hit("guess_ok")
	if _is_win:
		_cov_hit("guess_win")
	if _is_win or _attempts_used >= _max_attempts:
		if _attempts_used >= _max_attempts:
			_cov_hit("attempts_exhausted")
		_is_over = true

	return {
		"ok": true,
		"guess": cleaned,
		"feedback": feedback,
		"attempts_used": _attempts_used,
		"attempts_left": _max_attempts - _attempts_used,
		"is_win": _is_win,
		"is_over": _is_over
	}

# Query if the game is over.
func is_game_over() -> bool:
	return _is_over

# Remaining attempts.
func attempts_left() -> int:
	return _max_attempts - _attempts_used

# Compute feedback with duplicate-letter handling.
func _evaluate_feedback(guess_word: String) -> Array:
	var feedback: Array = []
	feedback.resize(_word_length)

	var secret_chars := _secret_word.split("")
	var guess_chars := guess_word.split("")

	var remaining_counts := {}
	for i in _word_length:
		if guess_chars[i] == secret_chars[i]:
			feedback[i] = "green"
			_cov_hit("feedback_green")
		else:
			var ch := secret_chars[i]
			remaining_counts[ch] = int(remaining_counts.get(ch, 0)) + 1

	for i in _word_length:
		if feedback[i] == "green":
			continue
		var ch := guess_chars[i]
		var count := int(remaining_counts.get(ch, 0))
		if count > 0:
			feedback[i] = "yellow"
			_cov_hit("feedback_yellow")
			remaining_counts[ch] = count - 1
		else:
			feedback[i] = "gray"
			_cov_hit("feedback_gray")

	return feedback

# Check if all feedback entries are correct.
func _is_all_correct(feedback: Array) -> bool:
	for status in feedback:
		if status != "green":
			_cov_hit("is_all_correct_false")
			return false
	_cov_hit("is_all_correct_true")
	return true
