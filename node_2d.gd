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
