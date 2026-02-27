package main

import rl "vendor:raylib"
import la "core:math/linalg"
import "core:fmt"

main :: proc() {
    fmt.println("Hellope!")
    rl.InitWindow(1280, 720, "this is not a drill")
    player := rl.LoadTexture("player.png")
    player_pos: [2]f32
    speed: f32 = 500 // px/second

    for !rl.WindowShouldClose() {
        input: [2]f32

        if rl.IsKeyDown(.UP) {
            input.y -= 1
        }
        if rl.IsKeyDown(.DOWN) {
            input.y += 1
        }
        if rl.IsKeyDown(.LEFT) {
            input.x -= 1
        }
        if rl.IsKeyDown(.RIGHT) {
            input.x += 1
        }

        player_pos += speed * la.normalize0(input) * rl.GetFrameTime()

        rl.BeginDrawing()
        rl.ClearBackground({160, 200, 255, 255})
        rl.DrawTextureV(player, player_pos, rl.WHITE)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
