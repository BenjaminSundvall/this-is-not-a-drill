package main

import rl "vendor:raylib"

GameState :: struct {
    // Game
    player: Player,
    level: Level,
    camera: rl.Camera2D,

    // UI
    notepad: UIElem,
}