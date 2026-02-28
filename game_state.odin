package main

import rl "vendor:raylib"

GameState :: struct {
    // Game
    player: Player,
    level: Level,
    camera: rl.Camera2D,
    time: f64,
    cam_boundary_tl: [2]f32,
    cam_boundary_br: [2]f32,

    // UI
    notepad_texture: rl.Texture2D,
}