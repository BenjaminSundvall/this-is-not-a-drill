package main

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
    player: Player,
    level: Level,
    camera: rl.Camera2D,

    // UI
    notepad: UIElem,

    render_queue: [dynamic]RenderElement,
}
