# Wordle
A Wordle-style game made in Godot 4.

## Gameplay
- A secret 5-letter word is chosen from [Data/wordle_ord.txt](Data/wordle_ord.txt).
- You have 6 attempts to guess the word.
- Feedback colors: green = correct letter + position, yellow = correct letter wrong position, gray = not in the word.

## Run
- Open the project in Godot 4.
- Press Play.

## Controls
- Type letters to fill the row.
- Enter to submit, Backspace to delete.
- Press R to restart after a game ends.

## Testing (GUT)
- Enable the GUT plugin: Project > Project Settings > Plugins > Gut > Enable.
- Open the GUT panel (bottom dock) and click Run All.
- Tests live in [tests/test_wordle_game.gd](tests/test_wordle_game.gd).

## License
MIT — see [LICENSE](LICENSE).
