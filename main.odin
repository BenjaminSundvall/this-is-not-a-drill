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

draw_cam :: proc() {
    rl.DrawTextureV(gs.level.texture, {0, 0}, rl.WHITE)
    rl.DrawTextureV(gs.player.texture, gs.player.pos, rl.WHITE)
}

draw_ui :: proc() {
    rl.DrawTextureV(gs.notepad.texture, gs.notepad.pos, rl.WHITE)
}

draw_game :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground({160, 200, 255, 255})

    // Camera
    rl.BeginMode2D(gs.camera)
    draw_cam()
    rl.EndMode2D()

    // UI elements
    draw_ui()

    rl.EndDrawing()
}

main :: proc() {
    rl.InitWindow(1280, 720, "This is not a drill!")

    gs.player = {
        pos = {0, 0},
        texture = rl.LoadTexture("resources/player.png"),
        speed = 200,
    }

    gs.level = {
        texture = rl.LoadTexture("resources/dummy_level.png"),
    }

    gs.camera = {
        zoom = 8,
        offset = {f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)},
        target = gs.player.pos
    }

    gs.notepad = {
        pos = {0, 0},
        texture = rl.LoadTexture("resources/notepad.png")
    }

    for !rl.WindowShouldClose() {
        input := handle_input()

        gs.player.pos += gs.player.speed * la.normalize0(input) * rl.GetFrameTime()
        gs.camera.target.x = math.clamp(gs.player.pos.x, 0, 128) // TODO: Clamp to available map area
        gs.camera.target.y = math.clamp(gs.player.pos.y, 0, 128) // TODO: Clamp to available map area

        draw_game()
    }

    rl.CloseWindow()
}
