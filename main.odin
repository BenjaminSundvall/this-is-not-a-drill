package main

import "base:runtime"
import rl "vendor:raylib"
import b2 "vendor:box2d"
import la "core:math/linalg"
import "core:fmt"
import "core:math"
import "core:sort"
import "core:strings"
import "core:c"

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

render_el_cmp :: proc(a, b: RenderElement) -> int {
    if a.z == b.z {
        return 0
    }
    return a.z < b.z ? -1 : 1
}


draw_path :: proc(scientist: Scientist) {
    for i in 0..<(len(scientist.path)-1) {
        from := scientist.path[i]
        to := scientist.path[i+1]
        rl.DrawLineV(from, to, rl.RED)
    }


    for i in 0..<(len(scientist.path)) {
        tgt_pos := scientist.path[scientist.path_progress]
        rl.DrawCircleV(scientist.path[i], i == scientist.path_progress ? 0.15 : 0.05, rl.BLUE)
    }
}

draw_cam :: proc() {
    sort.quick_sort_proc(gs.render_queue[:], render_el_cmp)

    for el in gs.render_queue {
        rl.DrawTexturePro(el.texture^, el.src, el.dest,
                          {0, 0}, 0, rl.WHITE)
    }

    draw_path(gs.scientist)
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
    level_draw(&gs.level)

    pos := b2.Body_GetPosition(gs.player.id)

    el: RenderElement = {
        &gs.player.texture,
        {0, 0, f32(gs.player.texture.width), f32(gs.player.texture.height)},
        {pos.x - 0.5,
         pos.y - 1.5,
         1.0, 2.0,
        },
        pos.y - 0.65,
    }
    append(&gs.render_queue, el)

    // Test scientist
    pos = b2.Body_GetPosition(gs.scientist.id)
    el = {
        &gs.scientist.texture,
        {0, 0, f32(gs.scientist.texture.width), f32(gs.scientist.texture.height)},
        {pos.x - 0.5,
         pos.y - 1.5,
         1.0, 2.0,
        },
        pos.y - 0.65,
    }
    append(&gs.render_queue, el)

    // Camera
    rl.BeginMode2D(gs.camera)
    draw_cam()
    b2.World_Draw(gs.world, &gs.dbg_draw)
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
    // Init
    rl.InitWindow(1280, 720, "This is not a drill!")
    rl.InitAudioDevice()

    music: rl.Music = rl.LoadMusicStream("resources/alarm2.mp3")
    music.looping = true
    rl.PlayMusicStream(music)

    wd := b2.DefaultWorldDef()
    wd.gravity = {0, 0}
    world := b2.CreateWorld(wd)

    body := b2.DefaultBodyDef()
    body.type = b2.BodyType.dynamicBody
    body.position = {0, 0}
    body.linearDamping = 20.0

    body_id := b2.CreateBody(world, body)
    shape_def := b2.DefaultShapeDef()
    shape_def.density = 8.0
    shape := b2.CreateCircleShape(body_id, shape_def, {{0.0, 0.0}, 0.45})

    dbg := b2.DefaultDebugDraw()
    dbg.DrawSolidPolygonFcn = proc "c" (t: b2.Transform, vert: [^]b2.Vec2, count: c.int, radius: f32,
                                   color: b2.HexColor, ctx: rawptr) {
        context = runtime.default_context()

        if count != 4 {
            fmt.printfln("Bad size")
            return
        } else {
            min_x: f32 = 10000
            max_x: f32 = 0
            min_y: f32 = 10000
            max_y: f32 = 0
            for ix in 0..<4 {
                min_x = min(min_x, vert[ix].x)
                max_x = max(max_x, vert[ix].x)
                min_y = min(min_y, vert[ix].y)
                max_y = max(max_y, vert[ix].y)
            }
            rl.DrawRectangleRec({
                min_x + t.p.x, min_y + t.p.y,
                max_x - min_x, max_y - min_y,
            }, rl.RED)
        }
    }
    dbg.DrawSolidCircleFcn = proc "c" (t: b2.Transform, rad: f32, color: b2.HexColor, ctx: rawptr) {
        context = runtime.default_context()
        rl.DrawCircleV({t.p.x, t.p.y}, rad, rl.WHITE)
    }
    dbg.drawShapes = false
    gs.dbg_draw = dbg


    rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))
    gs.game_over = false
    gs.world = world

    gs.player = {
        id = body_id,
        texture = rl.LoadTexture("resources/security_guard.png"),
        speed = 10,
    }

    gs.level = load_level()
    gs.camera = {
        zoom = TILE_SCALE * 4,
        offset = {f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)},
        target = b2.Body_GetPosition(gs.player.id),
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
    defer delete(gs.tasks)

    // Test scientist
    body = b2.DefaultBodyDef()
    body.type = b2.BodyType.dynamicBody
    body.position = {0, 0}
    body.linearDamping = 20.0

    body_id = b2.CreateBody(world, body)
    shape_def = b2.DefaultShapeDef()
    shape_def.density = 8.0
    shape = b2.CreateCircleShape(body_id, shape_def, {{0.0, 0.0}, 0.45})

    gs.scientist = {
        id = body_id,
        texture = rl.LoadTexture("resources/player.png"),
        speed = 5,
    }
    append(&gs.scientist.path, b2.Body_GetPosition(gs.scientist.id))
    append(&gs.scientist.path, [2]f32{4, -2})
    append(&gs.scientist.path, [2]f32{4, 6})
    defer delete(gs.scientist.path)

    for !rl.WindowShouldClose() {
        if !gs.game_over {
            // Audio
            rl.UpdateMusicStream(music)

            // Input
            input := handle_input()
            input = b2.Normalize(input)
            b2.Body_ApplyForceToCenter(gs.player.id, input * 800.0,
                                       true)

            follow_path(&gs.scientist)

            b2.World_Step(world, 1.0 / 60.0, 4)


            level_tick(&gs.level)
            // Update game state
            gs.time_left = gs.time_limit - rl.GetTime()
            if gs.time_left <= 0 {
                game_over()
            }
            pos := b2.Body_GetPosition(gs.player.id)
            gs.camera.target.x = math.clamp(pos.x,
                gs.cam_boundary_tl.x, gs.cam_boundary_br.x)
            gs.camera.target.y = math.clamp(pos.y,
                gs.cam_boundary_tl.y, gs.cam_boundary_br.y)
                
            if rl.IsKeyPressed(.SPACE) {
                level_interact(&gs.level, pos)
            }
        }

        draw_game()
    }

    // Deinit
    rl.CloseAudioDevice()
    rl.CloseWindow()
}
