package main

import "core:fmt"
import "base:intrinsics"
import rl "vendor:raylib"

TILE_SIZE :: 16
TILE_WIDTH :: 16
TILE_HEIGHT :: 32

WORLD_WIDTH :: 128
WORLD_HEIGHT :: 128

TILE_SCALE : i32 = 4

TILE_NONE: u32 : ~u32(0)

tile_rect :: proc(ix: u32) -> rl.Rectangle {
    return {f32(TILE_WIDTH * ix), 0, TILE_WIDTH, TILE_HEIGHT}
}

main :: proc() {
    rl.InitWindow(1280, 720, "this is not a drill")
    tiles := rl.LoadTexture("tilemap.png")
    rl.SetTextureFilter(tiles, rl.TextureFilter.POINT)


    grid: [WORLD_WIDTH][WORLD_HEIGHT]u32
    for x in 0 ..< WORLD_WIDTH {
        for y in 0 ..< WORLD_HEIGHT {
            grid[x][y] = TILE_NONE
        }
    }
    data_size :i32 = 0
    data := rl.LoadFileData("map.dat", &data_size)
    if data != nil && data_size == size_of(grid) {
        intrinsics.mem_copy(
            &grid[0],
            &data[0],
            size_of(grid),
        )
        fmt.printfln("Loaded map.dat")
    }

    offset: [2]f32 = {0, 0}

    selected_tile: u32 = 0

    for !rl.WindowShouldClose() {
        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            mx, my: i32 = rl.GetMouseX(), rl.GetMouseY()

            tx: i32 = ((mx - i32(offset.x)) / (TILE_SIZE * TILE_SCALE)) 
            ty: i32 = ((my - i32(offset.y)) / (TILE_SIZE * TILE_SCALE)) - 1
            if tx >= 0 && ty >= 0 && tx < WORLD_WIDTH && ty < WORLD_HEIGHT {
                grid[tx][ty] = selected_tile
                fmt.printfln("%d, %d", tx, ty)
            }
        }
        if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
            mx, my: i32 = rl.GetMouseX(), rl.GetMouseY()

            tx: i32 = ((mx - i32(offset.x)) / (TILE_SIZE * TILE_SCALE))
            ty: i32 = ((my - i32(offset.y)) / (TILE_SIZE * TILE_SCALE)) - 1
            if tx >= 0 && ty >= 0 && tx < WORLD_WIDTH && ty < WORLD_HEIGHT {
                grid[tx][ty] = TILE_NONE
                fmt.printfln("%d, %d", tx, ty)
            }
        }

        if rl.IsMouseButtonDown(rl.MouseButton.MIDDLE) {
            offset.xy += rl.GetMouseDelta()
        }

        if rl.IsKeyPressed(.UP) {
            offset.y += f32(TILE_SIZE * TILE_SCALE)
        }
        if rl.IsKeyPressed(.DOWN) {
            offset.y -= f32(TILE_SIZE * TILE_SCALE)
        }
        if rl.IsKeyPressed(.LEFT) {
            offset.x += f32(TILE_SIZE * TILE_SCALE)
        }
        if rl.IsKeyPressed(.RIGHT) {
            offset.x -= f32(TILE_SIZE * TILE_SCALE)
        }
        if rl.IsKeyPressed(.S) {
            if rl.SaveFileData("map.dat", &grid[0], size_of(grid)) {
                fmt.printfln("Saved map.dat")
            }
        }
        
        for {
            ch := rl.GetCharPressed()
            if ch == 0 {
                break
            }

            if ch == '+' && TILE_SCALE <= 16 {
                TILE_SCALE *= 2
            }
            if ch == '-' && TILE_SCALE >= 2 {
                TILE_SCALE /= 2
            }
        }

        wheel_delta: f32 = rl.GetMouseWheelMove()
        if wheel_delta < 0.0 && selected_tile < 8 - 1 {
            selected_tile += 1
        } else if wheel_delta > 0.0 && selected_tile > 0 {
            selected_tile -= 1
        }

        rl.BeginDrawing()
        rl.ClearBackground({160, 200, 255, 255})

        rl.DrawRectangle(i32(offset.x), i32(offset.y), 
                         WORLD_WIDTH * TILE_SIZE * TILE_SCALE, 
                         WORLD_HEIGHT * TILE_SIZE * TILE_SCALE, rl.LIGHTGRAY)

        for x in i32(0) ..< i32(WORLD_WIDTH) {
            for y in i32(0) ..< i32(WORLD_HEIGHT) {
                tile: u32 = grid[x][y]
                if tile == TILE_NONE {
                    continue
                }
                rl.DrawTexturePro(
                    tiles,
                    tile_rect(tile),
                    {
                        f32(x * TILE_SIZE * TILE_SCALE + i32(offset.x)),
                        f32((y * TILE_SIZE) * TILE_SCALE + i32(offset.y)),
                        f32(TILE_WIDTH * TILE_SCALE),
                        f32(TILE_HEIGHT * TILE_SCALE),
                    },
                    {0, 0},
                    0.0,
                    rl.WHITE,
                )
            }
        }

        for tile_ix in u32(0)..<u32(8) {
            color: rl.Color = tile_ix % 2 == 0 ? rl.GRAY : rl.WHITE
            if tile_ix == selected_tile {
                color = rl.GREEN
            }
            rl.DrawRectangle(1280 - TILE_SIZE * 4 - 16,
                         i32(tile_ix) * TILE_HEIGHT * 4,
                         TILE_SIZE * 4 + 16, TILE_HEIGHT * 4,
                         color)
            rl.DrawTexturePro(
                tiles,
                tile_rect(tile_ix),
                {
                    f32(1280 - TILE_SIZE * 4),
                    f32((tile_ix * TILE_HEIGHT) * u32(4)),
                    f32(TILE_WIDTH * 4),
                    f32(TILE_HEIGHT * 4),
                },
                {0, 0},
                0.0,
                rl.WHITE,
            )
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}
