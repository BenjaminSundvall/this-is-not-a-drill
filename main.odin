package main

import rl "vendor:raylib"
import la "core:math/linalg"
import "core:fmt"
import "core:math"
import "core:sort"
import "core:strings"

gs: GameState

TASK_FONT_SIZE :: 16
TASK_SPACING :: 32

CLOCK_FONT_SIZE :: 64

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
    // Draw tasks
    notepad_pos: [2]f32 = {8, 8}    // TODO: Move to right side
    rl.DrawTextureV(gs.notepad_texture, notepad_pos, rl.WHITE)
    task_pos := notepad_pos + {0, 32}
    for task in gs.tasks {
        if task.completed {
            rl.DrawTextureV(gs.checkbox_ok_texture, task_pos, rl.WHITE)
        } else {
            rl.DrawTextureV(gs.checkbox_empty_texture, task_pos, rl.WHITE)
        }
        rl.DrawTextEx(gs.font, task.description, task_pos + {32, (TASK_SPACING - TASK_FONT_SIZE) / 2}, TASK_FONT_SIZE, 1, rl.BLACK) // TODO: Font
        task_pos.y += TASK_SPACING
    }

    // Draw clock
    clock_string: cstring = strings.clone_to_cstring(fmt.tprintf("%2d:%2d", u32(gs.time_left) / 60, u32(gs.time_left) % 60))
    clock_size: [2]f32 = rl.MeasureTextEx(gs.font, clock_string, CLOCK_FONT_SIZE, 1)
    clock_pos: [2]f32 = {(f32(rl.GetScreenWidth()) - clock_size.x)/2, 0}
    rl.DrawTextEx(gs.font, clock_string, clock_pos, CLOCK_FONT_SIZE, 1, rl.RED)
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

game_over :: proc() {
    gs.game_over = true
    fmt.println("Game over!")
}

main :: proc() {
    rl.InitWindow(1280, 720, "This is not a drill!")

    rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))
    gs.game_over = false

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

    gs.time_limit = 120

    gs.cam_boundary_tl = {0, 0}
    gs.cam_boundary_br = {256, 256}

    gs.font = rl.LoadFont("resources/marker.ttf")
    gs.notepad_texture = rl.LoadTexture("resources/notepad.png")
    gs.checkbox_empty_texture = rl.LoadTexture("resources/checkbox_empty.png")
    gs.checkbox_ok_texture = rl.LoadTexture("resources/checkbox_ok.png")

    append(&gs.tasks, Task{description="Save the scientists (3/3)", completed=true})
    append(&gs.tasks, Task{description="Get out!"})

    for !rl.WindowShouldClose() {
        if !gs.game_over {
            input := handle_input()

            // Update game state
            gs.time_left = gs.time_limit - rl.GetTime()
            if gs.time_left <= 0 {
                game_over()
            }
            gs.player.pos += gs.player.speed * la.normalize0(input) * rl.GetFrameTime()
            gs.camera.target.x = math.clamp(gs.player.pos.x, gs.cam_boundary_tl.x, gs.cam_boundary_br.x)
            gs.camera.target.y = math.clamp(gs.player.pos.y, gs.cam_boundary_tl.y, gs.cam_boundary_br.y)
        }

        draw_game()
    }

    rl.CloseWindow()
}
