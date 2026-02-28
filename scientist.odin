package main

import rl "vendor:raylib"
import b2 "vendor:box2d"
import "core:fmt"

PATH_FOLLOW_THRESHOLD :: 0.5

Scientist :: struct {
    id: b2.BodyId,
    texture: rl.Texture2D,
    speed: f32,
    path_progress: int,
    path: [dynamic]([2]f32),
}

follow_path :: proc(scientist: ^Scientist) {
    if scientist.path_progress < len(scientist.path) {
        cur_pos: [2]f32 = b2.Body_GetPosition(scientist.id)
        tgt_pos: [2]f32 = scientist.path[scientist.path_progress]

        if b2.Distance(tgt_pos, cur_pos) < PATH_FOLLOW_THRESHOLD {
                if scientist.path_progress + 1 < len(scientist.path) {
                    scientist.path_progress += 1
                }
        } else {
            b2.Body_ApplyForceToCenter(scientist.id, b2.Normalize(tgt_pos - cur_pos) * 200.0, true)
        }
    }
}

