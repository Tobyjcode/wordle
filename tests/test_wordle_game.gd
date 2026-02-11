# WordleGame unit tests using GUT.
extends GutTest

# Create a new game with a deterministic secret word.
func _make_game(word_list: PackedStringArray, secret_word: String) -> WordleGame:
	var game := WordleGame.new()
	game.set_word_list(word_list)
	game.start_new_game()
	game._secret_word = secret_word
	return game

# Reject guesses before the game starts.
func test_guess_before_start_rejected() -> void:
	var game := WordleGame.new()
	game.set_word_list(PackedStringArray(["cigar"]))
	var result := game.guess("cigar")
	assert_false(result.get("ok", true))
	assert_eq(result.get("error", ""), "Game not started.")

# Reject starting a game with an empty word list.
func test_start_new_game_empty_list() -> void:
	var game := WordleGame.new()
	game.start_new_game()
	assert_eq(game.get_secret_word(), "")

# Reject guesses not in the word list.
func test_guess_not_in_list_rejected() -> void:
	var game := _make_game(PackedStringArray(["cigar", "rebus"]), "cigar")
	var result := game.guess("zzzzz")
	assert_false(result.get("ok", true))
	assert_eq(result.get("error", ""), "Guess is not in word list.")

# Reject guesses of the wrong length.
func test_guess_wrong_length_rejected() -> void:
	var game := _make_game(PackedStringArray(["cigar"]), "cigar")
	var result := game.guess("cat")
	assert_false(result.get("ok", true))
	assert_eq(result.get("error", ""), "Guess must be 5 letters.")

# Return all green feedback for a correct guess.
func test_guess_all_green_win() -> void:
	var game := _make_game(PackedStringArray(["cigar"]), "cigar")
	var result := game.guess("cigar")
	assert_true(result.get("ok", false))
	assert_eq(result.get("feedback", []), ["green", "green", "green", "green", "green"])
	assert_true(result.get("is_win", false))
	assert_true(result.get("is_over", false))

# Handle duplicate letters correctly in feedback.
func test_feedback_duplicates() -> void:
	var game := _make_game(PackedStringArray(["allee", "eagle"]), "allee")
	var result := game.guess("eagle")
	assert_true(result.get("ok", false))
	assert_eq(result.get("feedback", []), ["yellow", "yellow", "gray", "yellow", "green"])

# End the game after the maximum number of attempts.
func test_game_over_after_max_attempts() -> void:
	var game := _make_game(PackedStringArray(["cigar", "rebus"]), "cigar")
	for i in WordleGame.DEFAULT_MAX_ATTEMPTS:
		var result := game.guess("rebus")
		assert_true(result.get("ok", false))
	assert_true(game.is_game_over())
	assert_false(game._is_win)

# Reject guesses after the game ends.
func test_guess_after_game_over_rejected() -> void:
	var game := _make_game(PackedStringArray(["cigar", "rebus"]), "cigar")
	var win_result := game.guess("cigar")
	assert_true(win_result.get("is_over", false))
	var result := game.guess("rebus")
	assert_false(result.get("ok", true))
	assert_eq(result.get("error", ""), "Game is over.")

# Coverage report should meet the 70% target for core logic.
func test_coverage_report_at_least_70() -> void:
	var game := WordleGame.new()
	game.reset_coverage()

	# Empty list -> start_new_game_empty_list + guess_not_started
	game.start_new_game()
	game.guess("cigar")

	# Normal setup
	game.set_word_list(PackedStringArray(["cigar", "rebus", "allee", "eagle"]))
	game.start_new_game()
	game._secret_word = "allee"

	# Wrong length and not-in-list
	game.guess("cat")
	game.guess("zzzzz")

	# Yellow/gray/green feedback
	game.guess("eagle")

	# Win path
	game._attempts_used = 0
	game._is_over = false
	game._secret_word = "cigar"
	game.guess("cigar")

	# Game over path
	game._attempts_used = WordleGame.DEFAULT_MAX_ATTEMPTS - 1
	game._is_over = false
	game._secret_word = "cigar"
	game.guess("rebus")

	# Guess after game over
	game._is_over = true
	game.guess("cigar")

	var report := game.get_coverage_report()
	assert_true(float(report.get("percent", 0.0)) >= 70.0)
