extends Control

# Main Wordle board game

# Board dimensions and attempts
const WORDLENGTH := 5
const MAXATTEMPTS := 6


# Tile colors (Wordle palette)
const COLOR_EMPTY := Color("1f1f1f")
const COLOR_CORRECT := Color("6aaa64")
const COLOR_PRESENT := Color("c9b458")
const COLOR_ABSENT := Color("787c7e")
const COLOR_TEXT := Color("ffffff")

# Optional inspector references (manual wiring)
@export var grid_container: GridContainer
@export var status: Label

# Cached nodes (auto lookup when scene is ready)
@onready var grid: GridContainer = $VBoxContainer/GridContainer
@onready var status_label: Label = $VBoxContainer/Status
@onready var keyboard_container: GridContainer = $VBoxContainer/Keyboard


# Core game logic instance
var game := WordleGame.new()

# 2D array of tiles (row -> col)
var tiles: Array = []

# Keyboard letter buttons
var keyboard_keys: Dictionary = {}

# Letter status tracking for keyboard (best status per letter)
var letter_status: Dictionary = {}

# Current input position
var current_row := 0
var current_col := 0

# Set initial UI text when the scene loads
func _ready() -> void:
	game.load_word_list("res://Data/wordle_ord.txt")
	game.start_new_game()
	_collect_tiles()
	_setup_keyboard()
	status_label.text = "Type a 5-letter word. Attempts left: %d" % game.attempts_left()

# Setup keyboard display
func _setup_keyboard() -> void:
	var keyboard_rows := [
		"QWERTYUIOP",
		"ASDFGHJKL",
		"ZXCVBNM"
	]
	
	for row_text in keyboard_rows:
		for ch in row_text:
			var key := ColorRect.new()
			key.custom_minimum_size = Vector2(32, 40)
			key.color = COLOR_EMPTY
			var label := Label.new()
			label.text = ch
			label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", COLOR_TEXT)
			label.add_theme_font_size_override("font_size", 16)
			key.add_child(label)
			keyboard_container.add_child(key)
			keyboard_keys[ch.to_lower()] = key
			letter_status[ch.to_lower()] = ""

# Collect 30 tiles from the GridContainer into a 6x5 array
func _collect_tiles() -> void:
	_tiles_clear()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var children := grid.get_children()
	if children.size() < WORDLENGTH * MAXATTEMPTS:
		push_error("GridContainer must have 30 ColorRect tiles.")
		return

	for row in MAXATTEMPTS:
		var row_tiles: Array = []
		for col in WORDLENGTH:
			var index := row * WORDLENGTH + col
			var tile := children[index] as ColorRect
			if tile == null:
				push_error("Tile at index %d is not a ColorRect." % index)
				continue
			tile.color = COLOR_EMPTY
			tile.custom_minimum_size = Vector2(64, 64)
			var label := tile.get_node_or_null("Label") as Label
			if label != null:
				label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				label.grow_horizontal = Control.GROW_DIRECTION_BOTH
				label.grow_vertical = Control.GROW_DIRECTION_BOTH
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.add_theme_color_override("font_color", COLOR_TEXT)
				label.add_theme_font_size_override("font_size", 32)
			row_tiles.append(tile)
		tiles.append(row_tiles)

# Clear tile cache
func _tiles_clear() -> void:
	tiles.clear()

# Set the letter on a tile (UI helper)
func set_tile_letter(row: int, col: int, ch: String) -> void:
	var tile: ColorRect = tiles[row][col]
	var label: Label = tile.get_node_or_null("Label")
	if label == null:
		return
	label.text = ch.to_upper()

# Clear a tile's letter
func clear_tile(row: int, col: int) -> void:
	set_tile_letter(row, col, "")

# Handle keyboard input for typing, backspace, and submit
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_R:
		if game.is_game_over():
			_restart_game()
			return

	if game.is_game_over():
		return

	if key_event.keycode == KEY_BACKSPACE:
		_handle_backspace()
		return
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		_handle_submit()
		return

	if key_event.unicode > 0:
		var ch := String.chr(key_event.unicode).to_lower()
		if ch.length() == 1 and ch >= "a" and ch <= "z":
			_handle_letter(ch)

# Add a letter to the current row
func _handle_letter(ch: String) -> void:
	if current_col >= WORDLENGTH or current_row >= MAXATTEMPTS:
		return
	set_tile_letter(current_row, current_col, ch)
	current_col += 1

# Remove a letter from the current row
func _handle_backspace() -> void:
	if current_col <= 0:
		return
	current_col -= 1
	clear_tile(current_row, current_col)

# Submit the current row (placeholder for now)
func _handle_submit() -> void:
	if current_col < WORDLENGTH:
		status_label.text = "Not enough letters."
		return

	var guess := ""
	for col in WORDLENGTH:
		var tile: ColorRect = tiles[current_row][col]
		var label: Label = tile.get_node_or_null("Label")
		if label == null:
			push_error("Tile is missing a Label child at %d,%d" % [current_row, col])
			return
		guess += label.text.to_lower()

	var result := game.guess(guess)
	if not result.get("ok", false):
		status_label.text = String(result.get("error", "Invalid guess."))
		return

	_apply_feedback(current_row, result["feedback"])
	if result.get("is_win", false):
		status_label.text = "You win!"
		return
	if result.get("is_over", false):
		status_label.text = "Game over. Word was: %s" % game.get_secret_word().to_upper()
		return

	status_label.text = "Guess accepted. Attempts left: %d" % int(result.get("attempts_left", 0))
	current_row += 1
	current_col = 0

# Restart the game and clear the board
func _restart_game() -> void:
	game.start_new_game()
	current_row = 0
	current_col = 0
	for row in MAXATTEMPTS:
		for col in WORDLENGTH:
			clear_tile(row, col)
			tiles[row][col].color = COLOR_EMPTY
	# Reset keyboard
	for letter in keyboard_keys:
		keyboard_keys[letter].color = COLOR_EMPTY
		letter_status[letter] = ""
	status_label.text = "New game. Attempts left: %d" % game.attempts_left()

# Update keyboard letter color based on feedback (keep best status)
func _update_keyboard_letter(letter: String, status: String) -> void:
	if not keyboard_keys.has(letter):
		return
	
	var current_status: String = letter_status[letter]
	var new_color := COLOR_EMPTY
	
	# Priority: green > yellow > gray
	if status == "green" or current_status == "green":
		new_color = COLOR_CORRECT
		letter_status[letter] = "green"
	elif status == "yellow" or (current_status == "yellow" and status != "green"):
		new_color = COLOR_PRESENT
		letter_status[letter] = "yellow"
	elif status == "gray":
		new_color = COLOR_ABSENT
		if current_status == "":
			letter_status[letter] = "gray"
	
	keyboard_keys[letter].color = new_color

# Apply feedback colors to a row
func _apply_feedback(row: int, feedback: Array) -> void:
	for col in WORDLENGTH:
		var tile: ColorRect = tiles[row][col]
		var status := String(feedback[col])
		match status:
			"green":
				tile.color = COLOR_CORRECT
			"yellow":
				tile.color = COLOR_PRESENT
			"gray":
				tile.color = COLOR_ABSENT
			_:
				tile.color = COLOR_EMPTY
		
		# Update keyboard
		var label: Label = tile.get_node_or_null("Label")
		if label != null:
			var letter := label.text.to_lower()
			_update_keyboard_letter(letter, status)
