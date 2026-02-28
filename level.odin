package main

import rl "vendor:raylib"
import "base:intrinsics"

WORLD_WIDTH :: 128
WORLD_HEIGHT :: 128

Tile :: enum u32 {
    FLOOR = 0,
    WALL1 = 1,
    WALL2 = 2,
    DOOR_H_CLOSED = 3,
    DOOR_V_CLOSED = 4,
    DOOR_H_OPENING1 = 5,
    DOOR_V_OPENING1 = 6,
    DOOR_H_OPENING2 = 7,
    DOOR_V_OPENING2 = 8,
    DOOR_H_OPENING3 = 9,
    DOOR_V_OPENING3 = 10,
    DOOR_H_OPEN = 11,
    DOOR_V_OPEN = 12,
    NONE = 0xffffffff,
}

Level :: struct {
    tiles: rl.Texture2D,
    grid: [WORLD_WIDTH][WORLD_HEIGHT]Tile,
    textures: u32,
}

load_level :: proc() -> Level {
    tiles := rl.LoadTexture("resources/tilemap.png")

    level: Level = {tiles, {}, 0}
    for x in 0..<WORLD_WIDTH {
        for y in 0..<WORLD_HEIGHT {
            level.grid[x][y] = Tile.NONE
        }
    }

    data_size: i32 = 0
    data := rl.LoadFileData("map.dat", &data_size)
    if data != nil && data_size == size_of(level.grid) {
        intrinsics.mem_copy(
            &level.grid[0],
            &data[0],
            size_of(level.grid),
        )
    }

    level_refresh(&level)

    return level
}

level_refresh :: proc(level: ^Level) {
    for x in i32(0) ..< i32(WORLD_WIDTH) {
        for y in i32(0) ..< i32(WORLD_HEIGHT) {
            tile := level.grid[x][y]
            if tile == Tile.NONE {
                continue
            }
            el: RenderElement = {
                &level.tiles,
                tile_rect(tile),
                {
                    f32(x * TILE_SIZE),
                    f32((y * TILE_SIZE)),
                    TILE_WIDTH / TILE_SCALE,
                    TILE_HEIGHT / TILE_SCALE,
                },
                f32(y * TILE_SIZE),
                u32(len(gs.render_queue)),
            }
            append(&gs.render_queue, el)
        }
    }
    level.textures = u32(len(gs.render_queue))
}

TILE_WIDTH :: 16
TILE_HEIGHT :: 32

TILE_SCALE :: 16
TILE_SIZE :: 1

tile_rect :: proc(ix: Tile) -> rl.Rectangle {
    return {f32(TILE_WIDTH * u32(ix)), 0, TILE_WIDTH, TILE_HEIGHT}
}

draw_level :: proc(level: ^Level) {
    for x in i32(0) ..< i32(WORLD_WIDTH) {
        for y in i32(0) ..< i32(WORLD_HEIGHT) {
            tile := level.grid[x][y]
            if tile == Tile.NONE {
                continue
            }
            rl.DrawTexturePro(
                level.tiles,
                tile_rect(tile),
                {
                    f32(x * TILE_SIZE),
                    f32((y * TILE_SIZE)),
                    TILE_WIDTH / TILE_SCALE,
                    TILE_HEIGHT / TILE_SCALE,
                },
                {0, 0},
                0.0,
                rl.WHITE,
            )
        }
    }
}
