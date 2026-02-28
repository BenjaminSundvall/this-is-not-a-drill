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
    rl.DrawTextureV(gs.notepad_texture, {0, 0}, rl.WHITE)

    // Draw clock
    clock_font_size: i32 = 64
    clock_string: cstring = strings.clone_to_cstring(fmt.tprintf("%2d:%2d", u32(gs.time_left) / 60, u32(gs.time_left) % 60))
    clock_width := rl.MeasureText(clock_string, clock_font_size)
    rl.DrawText(clock_string, (rl.GetScreenWidth() - clock_width)/2, 0, clock_font_size, rl.RED)
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
        u32(len(gs.render_queue)),
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
    rl.InitWindow(1280, 720, "This is not a drill!")

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
        texture = rl.LoadTexture("resources/player.png"),
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

    gs.notepad_texture = rl.LoadTexture("resources/notepad.png")

    for !rl.WindowShouldClose() {
        if !gs.game_over {
            input := handle_input()
            input = b2.Normalize(input)
            b2.Body_ApplyForceToCenter(gs.player.id, input * 800.0, 
                                       true)

            b2.World_Step(world, 1.0 / 60.0, 4)

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
        }

        draw_game()
    }

    rl.CloseWindow()
}
