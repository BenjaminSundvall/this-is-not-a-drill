package main

import rl "vendor:raylib"

GameState :: struct {
    // Game
    game_over: bool,
    player: Player,
    level: Level,
    camera: rl.Camera2D,
    time_limit: f64,
    time_left: f64,
    cam_boundary_tl: [2]f32,
    cam_boundary_br: [2]f32,
    tasks: [dynamic]Task,

    // UI
    font: rl.Font,
    notepad_texture: rl.Texture2D,
    checkbox_empty_texture: rl.Texture2D,
    checkbox_ok_texture: rl.Texture2D,
}