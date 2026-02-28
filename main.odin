package main

import rl "vendor:raylib"
import la "core:math/linalg"
import "core:fmt"
import "core:math"

gs: GameState


handle_input :: proc() -> [2]f32 {
    input: [2]f32

    if rl.IsKeyDown(.W)  {
        input.y -= 1
    }
    if rl.IsKeyDown(.S) {
        input.y += 1
    }
    if rl.IsKeyDown(.A) {
        input.x -= 1
    }
    if rl.IsKeyDown(.D) {
        input.x += 1
    }

    return input
}

draw_game :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground({160, 200, 255, 255})

    camera := rl.Camera2D {
        zoom = 8,
        offset = {f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)},
        target = gs.player.pos
    }
    rl.BeginMode2D(camera)

    // Draw everything with a global position here...
    rl.DrawTextureV(gs.level.texture, {0, 0}, rl.WHITE)
    rl.DrawTextureV(gs.player.texture, gs.player.pos, rl.WHITE)
    rl.EndMode2D()

    // Draw UI elements here...

    rl.EndDrawing()
}

main :: proc() {
    rl.InitWindow(1280, 720, "This is not a drill!")

    gs.player = {
        pos = {0, 0},
        texture = rl.LoadTexture("player.png"),
        speed = 200,
    }

    gs.level = {
        texture = rl.LoadTexture("dummy_level.png"),
    }

    for !rl.WindowShouldClose() {
        input := handle_input()

        gs.player.pos += gs.player.speed * la.normalize0(input) * rl.GetFrameTime()

        draw_game()
    }

    rl.CloseWindow()
}
