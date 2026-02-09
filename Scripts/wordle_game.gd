# Core Wordle game logic (minimal: load + start).
class_name WordleGame
extends RefCounted

const DEFAULT_WORD_LENGTH := 5

var _word_length := DEFAULT_WORD_LENGTH
var _word_list: PackedStringArray = PackedStringArray()
var _secret_word := ""

# Load a word list from a text file (one word per line).
func load_word_list(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open word list: %s" % path)
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
	if _word_list.size() == 0:
		push_error("Word list is empty; load words before starting.")
		return
	var index := randi() % _word_list.size()
	_secret_word = _word_list[index]

# Submit a guess and get minimal feedback.
func guess(guess_word: String) -> Dictionary:
	if _secret_word == "":
		return {"ok": false, "error": "Game not started."}
	var cleaned := guess_word.strip_edges().to_lower()
	if cleaned.length() != _word_length:
		return {"ok": false, "error": "Guess must be %d letters." % _word_length}
	if not _word_list.has(cleaned):
		return {"ok": false, "error": "Guess is not in word list."}

	var feedback := _evaluate_feedback(cleaned)
	return {"ok": true, "guess": cleaned, "feedback": feedback}

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
			remaining_counts[ch] = count - 1
		else:
			feedback[i] = "gray"

	return feedback
