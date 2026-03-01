package main

import "core:fmt"
import rl "vendor:raylib"
import b2 "vendor:box2d"
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
    SERVER_LEFT = 13,
    SERVER_RIGHT = 14,
    TANK1_LEFT = 15,
    TANK1_RIGHT = 16,
    TANK2_LEFT = 17,
    TANK2_RIGHT = 18,
    TANK3_LEFT = 19,
    TANK3_RIGHT = 20,
    SERVER = 21,
    LAB_TEXT_L = 22,
    LAB_TEXT_A = 23,
    LAB_TEXT_B = 24,
    LAB_TEXT_ARROW = 25,
    LAB_DOOR = 26,
    LAB_FLOOR = 27,
    KEYPAD_LOCKED = 28,
    KEYPAD_UNLOCKED = 29,
    LAB_TABLE_1 = 30,
    LAB_TABLE_2 = 31,
    LAB_TABLE_3 = 32,
    LAB_TABLE_4 = 33,
    LAB_TABLE_5 = 34,
    LAB_TABLE_6 = 35,
    LAB_TABLE_7 = 36,
    LAB_TABLE_8 = 37,
    NONE = 0xffffffff,
}

DoorState :: enum u32 {
    OPEN = 0, 
    OPENING1 = 1, OPENING2 = 2, OPENING3 = 3, 
    CLOSED = 4,
    CLOSING1 = 5, CLOSING2 = 6, CLOSING3 = 7, 
}

Door :: struct {
    state: DoorState,
    vertical: bool,
    state_change_time: f64,
}

Keypad :: struct {
    locked: bool,
}

InteractableState :: union {
    Door, Keypad,
} 

Interactable :: struct {
    body: b2.BodyId,
    state : InteractableState,
}

Level :: struct {
    tiles: rl.Texture2D,
    grid: [WORLD_WIDTH][WORLD_HEIGHT]Tile,
    iteractables: [dynamic]Interactable,
}

