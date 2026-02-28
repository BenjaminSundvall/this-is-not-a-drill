package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

RenderElement :: struct {
    texture: ^rl.Texture2D,
    src: rl.Rectangle,
    dest: rl.Rectangle,
    z: f32,
    ix: u32,
}

GameState :: struct {
    // Game
    game_over: bool,
    dbg_draw: b2.DebugDraw,
    world: b2.WorldId,
    player: Player,
    level: Level,
    camera: rl.Camera2D,
    time_limit: f64,
    time_left: f64,
    cam_boundary_tl: [2]f32,
    cam_boundary_br: [2]f32,

    render_queue: [dynamic]RenderElement,
    notepad_texture: rl.Texture2D,
}
