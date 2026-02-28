package main

import rl "vendor:raylib"
import la "core:math/linalg"
import "core:fmt"
import "core:math"
import "core:sort"

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

render_el_cmd :: proc(a, b: RenderElement) -> int {
    if a.z == b.z {
        return 0
    }
    return a.z < b.z ? -1 : 1
}

draw_cam :: proc() {
    sort.quick_sort_proc(gs.render_queue[:], render_el_cmd)

    for el in gs.render_queue {
        rl.DrawTexturePro(el.texture^, el.src, el.dest, 
                          {0, 0}, 0, rl.WHITE)
    }
    //rl.DrawTextureV(gs.player.texture, gs.player.pos, rl.WHITE)
}

draw_ui :: proc() {
    rl.DrawTextureV(gs.notepad.texture, gs.notepad.pos, rl.WHITE)
}

draw_game :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground({160, 200, 255, 255})

    resize(&gs.render_queue, 0)
    level_refresh(&gs.level)

    el: RenderElement = {
        &gs.player.texture,
        {0, 0, f32(gs.player.texture.width), f32(gs.player.texture.height)},
        {gs.player.pos.x - 0.5,
         gs.player.pos.y - 1.0,
         1.0, 2.0,
        },
        gs.player.pos.y,
        u32(len(gs.render_queue)),
    }
    append(&gs.render_queue, el)


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

    rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

    gs.player = {
        pos = {0, 0},
        texture = rl.LoadTexture("resources/player.png"),
        speed = 10,
    }

    gs.level = load_level() 
    gs.camera = {
        zoom = TILE_SCALE * 4,
        offset = {f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)},
        target = gs.player.pos,
    }

    gs.notepad = {
        pos = {0, 0},
        texture = rl.LoadTexture("resources/notepad.png"),
    }

    for !rl.WindowShouldClose() {
        input := handle_input()

        gs.player.pos += gs.player.speed * la.normalize0(input) * rl.GetFrameTime()
        gs.camera.target.x = math.clamp(gs.player.pos.x, 0, 256) // TODO: Clamp to available map area
        gs.camera.target.y = math.clamp(gs.player.pos.y, 0, 256) // TODO: Clamp to available map area

        draw_game()
    }

    rl.CloseWindow()
}