load_level :: proc() -> Level {
    tiles := rl.LoadTexture("resources/tilemap.png")

    I : InteractableState = {}

    level: Level = {tiles, {}, {}}
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

interact_with :: proc(item: ^Interactable) {
    switch &v in item.state {
    case Keypad:
        v.locked = true
    case Door:
        if v.state == DoorState.OPEN {
            v.state = DoorState.CLOSING1
            v.state_change_time = rl.GetTime() + 0.2
            b2.Body_Enable(item.body)
        } else if v.state == DoorState.CLOSED {
            v.state = DoorState.OPENING1
            v.state_change_time = rl.GetTime() + 0.2
        }
    }
}

level_interact :: proc(level: ^Level, pos: [2]f32) {
    max_range: f32 = 1.5

    closest: ^Interactable = nil
    min_dist: f32 = 1000000000

    for &i in level.iteractables {
        bpos := b2.Body_GetPosition(i.body)

        dist := b2.Distance(pos, bpos)
        if dist > max_range {
            continue
        }
        if dist < min_dist {
            closest = &i
            min_dist = dist
        }
    }
    if closest != nil {
        interact_with(closest)
    }
}

level_tick :: proc(level: ^Level) {
    for &i in level.iteractables {
        switch &v in i.state {
        case Door:
            if v.state != DoorState.OPEN && 
                v.state != DoorState.CLOSED {
                now := rl.GetTime()
                if now >= v.state_change_time {
                    if v.state >= DoorState.CLOSED {
                        v.state = DoorState.CLOSED
                    } else {
                        v.state = DoorState.OPEN
                        b2.Body_Disable(i.body)
                    }
                } else if v.state >= DoorState.CLOSED {
                    ratio := 1.0 - (v.state_change_time - now) / 0.2
                    v.state = DoorState(u32(DoorState.CLOSING1) +
                                        u32(ratio * 3))
                } else {
                    ratio := 1.0 - (v.state_change_time - now) / 0.2
                    v.state = DoorState(u32(DoorState.OPENING1) +
                                        u32(ratio * 3))
                }
            }
        case Keypad:
            return
        }
    }
}

level_refresh :: proc(level: ^Level) {
    for x in i32(0) ..< i32(WORLD_WIDTH) {
        for y in i32(0) ..< i32(WORLD_HEIGHT) {
            tile := level.grid[x][y]
            if tile == Tile.NONE || tile == Tile.FLOOR {
                continue
            }
            body_def := b2.DefaultBodyDef()
            body_def.type = b2.BodyType.staticBody

            px := f32(x * TILE_SIZE) + TILE_SIZE / 2.0
            py := TILE_SIZE + TILE_SIZE / 2.0 + f32(y * TILE_SIZE)

            i: Interactable = {}

            box: b2.Polygon
            body_def.position = {px, py}
            box = b2.MakeSquare(TILE_SIZE / 2.0)
            if (tile == Tile.KEYPAD_LOCKED || tile == Tile.KEYPAD_UNLOCKED) {
                i.state = Keypad({tile == Tile.KEYPAD_LOCKED})
                level.grid[x][y] = Tile.WALL1
            } else if (tile == Tile.DOOR_H_CLOSED) {
                i.state = Door({DoorState.CLOSED, false, 0.0})
                level.grid[x][y] = Tile.FLOOR
            } else if (tile == Tile.DOOR_V_CLOSED) {
                i.state = Door({DoorState.CLOSED, true, 0.0})
                body_def.position = {px, py}
                box = b2.MakeBox(TILE_SIZE / 5.0, TILE_SIZE / 2.0)
                level.grid[x][y] = Tile.FLOOR
            }
            body := b2.CreateBody(gs.world, body_def)

            shape_def := b2.DefaultShapeDef()
            shape := b2.CreatePolygonShape(body, shape_def, box)

            if i.state != nil {
                i.body = body
                append(&level.iteractables, i)
            }
        }
    }

}

level_draw :: proc(level: ^Level) {
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
                f32(y * TILE_SIZE) - (tile == Tile.FLOOR ? 0.2 : 0),
            }
            append(&gs.render_queue, el)
        }
    }
    for &i in level.iteractables {
        pos := b2.Body_GetPosition(i.body)
        x := u32(pos.x - TILE_SIZE / 2.0) / TILE_SIZE
        y := u32(pos.y - TILE_SIZE - TILE_SIZE / 2.0) / TILE_SIZE

        tile: Tile = Tile.NONE
        switch v in i.state {
        case Keypad:
            tile = v.locked ? Tile.KEYPAD_LOCKED : Tile.KEYPAD_UNLOCKED
        case Door:
            switch v.state {
            case DoorState.OPEN:
                tile = v.vertical ? Tile.DOOR_V_OPEN :
                                    Tile.DOOR_H_OPEN
            case DoorState.CLOSED:
                tile = v.vertical ? Tile.DOOR_V_CLOSED :
                                    Tile.DOOR_H_CLOSED
            case DoorState.CLOSING1:
                tile = v.vertical ? Tile.DOOR_V_OPENING3 :
                                    Tile.DOOR_H_OPENING3
            case DoorState.CLOSING2:
                tile = v.vertical ? Tile.DOOR_V_OPENING2 :
                                    Tile.DOOR_H_OPENING2
            case DoorState.CLOSING3:
                tile = v.vertical ? Tile.DOOR_V_OPENING1 :
                                    Tile.DOOR_H_OPENING1
            case DoorState.OPENING3:
                tile = v.vertical ? Tile.DOOR_V_OPENING3 :
                                    Tile.DOOR_H_OPENING3
            case DoorState.OPENING2:
                tile = v.vertical ? Tile.DOOR_V_OPENING2 :
                                    Tile.DOOR_H_OPENING2
            case DoorState.OPENING1:
                tile = v.vertical ? Tile.DOOR_V_OPENING1 :
                                    Tile.DOOR_H_OPENING1
            }
            
        }
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
            f32(y * TILE_SIZE) + 0.05,
        }
        append(&gs.render_queue, el)

    }
}

TILE_WIDTH :: 16
TILE_HEIGHT :: 32

TILE_SCALE :: 16
TILE_SIZE :: 1

tile_rect :: proc(ix: Tile) -> rl.Rectangle {
    return {f32(TILE_WIDTH * u32(ix)), 0, TILE_WIDTH, TILE_HEIGHT}
}
